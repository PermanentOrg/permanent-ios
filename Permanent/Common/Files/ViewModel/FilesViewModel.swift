//
//  FilesViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation
import CoreImage

typealias FileMetaUploadResponse = (_ recordId: Int?, _ errorMessage: String?) -> Void
typealias FileUploadResponse = (_ file: FileInfo?, _ errorMessage: String?) -> Void

typealias VoidAction = () -> Void

typealias DownloadResponse = (_ downloadURL: URL?, _ errorMessage: Error?) -> Void

enum PublicRootRequestStatus: Equatable {
    static func == (lhs: PublicRootRequestStatus, rhs: PublicRootRequestStatus) -> Bool {
        return true
    }
    case success(folder: FolderVOData?)
    case error(message: String?)
}

enum CheckboxState {
    case none
    case partial
    case selected
}

class FilesViewModel: NSObject, ViewModelInterface {
    var viewModels: [FileModel] = []
    var navigationStack: [FileModel] = []
    var uploadQueue: [FileInfo] = []

    /// Whether this screen routes folder navigation through the Stela V2 endpoint.
    /// Default OFF (this base class hardcodes `false`). The opted-in workspaces override
    /// this to `FeatureFlags.useStelaNavigation`: `MyFilesViewModel`, `PublicFilesViewModel`
    /// (via inheritance), and `SearchFilesViewModel`. `SharedFilesViewModel` and everything
    /// else inherit `false` and stay on V1 (shared listings need per-item permissions the
    /// V2 path doesn't compute).
    var usesStelaNavigation: Bool { false }

    /// The folder a forward V2 navigation is heading into (the tapped item / resolved
    /// root). On back/refresh the target is taken from `navigationStack` instead.
    var v2NavigationTarget: FileModel?

    /// Monotonic id of the newest V2 children fetch. Superseded fetches compare against
    /// it on the main thread and report `.superseded` (see `getFolderChildrenV2`).
    private var childrenFetchGeneration = 0

    /// Injection seam for the V2 children fetch used by navigation (same idiom as
    /// SharesViewController.getSharesRequest). Tests inject outcomes to pin the
    /// supersede/retry policy in `navigateV2` without network.
    var childrenFetchV2Request: ((String, @escaping (ChildrenFetchOutcome) -> Void) -> Void)?

    /// The folder whose children the in-flight V2 fetch is listing, captured by
    /// `navigateV2`. Lets `getFolderChildrenV2` derive per-child context via
    /// `v2ChildContext(enteredFolder:)` — Shared inherits this folder's accessRole
    /// onto its children (the V2 `/children` payload carries no per-child role).
    private var v2EnteredFolder: FileModel?

    var downloadQueue: [FileModel] = []
    var activeSortOption: SortOption = .nameAscending
    var uploadInProgress: Bool = false
    var downloadInProgress: Bool {
        downloader != nil
    }
    var uploadFolder: FolderInfo?
    var fileAction: FileAction = .none
    
    var selectedFiles: [FileModel]? = []
    var currentFolder: FileModel? { navigationStack.last }
    var isSelecting: Bool = false
    var isSelectingDestination: Bool = false
    var checkboxState: CheckboxState = .none
    
    lazy var searchViewModels: [FileModel] = { [] }()
    private var downloader: DownloadManagerGCD?

    var currentArchive: ArchiveVOData? { return AuthenticationManager.shared.session?.selectedArchive }
    var archivePermissions: [Permission] {
        return currentArchive?.permissions() ?? [.read]
    }
    var archiveAccessRole: AccessRole {
        return AccessRole.roleForValue(currentArchive?.accessRole)
    }

    /// The `(permissions, accessRole)` to stamp on each child produced by the V2
    /// `/folders/{id}/children` listing. Base uses the archive-level role — correct for
    /// My Files / Public / Search, where a single archive role governs every item in the
    /// (owned) workspace. Shared overrides this to INHERIT the entered folder's role,
    /// because a shared folder's contents come back with no per-child role of their own.
    /// Called on the main thread by `getFolderChildrenV2` (reads main-only session state).
    func v2ChildContext(enteredFolder: FileModel?) -> (permissions: [Permission], accessRole: AccessRole) {
        return (archivePermissions, archiveAccessRole)
    }

    var timer: Timer?
    var timerRunCount: Int = 0
    
    var isGridView: Bool {
        get {
            AuthenticationManager.shared.session?.isGridView ?? false
        }
        
        set {
            AuthenticationManager.shared.session?.isGridView = newValue
        }
    }
    
    // MARK: - Table View Logic
    
    var currentFolderIsRoot: Bool { true }
    
    func removeCurrentFolderFromHierarchy() -> FileModel? {
        navigationStack.popLast()
    }
    
    func shouldPerformAction(forSection section: Int) -> Bool {
        // Perform action only for synced items
        return section == FileListType.synced.rawValue
    }
    
    func hasCancelButton(forSection section: Int) -> Bool {
        return FileListType.uploading.rawValue == section
    }
    
    func title(forSection section: Int) -> String {
        switch section {
        case FileListType.downloading.rawValue: return .downloads
        case FileListType.uploading.rawValue: return .uploads
        case FileListType.synced.rawValue: return activeSortOption.title
        default: return "" // We cannot have more than 3 sections.
        }
    }
    
