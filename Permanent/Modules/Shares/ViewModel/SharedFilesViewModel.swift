//
//  SharedFilesViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 18.02.2021.
//

import Foundation

class SharedFilesViewModel: FilesViewModel {
    static let didSelectFilesNotifName = NSNotification.Name("SharedFilesViewModel.didSelectFilesNotifName")
    override var currentFolderIsRoot: Bool { navigationStack.count == 0 }

    /// The share list is on screen: no folder is open and none is being entered.
    var showsShareList: Bool {
        navigationStack.isEmpty && (!isLoadingFirstPage || (shareListLoads > 0 && firstPageLoads == shareListLoads))
    }

    /// Share-list loads under skeleton rows. They count as first-page loads, but they are not folder entries.
    private var shareListLoads = 0

    func beginShareListLoad() {
        shareListLoads += 1
        beginFirstPageLoad()
    }

    /// `true` when this ended the last first-page load under way.
    @discardableResult
    func endShareListLoad() -> Bool {
        shareListLoads = max(0, shareListLoads - 1)
        return endFirstPageLoad()
    }

    /// Counted as a share-list load, so a share list that loads under the swipe still counts as on screen.
    override func beginBackPreview() {
        shareListLoads += 1
        super.beginBackPreview()
    }

    @discardableResult
    override func endBackPreview() -> Bool {
        shareListLoads = max(0, shareListLoads - 1)
        return super.endBackPreview()
    }

    /// The V2 payload carries no per-child accessRole, so each child takes the entered folder's role
    /// intersected with archive permissions. Fails closed to `.viewer`, so it can only under-grant.
    override func v2ChildContext(enteredFolder: FileModel?) -> (permissions: [Permission], accessRole: AccessRole) {
        let inheritedRole = enteredFolder?.accessRole ?? .viewer
        let inheritedPermissions = Set(ArchiveVOData.permissions(forAccessRole: inheritedRole.apiValue))
        let intersection = Array(Set(archivePermissions).intersection(inheritedPermissions))
        return (intersection, inheritedRole)
    }

    /// Another archive's folder: the role granted on it decides, not the session archive's.
    override var canPersistSort: Bool { currentFolder?.permissions.contains(.edit) ?? false }

    var shareListType: ShareListType = .sharedByMe {
        didSet {
            viewModels = shareListType == .sharedByMe ? sharedByMeViewModels : sharedWithMeViewModels
            holdsBackShareList = false
            navigationStack.removeAll()
        }
    }

    /// A folder opened from a share link, whose own V2 details give the role for the paged route.
    var linkedFolderId: Int?

    /// Test seam for the V2 folder details request.
    var folderV2Request: ((_ folderId: String, _ completion: @escaping (FolderV2Data?) -> Void) -> Void)?

