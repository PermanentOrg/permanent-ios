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
    case success(folder: FolderVOData?)
    case error(message: String?)

    /// `FolderVOData` is not `Equatable`, so a success compares by the folder's identity fields.
    static func == (lhs: PublicRootRequestStatus, rhs: PublicRootRequestStatus) -> Bool {
        switch (lhs, rhs) {
        case (.success(let lhsFolder), .success(let rhsFolder)):
            return lhsFolder?.folderID == rhsFolder?.folderID && lhsFolder?.folderLinkID == rhsFolder?.folderLinkID
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }

    /// Maps the V1 `getPublicRoot` result. Every case completes, so the caller's spinner always clears.
    init(operationResult: OperationResult) {
        switch operationResult {
        case .json(let response, _):
            guard let model: GetRootResponse = JSONHelper.convertToModel(from: response), model.isSuccessful == true else {
                self = .error(message: .errorMessage)
                return
            }
            self = .success(folder: model.results?.first?.data?.first?.folderVO)
        case .error(let error, _):
            self = .error(message: error?.localizedDescription)
        case .file:
            self = .error(message: .errorMessage)
        }
    }
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

    /// The folder a forward V2 navigation is heading into (the tapped item / resolved
    /// root). On back/refresh the target is taken from `navigationStack` instead.
    var v2NavigationTarget: FileModel?

    /// Monotonic id of the newest V2 children fetch. Superseded fetches compare against
    /// it on the main thread and report `.superseded` (see `getFolderChildrenV2`).
    private var childrenFetchGeneration = 0

    /// Injection seam for the V2 children fetch. Tests pin the supersede/retry policy in
    /// `navigateV2` by returning outcomes, with no network.
    var childrenFetchV2Request: ((String, @escaping (ChildrenFetchOutcome) -> Void) -> Void)?

    /// Test seam for the Stela archives fetch behind root discovery and publish. Production leaves it nil.
    var archivesFetchV2Request: ((@escaping (Result<[ArchiveV2Data], Error>) -> Void) -> Void)?

    /// Test seam for the raw children fetch behind root discovery. Distinct from `getFolderChildrenV2`,
    /// which commits to `viewModels`; this only returns the decoded items.
    var rootChildrenFetchV2Request: ((String, @escaping (Result<[FolderChildV2Data], Error>) -> Void) -> Void)?

    /// Test seam for the V1 `getPublicRoot` lookup, the publish failsafe. Production leaves it nil.
    var publicRootV1Request: ((_ archiveNbr: String, _ completion: @escaping (PublicRootRequestStatus) -> Void) -> Void)?

    /// The folder the in-flight V2 fetch is listing, so `getFolderChildrenV2` can derive per-child
    /// context. Shared inherits this folder's accessRole, since the payload carries none.
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

    /// The `(permissions, accessRole)` to stamp on each V2 child. Base uses the archive role; Shared
    /// inherits the entered folder's. Called on main, since it reads session state.
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
    
    /// Backoff schedule for post-upload thumbnail polling; each value is the wait before the next
    /// fire, spanning ~45 s in four fires. Empty disables polling.
    static let thumbnailPollIntervals: [TimeInterval] = [3, 6, 12, 24]

    /// Cadence of the post-paste and post-upload thumbnail poll. The server processes fresh copies
    /// slowly — minutes, sometimes — so this polls gently but persistently.
    static let thumbnailPollInterval: TimeInterval = 10
    /// Hard cap on consecutive polls (~5 minutes at 10s) so a folder whose records
    /// legitimately never produce a thumbnail can't refetch forever.
    static let thumbnailPollMaxRuns = 30

    /// Cadence while the pasted rows are still missing — a read-after-write race that usually clears
    /// within a second. At `thumbnailPollInterval` a pasted file took ~10s to appear.
    static let pastedItemsPollInterval: TimeInterval = 1
    /// How many polls stay on the fast cadence before falling back to the slow one, so a row
    /// that never arrives doesn't hammer the server (5 × 1s ≈ 5s of quick re-checks).
    static let pastedItemsFastRuns = 5

    /// Cadence while an item is mid copy or move, which blocks tapping it and takes tens of seconds.
    /// Slower would look broken; faster would hammer the server for the whole copy.
    static let transientStatePollInterval: TimeInterval = 2

    /// True while a listed item is still processing server-side: mid copy/move, or a record with no
    /// thumbnail source yet. Gates the poll, bounded by `thumbnailPollMaxRuns`.
    var hasItemsAwaitingProcessing: Bool {
        hasItemsInTransientState || viewModels.contains { file in
            !file.type.isFolder && (file.thumbnailURL ?? "").isEmpty
        }
    }

    /// True while an item is mid copy or move. Those are not tappable, so the user is blocked — and
    /// it clears in seconds, unlike the thumbnail wait. Drives the middle poll cadence.
    var hasItemsInTransientState: Bool {
        viewModels.contains { $0.thumbStatus == .copying || $0.thumbStatus == .moving }
    }

    /// Items the destination must list before a paste counts as landed, keyed to its folder so
    /// navigating away makes it inert. A moved record arrives with thumbnails, so count is the signal.
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

    /// Injection seam for the single-record V2 copy. Tests pin the partition and aggregation policy
    /// by returning per-record outcomes; production leaves it nil.
    var copyRecordV2Request: ((_ recordId: String, _ destinationFolderId: String, _ completion: @escaping (Bool) -> Void) -> Void)?

    /// Eligible for the idempotent V2 copy only when it is a saved record and it is in
    /// the current archive — the bearer-only V2 call would reject a foreign one.
    func isEligibleForStelaCopy(_ file: FileModel) -> Bool {
        guard !file.type.isFolder, file.recordId > 0,
              let currentArchiveId = currentArchive?.archiveID else { return false }
        return file.archiveId > 0 && file.archiveId == currentArchiveId
    }

    func relocate(files: [FileModel]?, to destination: FileModel, then handler: @escaping ServerResponse) {
        guard let files = files else {
            handler(.error(message: "No files selected".localized()))
            return
        }

        // COPY prefers the idempotent V2 endpoint per eligible record, since a failed V1 copy orphans
        // invisible files that still consume storage. A non-positive destination id is not a V2 target.
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

    /// Copies eligible records through V2 serially and the rest through the V1 batch, reporting
    /// `.success` only if every one succeeded. No V2→V1 fallback, since copy is not idempotent.
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

    /// Resolves an archive section root from Stela reads only, as a navigation or publish target.
    /// Nil on any failure so the caller falls back to V1. A write destination passes no display-name fallback.
    func resolveSectionRootTargetV2(sectionType: FileType, fallbackDisplayName: String?, completion: @escaping (FileModel?) -> Void) {
        let resolver = SectionRootResolverV2(fetchArchives: archivesFetchV2Request, fetchChildren: rootChildrenFetchV2Request)
        resolver.resolve(sectionType: sectionType, fallbackDisplayName: fallbackDisplayName, archiveNbr: currentArchive?.archiveNbr) { [weak self] sectionChild in
            guard let self = self, let sectionChild = sectionChild else {
                completion(nil)
                return
            }
            let model = FileModel(model: sectionChild, permissions: self.archivePermissions, accessRole: self.archiveAccessRole)
            // Guard the ids navigation and its failsafe key on: a -1 sentinel id or an empty archiveNo is a
            // contract break, so return nil rather than hand back a target with a bad id.
            guard model.folderId > 0, model.folderLinkId > 0, !model.archiveNo.isEmpty else {
                completion(nil)
                return
            }
            completion(model)
        }
    }

    func publish(files: [FileModel], then handler: @escaping ServerResponse) {
        fileAction = .copy
        guard let archiveNbr = currentArchive?.archiveNbr else {
            // Always complete and clear the copy state: the caller only hides its spinner in the handler,
            // so a bare `return` strands it with fileAction stuck at `.copy`.
            fileAction = .none
            handler(.error(message: .errorMessage))
            return
        }

        // The public root from the Stela archives chain first; any resolution failure falls back to the
        // V1 lookup. The copy step itself never falls back — see `relocate`.
        resolveSectionRootTargetV2(sectionType: .publicRootFolder, fallbackDisplayName: nil) { [weak self] publicRoot in
            guard let self = self else { handler(.error(message: .errorMessage)); return }
            if let publicRoot = publicRoot {
                self.relocate(files: files, to: publicRoot, then: handler)
                return
            }
            self.getPublicRoot(archiveNbr: archiveNbr) { status in
                switch status {
                case .success(let folder):
                    if let rootFolder = folder {
                        self.relocate(files: files, to: FileModel(model: rootFolder), then: handler)
                    } else {
                        self.fileAction = .none
                        handler(.error(message: .errorMessage))
                    }
                case .error(let message):
                    self.fileAction = .none
                    handler(.error(message: message))
                }
            }
        }
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
        // `position` is a captured cell index and the queue can shrink between render and tap, so
        // guard before subscripting.
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
    /// Which path served the last folder load, so a parity test cannot silently pass on the V1
    /// failsafe while claiming V2. DEBUG-only, with no Release behaviour.
    static var lastNavigationSource = "none"
    #endif

    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
        // V2 path with V1 as an automatic failsafe. Forward navigation consumes a one-shot
        // target; entries that set none (deep links) fall through to V1.
        let v2Target = backNavigation ? navigationStack.last : v2NavigationTarget
        if !backNavigation { v2NavigationTarget = nil }
        if let target = v2Target,
           target.folderId > 0 {
            navigateV2(target: target, params: params, backNavigation: backNavigation, retriesLeft: 1, then: handler)
            return
        }
        performV1NavigateMin(params: params, backNavigation: backNavigation, then: handler)
    }

    /// One V2 navigation attempt: committed → done, failed → V1 failsafe, superseded-forward →
    /// retry once, superseded-back → complete quietly. Never V1-failsafe a superseded fetch.
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

    /// Overridable so tests can observe the V1 leg without the network. A real request carries a
    /// Bearer token, and its 401 logs out asynchronously and clears the session later tests read.
    func performV1NavigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
        #if DEBUG
        // Reached as the V2 failsafe, or directly by entries that set no V2 target (deep links).
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

    /// Outcome of one V2 children fetch. `superseded` is distinct from `failed` on purpose: it
    /// committed nothing, and V1-failsafing it would reintroduce the out-of-order overwrite.
    enum ChildrenFetchOutcome {
        case committed
        case superseded
        case failed(message: String?)
    }

    /// Lists a folder's children via V2, sorts client-side (the endpoint has no sort param) and
    /// replaces `viewModels`. The completion always runs exactly once, or the spinner hangs.
    func getFolderChildrenV2(folderId: String, completion: @escaping (ChildrenFetchOutcome) -> Void) {
        // Request the whole folder in a single page (see FolderV2Endpoint.maxChildrenPageSize).
        let apiOperation = APIOperation(FolderV2Endpoint.getFolderChildren(folderId: folderId, shareToken: "", pageSize: FolderV2Endpoint.maxChildrenPageSize))

        // Snapshot the per-child context and sort on main, so the decode, map and sort can run off-main
        // without touching main-only view-model state.
        let context = v2ChildContext(enteredFolder: v2EnteredFolder)
        let permissions = context.permissions
        let accessRole = context.accessRole
        let sortOption = activeSortOption

        // Staleness guard: decodes run concurrently, so only the newest request may commit or a stale
        // result overwrites a newer listing. Superseded fetches commit nothing but still complete.
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
                // Re-decode, map and sort off-main. A partial win only: the dispatcher already parsed the raw
                // body on main before this callback, so a residual cost remains for very large folders.
                DispatchQueue.global(qos: .userInitiated).async {
                    guard
                        let model: FolderChildrenV2Response = JSONHelper.decoding(from: response, with: FolderChildrenV2Response.decoder),
                        // `items == nil` on an otherwise-decodable 2xx is a contract failure, not an empty folder —
                        // only a present-but-empty array means verified empty. Anything else falls back to V1.
                        let items = model.items
                    else {
                        DispatchQueue.main.async { resolve(.failed(message: .errorMessage), nil) }
                        return
                    }
                    var mapped: [FileModel] = []
                    for item in items {
                        let file = FileModel(model: item, permissions: permissions, accessRole: accessRole)
                        // A write-critical id that resolved to the -1 sentinel is a contract break, so bail to V1 rather
                        // than render items whose move or delete would target -1. Same for a missing archiveNo.
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

    /// Client-side ordering matching the six server sort options, applied here because `/children`
    /// sorts by the folder's stored setting and takes no sort param.
    func sortedByActiveOption(_ items: [FileModel]) -> [FileModel] {
        return FilesViewModel.sorted(items, by: activeSortOption)
    }

    /// Static so it can run off-main. Date and type options precompute the sort key once per item
    /// and sort decorated pairs, rather than re-parsing dates on every comparison.
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

    // Four formatters because Stela emits ISO8601 with and without fractional seconds, Postgres
    // timestamptz, and zone-less local. Each is tried in turn; anything else sorts oldest.
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
        // Anchor to UTC like the other three: zone-less timestamps are server-UTC, and a device-local
        // parse would skew a mixed-format listing by the device's offset.
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
    
    /// True when the record belongs to the session's selected archive. Reads the session, not
    /// `currentArchive`, which subclasses override to the archive being viewed. Unknown → false.
    func isInSessionArchive(_ file: FileModel) -> Bool {
        guard let sessionArchiveId = AuthenticationManager.shared.session?.selectedArchive?.archiveID else { return false }
        return file.archiveId > 0 && file.archiveId == sessionArchiveId
    }

    /// Whether a rename may take `PATCH /records/{id}`. Own archive only: the call is bearer-only and
    /// not exempt from the 401 handler, so a foreign record would log the user out for a legal rename.
    func canRenameViaStelaPatch(_ file: FileModel, newName: String) -> Bool {
        return !file.type.isFolder          // folder rename has no V2 route
            && file.recordId > 0
            && !newName.isEmpty
            && isInSessionArchive(file)
    }

    func rename(file: FileModel, name: String?, then handler: @escaping ServerResponse) {
        // Record rename goes through V2 with V1 as an automatic failsafe, which is safe because renaming
        // to the same name is idempotent. Folder rename has no V2 route.
        if let newName = name, canRenameViaStelaPatch(file, newName: newName) {
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

    /// Overridable (rather than private) so a test can observe that the V1 leg was taken
    /// without issuing a real request — same seam as `performV1NavigateMin`.
    func performV1Rename(file: FileModel, name: String?, then handler: @escaping ServerResponse) {
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
    
    /// The V1 public-root lookup, kept as the publish failsafe. Uses the injected seam in tests.
    func getPublicRoot(archiveNbr: String, then handler: @escaping (PublicRootRequestStatus) -> Void) {
        if let injected = publicRootV1Request {
            injected(archiveNbr, handler)
            return
        }
        let apiOperation = APIOperation(FilesEndpoint.getPublicRoot(archiveNbr: archiveNbr))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            handler(PublicRootRequestStatus(operationResult: result))
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