    var shouldDisplayBackgroundView: Bool {
        syncedViewModels.isEmpty && uploadQueue.isEmpty
    }
    
    var numberOfSections: Int {
        3
    }
    
    var queueItemsForCurrentFolder: [FileInfo] {
        uploadQueue.filter { $0.folder.folderId == navigationStack.last?.folderId }
    }
    
    var syncedViewModels: [FileModel] {
        return viewModels
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        switch section {
        case FileListType.downloading.rawValue: return downloadQueue.count
        case FileListType.uploading.rawValue: return queueItemsForCurrentFolder.count
        case FileListType.synced.rawValue: return syncedViewModels.count
        default: fatalError() // We cannot have more than 2 sections.
        }
    }
    
    func fileForRowAt(indexPath: IndexPath) -> FileModel {
        switch indexPath.section {
        case FileListType.downloading.rawValue:
            return downloadQueue[indexPath.row]

        case FileListType.uploading.rawValue:
            let fileInfo = queueItemsForCurrentFolder[indexPath.row]
            var fileViewModel = FileModel(model: fileInfo, permissions: archivePermissions)
            
            // If the first item in queue, set the `uploading` status.
            let currentFileUpload = UploadManager.shared.inProgressUpload()
            fileViewModel.fileStatus = currentFileUpload?.id == fileInfo.id ? .uploading : .waiting
            
            fileViewModel.fileStatus = fileInfo.didFailUpload ? .failed : fileViewModel.fileStatus
            
            return fileViewModel
            
        case FileListType.synced.rawValue:
            return syncedViewModels[indexPath.row]
            
        default:
            fatalError()
        }
    }
    
    func clearDownloadQueue() {
        downloadQueue.removeAll()
        
        // delete from prefs
    }
    