    override func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
        guard !backNavigation, v2NavigationTarget == nil, let folderId = linkedFolderId else {
            return super.navigateMin(params: params, backNavigation: backNavigation, then: handler)
        }
        linkedFolderId = nil
        let generation = listingGeneration
        resolveLinkedFolder(folderId: folderId, params: params) { [weak self] target in
            guard let self else { return handler(.error(message: .errorMessage)) }
            // A tab or archive switch meanwhile replaced the list, so the entry ends quietly.
            guard generation == self.listingGeneration else { return handler(.success) }
            // Without the details the folder opens on the V1 route, which lists it whole.
            self.v2NavigationTarget = target
            self.enterFolder(params: params, then: handler)
        }
    }

    private func enterFolder(params: NavigateMinParams, then handler: @escaping ServerResponse) {
        super.navigateMin(params: params, backNavigation: false, then: handler)
    }

    /// Nil unless the details name the same folder link, so a mismatch can never open another folder.
    private func resolveLinkedFolder(folderId: Int, params: NavigateMinParams, completion: @escaping (FileModel?) -> Void) {
        let request = folderV2Request ?? { folderId, completion in
            APIOperation(FolderV2Endpoint.getFolderById(folderId: folderId, shareToken: "")).execute(in: APIRequestDispatcher()) { result in
                guard case .json(let response, _) = result,
                      let model: FolderV2Response = JSONHelper.decoding(from: response, with: FolderV2Response.decoder) else {
                    return completion(nil)
                }
                completion(model.items?.first)
            }
        }
        request(String(folderId)) { [weak self] folder in
            DispatchQueue.main.async {
                guard let self, let folder, folder.folderLinkId.flatMap(Int.init) == params.folderLinkId,
                      let role = self.linkedFolderRole(folder) else { return completion(nil) }
                let permissions = Array(Set(self.archivePermissions).intersection(ArchiveVOData.permissions(forAccessRole: role)))
                completion(FileModel(model: folder, fallbackArchiveNo: params.archiveNo, permissions: permissions,
                                     accessRole: AccessRole.roleForValue(role)))
            }
        }
    }

    /// Stela's top-level role is the account's best across its archives, where V1 gives the selected archive's.
    /// So only the selected archive's own folder takes it; any other takes that archive's approved share.
    private func linkedFolderRole(_ folder: FolderV2Data) -> String? {
        guard let archiveId = currentArchive?.archiveID.map(String.init) else { return nil }
        if folder.archive?.id == archiveId { return folder.accessRole ?? AccessRole.viewer.apiValue }
        let approved = folder.shares?.first { share in
            share.archive?.archiveId == archiveId && (share.status == ArchiveVOData.Status.ok.rawValue || share.status == "ok")
        }
        return approved?.accessRole
    }

    /// A share list landed while a folder was on screen or on its way, so it waits in the caches.
    private var holdsBackShareList = false

    /// Once a folder entry has failed back to the share list, the list that landed meanwhile shows.
    func showHeldBackShareList() {
        guard holdsBackShareList, showsShareList else { return }
        holdsBackShareList = false
        viewModels = shareListType == .sharedByMe ? sharedByMeViewModels : sharedWithMeViewModels
        resetChildrenPaging()
    }
    
    var sharedByMeViewModels: [FileModel] = []
    var sharedWithMeViewModels: [FileModel] = []
    
    override func shouldPerformAction(forSection section: Int) -> Bool {
        return section == FileListType.synced.rawValue && !currentFolderIsRoot
    }
    
    override func title(forSection section: Int) -> String {
        switch section {
        case FileListType.downloading.rawValue: return .downloads
        case FileListType.uploading.rawValue: return .uploads
        case FileListType.synced.rawValue: return currentFolderIsRoot && !isLoadingFirstPage ? "" : listingSortTitle
        default: return "" // We cannot have more than 3 sections.
        }
    }
    
    override var selectedFiles: [FileModel]? {
        get {
            return super.selectedFiles
        }
        set {
            super.selectedFiles = newValue
            if fileAction.action.isEmpty && isSelecting {
                if selectedFiles?.isEmpty ?? true {
                    NotificationCenter.default.post(name: Self.didSelectFilesNotifName, object: self, userInfo: ["showFloatingIsland": false])
                } else {
                    NotificationCenter.default.post(name: Self.didSelectFilesNotifName, object: self, userInfo: ["showFloatingIsland": true])
                }
            }
            updateCheckboxState()
        }
    }
    
    /// Monotonic token so two overlapping `getShares` calls can't interleave: the archive-change
    /// notification fires several times per switch. Fetches parse into locals and commit once.
    private var sharesRequestGeneration = 0

    func getShares(then handler: @escaping ServerResponse) {
        sharesRequestGeneration += 1
        let generation = sharesRequestGeneration

        let apiOperation = APIOperation(ShareEndpoint.getShares)

        apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            DispatchQueue.main.async {
                guard let self = self else { return handler(.error(message: .errorMessage)) }
                // A superseded fetch must not touch published state: a newer request is already
                // in flight and its response is the authoritative one. Still call back so the caller
                // can release its spinner — a stranded spinner is worse than a redundant hide.
                guard generation == self.sharesRequestGeneration else { return handler(.success) }

                switch result {
                case .json(let response, _):
                    guard let model: APIResults<ArchiveVO> = JSONHelper.decoding( from: response, with: APIResults<ArchiveVO>.decoder)
                    else {
                        return handler(.error(message: .errorMessage))
                    }

                    let currentArchive: ArchiveVOData? = AuthenticationManager.shared.session?.selectedArchive
                    let currentArchiveId: Int? = currentArchive?.archiveID
                    let archivePermissionsSet = Set(self.archivePermissions)

                    var byMe: [FileModel] = []
                    var withMe: [FileModel] = []

                    model.results.first?.data?.forEach { archive in
                        archive.archiveVO?.itemVOS?.forEach {
                            let accessRole = AccessRole.roleForValue($0.accessRole)
                            let itemPermissionsSet = Set(ArchiveVOData.permissions(forAccessRole: $0.accessRole ?? ""))
                            let permissionsIntersection = Array(archivePermissionsSet.intersection(itemPermissionsSet))

                            let sharedByArchive = $0.archiveID == currentArchiveId ? nil : archive.archiveVO
                            let sharedFileVM = FileModel(model: $0, archiveThumbnailURL: archive.archiveVO?.thumbURL200, sharedByArchive: sharedByArchive, permissions: permissionsIntersection, accessRole: accessRole)

                            if $0.archiveID == currentArchiveId {
                                byMe.append(sharedFileVM)
                            } else {
                                withMe.append(sharedFileVM)
                            }
                        }
                    }

                    // Commit once, after the whole response is parsed — inside the archive loop, a response with no
                    // archives never runs it and leaves the previous state behind.
                    self.sharedByMeViewModels = byMe
                    self.sharedWithMeViewModels = withMe
                    // A folder on screen, or one being entered, keeps its rows; the share list waits in its caches.
                    self.holdsBackShareList = !self.showsShareList
                    if self.showsShareList {
                        self.viewModels = self.shareListType == .sharedByMe ? byMe : withMe
                        // The share list is not a folder, so no folder's next page may land on it.
                        self.resetChildrenPaging()
                    }

                    handler(.success)

                case .error(let error, _):
                    handler(.error(message: error?.localizedDescription))

                default:
                    // Never leave the caller hanging. The view controller hides its spinner in
                    // this handler, so a silent `break` left the Shares screen spinning forever.
                    handler(.error(message: .errorMessage))
                }
            }
        }
    }
    
    override func onNavigateMinSuccess(_ model: NavigateMinResponse, _ backNavigation: Bool, _ handler: @escaping ServerResponse) {
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
        
        var entered: FileModel?
        if !backNavigation {
            let accessRole = AccessRole.roleForValue(folderVO.accessRole)
            let archivePermissionsSet = Set(self.archivePermissions)
            let itemPermissionsSet = Set(ArchiveVOData.permissions(forAccessRole: folderVO.accessRole ?? ""))
            let permissionsIntersection = Array(archivePermissionsSet.intersection(itemPermissionsSet))
            
            entered = FileModel(model: folderVO, permissions: permissionsIntersection, accessRole: accessRole)
        }
        
        listV1Folder(entering: entered, folderId: folderVO.folderID ?? -1, savedSort: SortOption(serverValue: folderVO.sort),
                     params: (archiveNo, folderLinkIds, folderLinkId), then: handler)
    }
    
    override func onGetLeanItemsSuccess(_ model: NavigateMinResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        viewModels.removeAll()
        
        let archivePermissionsSet = Set(self.archivePermissions)
        childItems.forEach {
            let accessRole = AccessRole.roleForValue($0.accessRole)
            let itemPermissionsSet = Set(ArchiveVOData.permissions(forAccessRole: $0.accessRole ?? ""))
            let permissionsIntersection = Array(archivePermissionsSet.intersection(itemPermissionsSet))
            
            let file = FileModel(model: $0, permissions: permissionsIntersection, accessRole: accessRole)
            self.viewModels.append(file)
        }
        
        handler(.success)
    }
    
    func unshare(_ file: FileModel, then handler: @escaping ServerResponse) {
        guard let archiveId = self.currentArchive?.archiveID else {
            handler(.error(message: .errorMessage))
            return
        }
        
        let apiOperation = APIOperation(FilesEndpoint.unshareRecord(archiveId: archiveId, folderLinkId: file.folderLinkId))
        
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
    
    func trackOpenFiles(action: AccountEventAction = AccountEventAction.openSharedWorkspace) {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: action,
                                                       entityId: String(accountId),
                                                       data: ["workspace": "Shared Files"]) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}
