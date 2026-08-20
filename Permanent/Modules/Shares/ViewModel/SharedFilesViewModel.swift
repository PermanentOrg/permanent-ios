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

    /// The V2 payload carries no per-child accessRole, so each child takes the entered folder's role
    /// intersected with archive permissions. Fails closed to `.viewer`, so it can only under-grant.
    override func v2ChildContext(enteredFolder: FileModel?) -> (permissions: [Permission], accessRole: AccessRole) {
        let inheritedRole = enteredFolder?.accessRole ?? .viewer
        let inheritedPermissions = Set(ArchiveVOData.permissions(forAccessRole: inheritedRole.apiValue))
        let intersection = Array(Set(archivePermissions).intersection(inheritedPermissions))
        return (intersection, inheritedRole)
    }

    var shareListType: ShareListType = .sharedByMe {
        didSet {
            viewModels = shareListType == .sharedByMe ? sharedByMeViewModels : sharedWithMeViewModels
            navigationStack.removeAll()
        }
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
        case FileListType.synced.rawValue: return currentFolderIsRoot ? "" : activeSortOption.title
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

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            DispatchQueue.main.async {
                // A superseded fetch must not touch published state: a newer request is already
                // in flight and its response is the authoritative one.
                guard generation == self.sharesRequestGeneration else { return }

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
                    self.viewModels = self.shareListType == .sharedByMe ? byMe : withMe

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
        
        if !backNavigation {
            let accessRole = AccessRole.roleForValue(folderVO.accessRole)
            let archivePermissionsSet = Set(self.archivePermissions)
            let itemPermissionsSet = Set(ArchiveVOData.permissions(forAccessRole: folderVO.accessRole ?? ""))
            let permissionsIntersection = Array(archivePermissionsSet.intersection(itemPermissionsSet))
            
            let file = FileModel(model: folderVO, permissions: permissionsIntersection, accessRole: accessRole)
            navigationStack.append(file)
        }
        
        let params: GetLeanItemsParams = (archiveNo, activeSortOption, folderLinkIds, folderLinkId)
        getLeanItems(params: params, then: handler)
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