    func showMemberChecklist(_ completionBlock: @escaping ((Bool?) -> Void)) {
        guard let accountId: Int = PermSession.currentSession?.account?.accountID else {
            completionBlock(nil)
            return
        }
        
        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: accountId))
        getUserDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil)
                    return
                }
                
                if let hideChecklist = model.results[0].data?[0].accountVO?.hideChecklist,
                   !hideChecklist {
                    completionBlock(true)
                } else {
                    completionBlock(false)
                }
                return
                
            default:
                completionBlock(nil)
                return
            }
        }
    }
    
    @discardableResult
    func refreshUploadQueue() -> Bool {
        let savedFiles: [FileInfo]? = UploadManager.shared.queuedFiles()
        
        if savedFiles?.map(\.id) != uploadQueue.map(\.id) {
            uploadQueue = savedFiles ?? []
            
            return true
        }
        
        return false
    }
    
    func removeSyncedFiles(_ files: [FileModel]?) {
        guard let files = files else {
            return
        }
        
        for file in files {
            guard let index = viewModels.firstIndex(where: { $0 == file }) else {
                return
            }
            viewModels.remove(at: index)
        }
    }
    
    /// Exponential-backoff schedule for the post-upload thumbnail-ready
    /// polling. Each value is the wait BEFORE the next fire. Four fires total
    /// span ~45 s of polling, which covers server-side thumbnail processing
    /// for typical media without flooding the API with linear-interval polls.
    /// Empty array → no polling.
    static let thumbnailPollIntervals: [TimeInterval] = [3, 6, 12, 24]

    /// Cadence of the post-paste/post-upload thumbnail poll (MainViewController.
    /// scheduleNextThumbnailPoll). The server processes fresh copies SLOWLY — on staging
    /// even the access-copy thumbnail can take minutes — so poll gently but persistently.
    static let thumbnailPollInterval: TimeInterval = 10
    /// Hard cap on consecutive polls (~5 minutes at 10s) so a folder whose records
    /// legitimately never produce a thumbnail can't refetch forever.
    static let thumbnailPollMaxRuns = 30

    /// Cadence used while the pasted rows themselves are still MISSING. That's a
    /// read-after-write race against the server's commit, which usually clears within a
    /// second — polling it at `thumbnailPollInterval` made a pasted file take ~10s to show up.
    static let pastedItemsPollInterval: TimeInterval = 1
    /// How many polls stay on the fast cadence before falling back to the slow one, so a row
    /// that never arrives doesn't hammer the server (5 × 1s ≈ 5s of quick re-checks).
    static let pastedItemsFastRuns = 5

    /// Cadence while an item is mid copy/move (`status` "copying"/"moving"). Those items are
    /// not tappable until the server finishes, and a V1 folder copy takes tens of seconds —
    /// staging-measured: the copied folder row appeared 9s after the request and only flipped
    /// to "ok" 15s later. Polling that at `thumbnailPollInterval` left the folder
    /// un-enterable long enough to look broken; polling it at `pastedItemsPollInterval` would
    /// hammer the server for the whole copy.
    static let transientStatePollInterval: TimeInterval = 2

    /// True while any listed item is still being processed server-side: mid copy/move
    /// (`thumbStatus` .copying/.moving), or a RECORD with no thumbnail source at all —
    /// the fresh-Stela-copy shape (create-record-copy returns null thumbUrl* and its
    /// access-copy 256 lands minutes later). Gates the thumbnail poll: while true the
    /// folder keeps refetching every `thumbnailPollInterval`, bounded by
    /// `thumbnailPollMaxRuns`; once everything settles the chain ends.
    var hasItemsAwaitingProcessing: Bool {
        hasItemsInTransientState || viewModels.contains { file in
            !file.type.isFolder && (file.thumbnailURL ?? "").isEmpty
        }
    }

    /// True while a listed item is mid copy/move server-side (`status` "copying"/"moving").
    /// Such items are deliberately NOT tappable (`FileModel.canBeAccessed`), so this is a
    /// wait the user is actively blocked on — and it clears in seconds to tens of seconds,
    /// unlike the thumbnail wait, which takes minutes. Drives the middle poll cadence.
    var hasItemsInTransientState: Bool {
        viewModels.contains { $0.thumbStatus == .copying || $0.thumbStatus == .moving }
    }

    /// How many items the destination folder must list before a paste counts as landed, and
    /// the folder that expectation belongs to. A relocate is committed ASYNCHRONOUSLY
    /// server-side, so the refetch fired straight after it can still return the PRE-paste
    /// listing. `hasItemsAwaitingProcessing` cannot detect that: it inspects the items that
    /// ARE listed, and a MOVED record arrives with its thumbnails already in place — so for a
    /// move the item count is the only signal that works. Keyed to the folder id, so
    /// navigating elsewhere makes the expectation inert.
    private(set) var expectedItemCount: Int?
    private(set) var expectedItemCountFolderId: Int?

    /// Records "this folder must reach `viewModels.count + pastedItems.count` items".
    /// MUST be called BEFORE the post-paste refetch — the baseline is the pre-paste count.
    func expectPastedItems(_ pastedItems: [FileModel], destination: FileModel) {
        guard !pastedItems.isEmpty, destination.folderId == currentFolder?.folderId else {
            clearPastedItemsExpectation()
            return
        }
        expectedItemCount = viewModels.count + pastedItems.count
        expectedItemCountFolderId = destination.folderId
    }

    func clearPastedItemsExpectation() {
        expectedItemCount = nil
        expectedItemCountFolderId = nil
    }

    /// True while the folder that received a paste still lists fewer items than expected.
    var isAwaitingPastedItems: Bool {
        guard let expected = expectedItemCount,
              expectedItemCountFolderId == currentFolder?.folderId else { return false }
        return viewModels.count < expected
    }

    func updateTimerCount() {
        timerRunCount += 1
        if timerRunCount >= Self.thumbnailPollIntervals.count {
            timerRunCount = 0
            invalidateTimer()
        }
    }

    func invalidateTimer() {
        if timer != nil {
            timer?.invalidate()
            timerRunCount = 0
            clearPastedItemsExpectation() // a manual pull-to-refresh cancels the settle chain
        }
    }

    /// Injection seam for the single-record Stela V2 copy (VSP-1789), mirroring
    /// `childrenFetchV2Request`. Tests pin the partition + aggregation policy without a
    /// dispatcher by returning per-record success/failure. Production leaves it nil.
    var copyRecordV2Request: ((_ recordId: String, _ destinationFolderId: String, _ completion: @escaping (Bool) -> Void) -> Void)?

    /// A record is eligible for the idempotent Stela V2 copy (POST /records/{id}/copies)
    /// only when the flag is on, it is a SAVED record (not a folder — there is no V2
    /// folder-copy route), and it lives in the CURRENT archive. A foreign/shared record
    /// would be rejected on the bearer-only V2 call, so it stays on V1 (same gate as
    /// `FilePreviewViewModel.canPublishViaStelaCopy`). Internal so tests can pin it.
    func isEligibleForStelaCopy(_ file: FileModel) -> Bool {
        guard usesStelaNavigation, !file.type.isFolder, file.recordId > 0,
              let currentArchiveId = currentArchive?.archiveID else { return false }
        return file.archiveId > 0 && file.archiveId == currentArchiveId
    }

    func relocate(files: [FileModel]?, to destination: FileModel, then handler: @escaping ServerResponse) {
        guard let files = files else {
            handler(.error(message: "No files selected".localized()))
            return
        }

        // VSP-1789: the COPY action prefers the idempotent Stela V2 copy endpoint for
        // own-archive records. The legacy V1 copy is NOT idempotent — a failed copy can
        // orphan invisible files that keep consuming the member's storage. V2 copy has NO
        // V1 failsafe (a mis-read success would silently duplicate the copy), so it is
        // flag-SELECT per record: eligible records go V2, while folders and foreign
        // records (no V2 route) stay on the V1 batch. MOVE is untouched.
        //
        // A non-positive destination folderId (e.g. a degenerate getPublicRoot result whose
        // folderVO carries a nil folderID) is NOT a valid V2 target — since copy has no V1
        // failsafe, posting "-1" would just fail. Route the whole copy through V1 in that
        // case, mirroring the `folderId > 0` guard on the FilePreview/FileDetails publish path.
        if fileAction == .copy, destination.folderId > 0 {
            let v2Records = files.filter { isEligibleForStelaCopy($0) }
            if !v2Records.isEmpty {
                let v1Rest = files.filter { !isEligibleForStelaCopy($0) }
                copyViaStela(v2Records: v2Records, v1Rest: v1Rest, to: destination, then: handler)
                return
            }
        }

        performV1Relocate(files: files, to: destination, then: handler)
    }

    /// Copies `v2Records` one at a time through Stela V2 and `v1Rest` through the V1 batch,
    /// aggregating into one `ServerResponse` (`.success` only if EVERY copy succeeded).
    /// V2 copies run serially and best-effort — a single failure never aborts the rest, and
    /// there is NO V2→V1 fallback (copy is not idempotent). Serial execution also avoids a
    /// data race on `errors`. The caller refetches the destination afterwards, so a partial
    /// success still reflects the true server state. Clears selection on the main thread.
    private func copyViaStela(v2Records: [FileModel], v1Rest: [FileModel], to destination: FileModel, then handler: @escaping ServerResponse) {
        let destinationFolderId = String(destination.folderId)
        Task {
            var errors: [String] = []

            for record in v2Records {
                let succeeded: Bool = await withCheckedContinuation { continuation in
                    self.copyRecordViaStelaV2(recordId: String(record.recordId), destinationFolderId: destinationFolderId) {
                        continuation.resume(returning: $0)
                    }
                }
                if !succeeded { errors.append("Unknown error") }
            }

            if !v1Rest.isEmpty {
                let v1Error: String? = await withCheckedContinuation { continuation in
                    self.performV1Relocate(files: v1Rest, to: destination) { status in
                        if case .error(let message) = status {
                            continuation.resume(returning: message ?? "Unknown error")
                        } else {
                            continuation.resume(returning: nil)
                        }
                    }
                }
                if let v1Error { errors.append(v1Error) }
            }

            await MainActor.run {
                self.selectedFiles = []
                self.fileAction = .none
                handler(errors.isEmpty ? .success : .error(message: errors.joined(separator: "\n")))
            }
        }
    }

    /// Single-record Stela V2 copy (POST /records/{id}/copies). Uses the injected seam in
    /// tests; otherwise calls the endpoint. `true` iff the server returned JSON success.
    private func copyRecordViaStelaV2(recordId: String, destinationFolderId: String, completion: @escaping (Bool) -> Void) {
        if let injected = copyRecordV2Request {
            injected(recordId, destinationFolderId, completion)
            return
        }
        let apiOperation = APIOperation(RecordV2Endpoint.copyRecord(recordId: recordId, destinationFolderId: destinationFolderId))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            if case .json = result {
                completion(true)
            } else {
                completion(false)
            }
        }
    }

    /// Injection seam for the V1 relocate batch (copy/move), so tests can exercise the
    /// copy partition + move routing without a dispatcher. Production leaves it nil.
    var relocateV1Request: ((_ files: [FileModel], _ destination: FileModel, _ completion: @escaping ServerResponse) -> Void)?

    private func performV1Relocate(files: [FileModel], to destination: FileModel, then handler: @escaping ServerResponse) {
        if let injected = relocateV1Request {
            injected(files, destination) { [weak self] status in
                self?.selectedFiles = []
                self?.fileAction = .none
                handler(status)
            }
            return
        }

        let fileGroup = DispatchGroup()
        var errors: [String] = []

        let folders = files.filter { $0.type.isFolder }
        let nonFolders = files.filter { !$0.type.isFolder }

        if !folders.isEmpty {
            fileGroup.enter()
            let folderParameters: RelocateParams = ((files: folders, destination: destination), fileAction)
            let folderApiOperation = APIOperation(FilesEndpoint.relocate(params: folderParameters))
            folderApiOperation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let httpResponse, _):
                    if let response = httpResponse,
                       let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted),
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let isSuccessful = json["isSuccessful"] as? Bool, isSuccessful {
                        // Handle successful folder response
                        break
                    } else {
                        errors.append("Unknown error")
                    }
                case .error(let error, _):
                    errors.append(error?.localizedDescription ?? "Unknown error")
                default:
                    break
                }
                fileGroup.leave()
            }
        }

        if !nonFolders.isEmpty {
            fileGroup.enter()
            let nonFolderParameters: RelocateParams = ((files: nonFolders, destination: destination), fileAction)
            let nonFolderApiOperation = APIOperation(FilesEndpoint.relocate(params: nonFolderParameters))
            nonFolderApiOperation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let httpResponse, _):
                    if let response = httpResponse,
                       let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted),
                       let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                       let isSuccessful = json["isSuccessful"] as? Bool, isSuccessful {
                        // Handle successful non-folder response
                        break
                    } else {
                        errors.append("Unknown error")
                    }
                case .error(let error, _):
                    errors.append(error?.localizedDescription ?? "Unknown error")
                default:
                    break
                }
                fileGroup.leave()
            }
        }

        fileGroup.notify(queue: .main) {
            self.selectedFiles = []
            self.fileAction = .none

            if errors.isEmpty {
                handler(.success)
            } else {
                handler(.error(message: errors.joined(separator: "\n")))
            }
        }
    }

    func publish(files: [FileModel], then handler: @escaping ServerResponse) {
        fileAction = .copy
        guard let archiveNbr = currentArchive?.archiveNbr else {
            // Always complete (and clear the copy state) so the caller's spinner is
            // dismissed. A bare `return` here previously stranded MainViewController's
            // spinner (it only hides it in the handler) with fileAction stuck at .copy.
            fileAction = .none
            handler(.error(message: .errorMessage))
            return
        }

        getPublicRoot(archiveNbr: archiveNbr, then: { status in
            switch status {
            case .success(let folder):
                if let rootFolder = folder {
                    let publicRoot = FileModel(model: rootFolder)
                    self.relocate(files: files, to: publicRoot, then: handler)
                } else {
                    handler(.error(message: .errorMessage))
                }
                
            case .error(let message):
                handler(.error(message: message))
            }
        })
    }
    
    func cancelDownload() {
        downloadQueue.safeRemoveFirst()
        
        downloader?.cancelDownload()
        downloader = nil
    }
    
    func download(_ file: FileModel, onDownloadStart: @escaping VoidAction, onFileDownloaded: @escaping DownloadResponse, progressHandler: ProgressHandler?) {
        var downloadFile = file
        downloadFile.fileStatus = .downloading
        downloadQueue.append(downloadFile)
        
        let downloadInfo = FileDownloadInfoVM(
            fileType: file.type,
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        downloader = DownloadManagerGCD()
        downloader?.download(
            downloadInfo,
            onDownloadStart: onDownloadStart,
            onFileDownloaded: onFileDownloaded,
            progressHandler: progressHandler,
            completion: {
                self.downloader = nil
                self.downloadQueue.safeRemoveFirst()
            }
        )}

    func delete(_ files: [FileModel]?, then handler: @escaping ServerResponse) {
        guard let files = files else {
            handler(.error(message: .errorMessage))
            return
        }

        let folders = files.filter({ $0.type.isFolder })
        let records = files.filter({ !$0.type.isFolder })

        let group = DispatchGroup()

        var folderError: String?
        var recordError: String?

        if !folders.isEmpty {
            group.enter()
            let apiOperation = APIOperation(FilesEndpoint.delete(params: folders))
            apiOperation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let response, _):
                    if let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder), !model.isSuccessful {
                        folderError = .errorMessage
                    }
                case .error(let error, _):
                    folderError = error?.localizedDescription
                default:
                    break
                }
                group.leave()
            }
        }

        if !records.isEmpty {
            group.enter()
            let apiOperation = APIOperation(FilesEndpoint.delete(params: records))
            apiOperation.execute(in: APIRequestDispatcher()) { result in
                switch result {
                case .json(let response, _):
                    if let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder), !model.isSuccessful {
                        recordError = .errorMessage
                    }
                case .error(let error, _):
                    recordError = error?.localizedDescription
                default:
                    break
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if let error = folderError ?? recordError {
                handler(.error(message: error))
            } else {
                handler(.success)
            }
        }
    }


    func removeFromQueue(_ position: Int) {
        // `position` comes from a captured cell index; the queue can shrink between render
        // and tap (an upload finishing removes its item), so guard before subscripting to
        // avoid an index-out-of-range crash.
        guard queueItemsForCurrentFolder.indices.contains(position) else { return }
        UploadManager.shared.cancelUpload(fileId: queueItemsForCurrentFolder[position].id)
    }
    
    func createNewFolder(params: NewFolderParams, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.newFolder(params: params))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: NavigateMinResponse = JSONHelper.convertToModel(from: response),
                    let folderVO = model.results?.first?.data?.first?.folderVO
                else {
                    handler(.error(message: .errorMessage))
                    return
                }

                let folder = FileModel(model: folderVO, permissions: self.archivePermissions, accessRole: self.archiveAccessRole)
                self.viewModels.insert(folder, at: 0)
                handler(.success)

            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))

            default:
                break
            }
        }
    }

    // this method takes care of multiple upload process
    // sets up a queue and calls uploadFileMeta and uploadFileData
    func uploadFiles(_ files: [FileInfo], completion: ((Bool) -> Void)? = nil) {
        UploadManager.shared.upload(files: files, completion: completion)
    }
    
    func cancelUploadsInFolder() {
        let uploadIds = queueItemsForCurrentFolder.map({ $0.id })
        uploadIds.forEach { id in
            UploadManager.shared.cancelUpload(fileId: id)
        }
    }

    func getLeanItems(params: GetLeanItemsParams, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getLeanItems(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetLeanItemsSuccess(model, handler)
                } else {
                    handler(.error(message: .errorMessage))
                }
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    #if DEBUG
    /// Records which navigation path actually served the last folder load — "v2" when the
    /// Stela path succeeded, "v1" when the legacy path ran (as the primary path or as the
    /// failsafe). UI parity tests read this (surfaced on the Files collection view) so a
    /// "V2" run can't silently pass on the V1 failsafe. DEBUG-only; no Release behavior.
    static var lastNavigationSource = "none"
    #endif

    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
        // Stela V2 path (Private Files only, gated by `usesStelaNavigation`), with the
        // legacy V1 call kept as an automatic failsafe on any error or anomaly.
        // Forward navigation consumes a one-shot target set by the caller (the tapped
        // item / resolved root). Entries that don't set one — e.g. deep links and
        // saved universal links — leave it nil and safely fall through to V1.
        let v2Target = backNavigation ? navigationStack.last : v2NavigationTarget
        if !backNavigation { v2NavigationTarget = nil }
        if usesStelaNavigation,
           let target = v2Target,
           target.folderId > 0 {
            navigateV2(target: target, params: params, backNavigation: backNavigation, retriesLeft: 1, then: handler)
            return
        }
        performV1NavigateMin(params: params, backNavigation: backNavigation, then: handler)
    }

    /// One V2 navigation attempt, with the supersede policy applied:
    /// - committed → done (append the target on forward navigation).
    /// - failed    → V1 failsafe (this fetch was the NEWEST, so no ordering hazard).
    /// - superseded, forward → retry once: a background refresh that raced the user's
    ///   tap must not eat the navigation ("tap does nothing"); the retry claims the
    ///   newest generation and wins. If superseded twice, give up quietly.
    /// - superseded, back/refresh → complete `.success` WITHOUT touching data: the
    ///   superseding fetch repaints this folder anyway; the caller just needs its
    ///   completion (hide spinner / endRefreshing). Never V1-failsafe a superseded
    ///   fetch — its out-of-order V1 response could overwrite the newer listing.
    private func navigateV2(target: FileModel, params: NavigateMinParams, backNavigation: Bool, retriesLeft: Int, then handler: @escaping ServerResponse) {
        // Record the folder being entered so `getFolderChildrenV2` can derive per-child
        // context from it (Shared inherits this folder's role onto its children).
        v2EnteredFolder = target
        let fetch: (String, @escaping (ChildrenFetchOutcome) -> Void) -> Void = childrenFetchV2Request ?? { [weak self] folderId, completion in
            guard let self = self else { completion(.failed(message: .errorMessage)); return }
            self.getFolderChildrenV2(folderId: folderId, completion: completion)
        }
        fetch(String(target.folderId)) { [weak self] outcome in
            guard let self = self else { handler(.error(message: .errorMessage)); return }
            switch outcome {
            case .committed:
                if !backNavigation { self.navigationStack.append(target) }
                #if DEBUG
                FilesViewModel.lastNavigationSource = "v2"
                #endif
                handler(.success)
            case .superseded:
                if !backNavigation, retriesLeft > 0 {
                    self.navigateV2(target: target, params: params, backNavigation: backNavigation, retriesLeft: retriesLeft - 1, then: handler)
                } else {
                    handler(.success)
                }
            case .failed:
                // Failsafe — fall back to the legacy V1 navigation transparently.
                self.performV1NavigateMin(params: params, backNavigation: backNavigation, then: handler)
            }
        }
    }

    private func performV1NavigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
        #if DEBUG
        // Reached either as the primary V1 path (flag off) or as the V2 failsafe.
        FilesViewModel.lastNavigationSource = "v1"
        #endif
        let apiOperation = APIOperation(FilesEndpoint.navigateMin(params: params))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }

                self.onNavigateMinSuccess(model, backNavigation, handler)

            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))

            default:
                break
            }
        }
    }

    // MARK: - Stela V2 navigation (Private Files)

    /// Outcome of a single V2 children fetch. `superseded` is distinct from `failed`
    /// on purpose: a superseded fetch committed nothing (a newer fetch owns the final
    /// state) and must be completed QUIETLY — running the V1 failsafe for it would
    /// reintroduce the exact out-of-order overwrite the generation guard prevents.
    enum ChildrenFetchOutcome {
        case committed
        case superseded
        case failed(message: String?)
    }

    /// Fetches a folder's children via the Stela `/folders/{id}/children` endpoint,
    /// maps them into `FileModel`s (archive-derived permissions), applies the active
    /// sort client-side (the endpoint has no sort param), and replaces `viewModels`.
    /// Reports `.failed` on any failure or corruption so the caller can fall back to
    /// V1, and `.superseded` when a newer fetch took over. The completion is ALWAYS
    /// called exactly once — a dropped completion leaves the caller's spinner/refresh
    /// control waiting forever (the "tap does nothing" bug this replaces).
    func getFolderChildrenV2(folderId: String, completion: @escaping (ChildrenFetchOutcome) -> Void) {
        // Request the whole folder in a single page (see FolderV2Endpoint.maxChildrenPageSize).
        let apiOperation = APIOperation(FolderV2Endpoint.getFolderChildren(folderId: folderId, shareToken: "", pageSize: FolderV2Endpoint.maxChildrenPageSize))

        // Snapshot the per-child context and sort on the calling (main) thread so the
        // decode/map/sort can run off-main without touching main-only view-model state.
        // Base context is archive-derived; Shared overrides it to inherit the entered
        // folder's role (the V2 payload has no per-child accessRole).
        let context = v2ChildContext(enteredFolder: v2EnteredFolder)
        let permissions = context.permissions
        let accessRole = context.accessRole
        let sortOption = activeSortOption

        // Staleness guard: decodes run on a CONCURRENT queue, so two in-flight fetches
        // (e.g. a silent refresh overlapping a folder tap, or a sort change mid-flight)
        // could land out of order and a stale result would overwrite the newer listing.
        // Only the newest request may commit. Superseded fetches commit NOTHING but do
        // report `.superseded` — dropping their completion entirely (the old behavior)
        // left the superseded caller's spinner/refresh control waiting forever.
        // Touched on main only.
        childrenFetchGeneration += 1
        let generation = childrenFetchGeneration

        apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { completion(.failed(message: .errorMessage)); return }
            // Resolves this fetch on main exactly once, downgrading any outcome to
            // `.superseded` when a newer fetch has claimed the generation meanwhile.
            let resolve: (ChildrenFetchOutcome, (() -> Void)?) -> Void = { outcome, commit in
                guard generation == self.childrenFetchGeneration else {
                    completion(.superseded)
                    return
                }
                commit?()
                completion(outcome)
            }
            switch result {
            case .json(let response, _):
                // Re-decode (JSONSerialization + Codable) over the unbounded page, plus the
                // per-item map and sort, run off-main. NOTE: this is a partial win — the
                // dispatcher already parsed the raw body on the main thread before this
                // callback (APINetworkSession hops completions to main), so a residual
                // main-thread cost remains for very large folders.
                DispatchQueue.global(qos: .userInitiated).async {
                    guard
                        let model: FolderChildrenV2Response = JSONHelper.decoding(from: response, with: FolderChildrenV2Response.decoder),
                        // `items == nil` (missing/renamed key on an otherwise-decodable 2xx
                        // body) is a contract failure, NOT an empty folder — every field of
                        // FolderChildrenV2Response is optional, so only a PRESENT-but-empty
                        // array means "verified empty". Anything else → V1 failsafe.
                        let items = model.items
                    else {
                        DispatchQueue.main.async { resolve(.failed(message: .errorMessage), nil) }
                        return
                    }
                    var mapped: [FileModel] = []
                    for item in items {
                        let file = FileModel(model: item, permissions: permissions, accessRole: accessRole)
                        // Sanity gate on the SOURCE item's kind (the field that actually received
                        // the id): a write-critical id that resolved to the -1 sentinel is a
                        // contract break — bail so the caller falls back to V1 rather than render
                        // items whose move/delete/rename would target id -1. folderLinkId is
                        // checked for BOTH kinds: every retained V1 write (delete, move, share)
                        // keys on it, and a missing one silently becomes -1 in the FileModel init.
                        // archiveNo is checked too: retained V1 writes (rename/move/batch edit)
                        // send it, and a missing `archiveNumber` silently becomes archiveNbr "".
                        let hasBadId = (item.isFolder ? file.folderId <= 0 : file.recordId <= 0) || file.folderLinkId <= 0 || file.archiveNo.isEmpty
                        if hasBadId {
                            DispatchQueue.main.async { resolve(.failed(message: .errorMessage), nil) }
                            return
                        }
                        mapped.append(file)
                    }
                    let sorted = FilesViewModel.sorted(mapped, by: sortOption)
                    DispatchQueue.main.async {
                        resolve(.committed, { self.viewModels = sorted })
                    }
                }

            case .error(let error, _):
                resolve(.failed(message: error?.localizedDescription), nil)

            default:
                resolve(.failed(message: .errorMessage), nil)
            }
        }
    }

    /// Client-side ordering matching the six server sort options. Stela's `/children`
    /// sorts by the folder's stored setting and takes no sort param, so the active
    /// option is applied here. Parity with server collation is verified during the
    /// staging shadow window.
    func sortedByActiveOption(_ items: [FileModel]) -> [FileModel] {
        return FilesViewModel.sorted(items, by: activeSortOption)
    }

    /// Static so it can run off the main thread (see `getFolderChildrenV2`). For the
    /// date/type options the sort key is precomputed once per item and the decorated
    /// pairs are sorted (Swift's sort is stable), instead of recomputing the key —
    /// notably `parseSortDate`'s two DateFormatter attempts — on every comparison.
    static func sorted(_ items: [FileModel], by option: SortOption) -> [FileModel] {
        switch option {
        case .nameAscending:  return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .nameDescending: return items.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedDescending }
        case .dateAscending, .dateDescending:
            let decorated = items.map { (key: parseSortDate($0.createdDT), file: $0) }
            let sorted = option == .dateAscending
                ? decorated.sorted { $0.key < $1.key }
                : decorated.sorted { $0.key > $1.key }
            return sorted.map { $0.file }
        case .typeAscending, .typeDescending:
            let decorated = items.map { (key: $0.type.rawValue + "|" + $0.name.lowercased(), file: $0) }
            let sorted = option == .typeAscending
                ? decorated.sorted { $0.key < $1.key }
                : decorated.sorted { $0.key > $1.key }
            return sorted.map { $0.file }
        }
    }

    // Parses a Stela date (records: displayDate, folders: displayTimestamp) into a
    // comparable Date, so a mixed folder/record listing sorts chronologically regardless
    // of raw-string format. Missing/unparseable dates sort oldest.
    //
    // Stela emits several shapes across endpoints (see ShareItemLinkSettingsViewModel):
    //   • "2025-10-09T08:35:55Z"       — ISO8601, no fractional seconds
    //   • "2025-10-09T08:35:55.000Z"   — ISO8601 with fractional seconds (JS toISOString)
    //   • "2025-10-09 08:35:55+00"     — Postgres timestamptz (space separator, "+00" offset)
    //   • "2025-10-09T08:35:55"        — zone-less local
    // Each is tried in turn; anything unrecognized sorts as .distantPast.
    private static let sortDateISO = ISO8601DateFormatter()
    private static let sortDateISOFractional: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private static let sortDatePostgres: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        // Lowercase `x` renders/parses the hour-only offset "+00" that Postgres emits.
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ssx"
        return formatter
    }()
    private static let sortDatePlain: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        // Anchor to UTC like the other three formatters: zone-less Stela timestamps are
        // server-UTC, and a device-local parse would skew mixed-format listings by the
        // device's UTC offset (same convention as ShareItemLinkSettingsViewModel).
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
    static func parseSortDate(_ raw: String?) -> Date {
        guard let raw = raw, !raw.isEmpty else { return .distantPast }
        return sortDateISO.date(from: raw)
            ?? sortDateISOFractional.date(from: raw)
            ?? sortDatePostgres.date(from: raw)
            ?? sortDatePlain.date(from: raw)
            ?? .distantPast
    }
    
    func onGetLeanItemsSuccess(_ model: NavigateMinResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        viewModels.removeAll()
        
        childItems.forEach {
            let file = FileModel(model: $0, permissions: self.archivePermissions, accessRole: self.archiveAccessRole)
            self.viewModels.append(file)
        }
        
        handler(.success)
    }

    func onNavigateMinSuccess(_ model: NavigateMinResponse, _ backNavigation: Bool, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS,
            let archiveNo = folderVO.archiveNbr,
            let folderLinkId = folderVO.folderLinkID
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        let folderLinkIds: [Int] = childItems.compactMap { $0.folderLinkID }
        
        if !backNavigation {
            let file = FileModel(model: folderVO, permissions: archivePermissions, accessRole: archiveAccessRole)
            navigationStack.append(file)
        }
        
        let params: GetLeanItemsParams = (archiveNo, activeSortOption, folderLinkIds, folderLinkId)
        getLeanItems(params: params, then: handler)
    }
    
    func changeArchive(withArchiveId toArchiveId: Int, archiveNbr: String, completion: @escaping ((Bool) -> Void)) {
        let changeArchiveOperation = APIOperation(ArchivesEndpoint.change(archiveId: toArchiveId, archiveNbr: archiveNbr))
        changeArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<ArchiveVO>.decoder),
                    model.isSuccessful
                else {
                    completion(false)
                    return
                }
                
                if let archive = model.results[0].data?[0].archiveVO {
                    AuthenticationManager.shared.updateSelectedArchive(archive)
                    
                    completion(true)
                } else {
                    completion(false)
                }
                return
                
            case .error:
                completion(false)
                return
                
            default:
                completion(false)
                return
            }
        }
    }
    
    func rename(file: FileModel, name: String?, then handler: @escaping ServerResponse) {
        // Record rename → Stela PATCH /records/{id} (My Files only) with V1 as an automatic
        // failsafe; renaming to the same name is idempotent so re-applying is harmless.
        // Folder rename has no V2 route and stays on V1.
        if usesStelaNavigation, !file.type.isFolder, file.recordId > 0, let newName = name, !newName.isEmpty {
            let apiOperation = APIOperation(RecordV2Endpoint.patchRecord(recordId: String(file.recordId), fields: ["displayName": newName]))
            apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
                switch result {
                case .json:
                    handler(.success)
                default:
                    self?.performV1Rename(file: file, name: name, then: handler) // failsafe
                }
            }
            return
        }
        performV1Rename(file: file, name: name, then: handler)
    }

    private func performV1Rename(file: FileModel, name: String?, then handler: @escaping ServerResponse) {
        var params: UpdateRecordParams
        var apiOperation: APIOperation

        if file.type.isFolder {
            params = (name, nil, nil, nil, file.folderId, file.folderLinkId, file.archiveNo)
            apiOperation = APIOperation(FilesEndpoint.renameFolder(params: params))
        } else {
            params = (name, nil, nil, nil, file.recordId, file.folderLinkId, file.archiveNo)
            apiOperation = APIOperation(FilesEndpoint.update(params: params))
        }

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful

                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                handler(.success)

            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))

            default:
                break
            }
        }
    }
    
    func getPublicRoot(archiveNbr: String, then handler: @escaping (PublicRootRequestStatus) -> Void) {
        let apiOperation = APIOperation(FilesEndpoint.getPublicRoot(archiveNbr: archiveNbr))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    handler(.success(folder: model.results?.first?.data?.first?.folderVO))
                } else {
                    handler(.error(message: .errorMessage))
                }
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    func updateCheckboxState() {
        if let numberOfSelectedItems = selectedFiles?.count {
            switch numberOfSelectedItems {
            case .zero: checkboxState = .none
            case viewModels.count: checkboxState = .selected
            default: checkboxState = .partial
            }
        }
    }
}
