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
    /// it on the main thread and drop their result (see `getFolderChildrenV2`).
    private var childrenFetchGeneration = 0

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
        }
    }

    func relocate(files: [FileModel]?, to destination: FileModel, then handler: @escaping ServerResponse) {
        guard let files = files else {
            handler(.error(message: "No files selected".localized()))
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
        guard let archiveNbr = currentArchive?.archiveNbr else { return }
        
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
            let folderId = String(target.folderId)
            getFolderChildrenV2(folderId: folderId) { [weak self] result in
                guard let self = self else { handler(.error(message: .errorMessage)); return }
                switch result {
                case .success:
                    if !backNavigation { self.navigationStack.append(target) }
                    #if DEBUG
                    FilesViewModel.lastNavigationSource = "v2"
                    #endif
                    handler(.success)
                default:
                    // Failsafe — fall back to the legacy V1 navigation transparently.
                    self.performV1NavigateMin(params: params, backNavigation: backNavigation, then: handler)
                }
            }
            return
        }
        performV1NavigateMin(params: params, backNavigation: backNavigation, then: handler)
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

    /// Fetches a folder's children via the Stela `/folders/{id}/children` endpoint,
    /// maps them into `FileModel`s (archive-derived permissions), applies the active
    /// sort client-side (the endpoint has no sort param), and replaces `viewModels`.
    /// Reports `.error` on any failure or corruption so the caller can fall back to V1.
    func getFolderChildrenV2(folderId: String, then handler: @escaping ServerResponse) {
        // Request the whole folder in a single page (see FolderV2Endpoint.maxChildrenPageSize).
        let apiOperation = APIOperation(FolderV2Endpoint.getFolderChildren(folderId: folderId, shareToken: "", pageSize: FolderV2Endpoint.maxChildrenPageSize))

        // Snapshot the archive-derived context and sort on the calling (main) thread so the
        // decode/map/sort can run off-main without touching main-only view-model state.
        let permissions = archivePermissions
        let accessRole = archiveAccessRole
        let sortOption = activeSortOption

        // Staleness guard: decodes run on a CONCURRENT queue, so two in-flight fetches
        // (e.g. a silent refresh overlapping a folder tap, or a sort change mid-flight)
        // could land out of order and a stale result would overwrite the newer listing.
        // Only the newest request may commit; superseded ones are dropped silently
        // (their superseder delivers the final state). Touched on main only.
        childrenFetchGeneration += 1
        let generation = childrenFetchGeneration

        apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            guard let self = self else { handler(.error(message: .errorMessage)); return }
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
                        DispatchQueue.main.async {
                            guard generation == self.childrenFetchGeneration else { return } // superseded
                            handler(.error(message: .errorMessage))
                        }
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
                            DispatchQueue.main.async {
                                guard generation == self.childrenFetchGeneration else { return } // superseded
                                handler(.error(message: .errorMessage))
                            }
                            return
                        }
                        mapped.append(file)
                    }
                    let sorted = FilesViewModel.sorted(mapped, by: sortOption)
                    DispatchQueue.main.async {
                        guard generation == self.childrenFetchGeneration else { return } // superseded
                        self.viewModels = sorted
                        handler(.success)
                    }
                }

            case .error(let error, _):
                guard generation == self.childrenFetchGeneration else { return } // superseded
                handler(.error(message: error?.localizedDescription))

            default:
                guard generation == self.childrenFetchGeneration else { return } // superseded
                handler(.error(message: .errorMessage))
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
