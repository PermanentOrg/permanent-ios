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

    /// Enable Stela V2 folder drill-in for the Shared workspace (same switch the other
    /// file screens use), with the V1 two-step navigation kept as the automatic failsafe.
    /// The Shared ROOT still loads via V1 `getShares` — there is no V2 aggregate route yet.
    override var usesStelaNavigation: Bool { FeatureFlags.useStelaNavigation }

    /// V2 `/folders/{id}/children` carries no per-child accessRole, and a shared folder's
    /// contents inherit the folder's grant (confirmed 2026-07-22: a shared folder's own
    /// `shares[]` holds the role, but every child comes back with `shares: []`). So stamp
    /// each child with the ENTERED folder's role ∩ archive permissions — identical to the
    /// V1 `onGetLeanItemsSuccess` path this replaces. Fails CLOSED: with no entered folder
    /// the role falls back to `.viewer` (read-only), never the broader archive role, so a
    /// missing role can only ever under-grant. (A child shared at a *different* level than
    /// its folder inherits the folder's role here; realistically such overrides only raise
    /// access, so inheriting under-grants — safe — and any fetch failure falls back to V1,
    /// which carries the true per-item roles.)
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
    
    /// Monotonic token so two overlapping `getShares` calls cannot interleave their results.
    ///
    /// The archive-change notification fires more than once per switch (it is posted from
    /// `AuthenticationManager.updateSelectedArchive`, `ArchivesViewModel.setCurrentArchive` and
    /// the archives screen), so the handler started two fetches. Both cleared the three arrays
    /// up front and both appended on response, which made three shared items render as six — and
    /// when the surviving request was the one whose completion the view controller's supersede
    /// guard dropped, the arrays stayed cleared and the list rendered EMPTY until a manual
    /// pull-to-refresh. Verified from a device trace: `withMe=3` then `withMe=6` for 3 real items.
    ///
    /// Two changes make a fetch atomic: parse into locals and commit once, and do not clear
    /// anything up front — blanking the list at request start is what turned a dropped response
    /// into a visibly empty screen. A stale refresh now leaves the previous content alone.
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

                    // Commit once, after the whole response is parsed. This assignment used to sit
                    // INSIDE the archive loop, so a response carrying no archives never ran it and
                    // left `viewModels` in whatever state the up-front clear had put it in.
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
