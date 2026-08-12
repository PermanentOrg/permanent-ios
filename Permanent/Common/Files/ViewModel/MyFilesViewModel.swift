//
//  MyFilesViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 19.02.2021.
//

import Foundation

protocol MyFilesViewModelPickerDelegate: AnyObject {
    func myFilesVMDidPickFile(viewModel: MyFilesViewModel, file: FileModel)
}

class MyFilesViewModel: FilesViewModel {
    static let didSelectFilesNotifName = NSNotification.Name("MyFilesViewModel.didSelectFilesNotifName")
    var isPickingImage: Bool = false
    weak var pickerDelegate: MyFilesViewModelPickerDelegate?

    /// Private Files opts into V2 navigation via the in-app flag. Public Files inherits it and Search
    /// overrides it, so the one flag switches all three.
    override var usesStelaNavigation: Bool {
        FeatureFlags.useStelaNavigation
    }

    override var currentFolderIsRoot: Bool { navigationStack.count == 1 }
    
    override var selectedFiles: [FileModel]? {
        get {
            return AuthenticationManager.shared.session?.selectedFiles
        }
        
        set {
            AuthenticationManager.shared.session?.selectedFiles = newValue
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
    
    override var fileAction: FileAction {
        get {
            return AuthenticationManager.shared.session?.fileAction ?? .none
        }
        
        set {
            AuthenticationManager.shared.session?.fileAction = newValue
        }
    }
    
    var rootFolderName: String {
        return .myFiles
    }
    
    /// Test seam: overrides the Stela archives fetch so `getRootV2` can be driven without
    /// network (mirrors `childrenFetchV2Request` / `AuthenticationManager.changeArchiveOverride`).
    var archivesFetchV2Request: ((@escaping (Result<[ArchiveV2Data], Error>) -> Void) -> Void)?

    /// Test seam for the raw children fetch `getRootV2` uses. Distinct from `getFolderChildrenV2`,
    /// which commits to `viewModels`; this only returns the decoded items.
    var rootChildrenFetchV2Request: ((String, @escaping (Result<[FolderChildV2Data], Error>) -> Void) -> Void)?

    /// The archive section-root this workspace lands in. `PublicFilesViewModel` overrides it and
    /// reuses the whole discovery path below.
    var rootSectionType: FileType { .privateRootFolder }
    var rootSectionFallbackDisplayName: String { Constants.API.FileType.myFilesFolder }

    func getRoot(then handler: @escaping ServerResponse) {
        // Stela V2 root discovery, gated by `useStelaNavigation`, with the V1
        // bootstrap kept as the automatic failsafe on any error/anomaly.
        if usesStelaNavigation {
            getRootV2(then: handler)
        } else {
            performV1GetRoot(then: handler)
        }
    }

    /// Root discovery from Stela reads only: resolve the section root, seed it as the V2 target, then
    /// list it. Any failure falls back to `performV1GetRoot`.
    private func getRootV2(then handler: @escaping ServerResponse) {
        resolveSectionRootTargetV2(sectionType: rootSectionType, fallbackDisplayName: rootSectionFallbackDisplayName) { [weak self] sectionRootModel in
            guard let self = self else { handler(.error(message: .errorMessage)); return }
            guard let sectionRootModel = sectionRootModel else {
                self.performV1GetRoot(then: handler)
                return
            }
            self.v2NavigationTarget = sectionRootModel
            let params: NavigateMinParams = (sectionRootModel.archiveNo, sectionRootModel.folderLinkId, nil)
            self.navigateMin(params: params, backNavigation: false, then: handler)
        }
    }

    /// Resolves "My Files" from Stela reads only, applying the same id sanity gate navigation uses.
    /// Nil on any failure so the caller falls back to V1. Side-effect-free, hence testable.
    func resolveMyFilesTargetV2(completion: @escaping (FileModel?) -> Void) {
        resolveSectionRootTargetV2(sectionType: .privateRootFolder, fallbackDisplayName: Constants.API.FileType.myFilesFolder, completion: completion)
    }

    /// Resolves any archive section-root from Stela reads only: the archive's `rootFolderId`, then the
    /// child matching `sectionType`. Nil on any failure so the caller falls back to V1.
    func resolveSectionRootTargetV2(sectionType: FileType, fallbackDisplayName: String, completion: @escaping (FileModel?) -> Void) {
        guard let archiveNbr = currentArchive?.archiveNbr, !archiveNbr.isEmpty else {
            completion(nil)
            return
        }
        fetchArchivesV2 { [weak self] result in
            guard let self = self else { completion(nil); return }
            guard
                case .success(let archives) = result,
                let rootFolderId = archives.first(where: { $0.archiveNbr == archiveNbr })?.rootFolderId,
                !rootFolderId.isEmpty
            else {
                completion(nil)
                return
            }
            self.fetchRootChildrenV2(folderId: rootFolderId) { [weak self] childrenResult in
                guard let self = self else { completion(nil); return }
                guard
                    case .success(let children) = childrenResult,
                    let sectionChild = Self.sectionRootChild(in: children, sectionType: sectionType, fallbackDisplayName: fallbackDisplayName)
                else {
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
    }

    /// Picks a section-root child among an archive root's children, matching the Stela `type` first
    /// and the display name second — a safety net until every environment's `type` is confirmed.
    static func sectionRootChild(in children: [FolderChildV2Data], sectionType: FileType, fallbackDisplayName: String) -> FolderChildV2Data? {
        if let byType = children.first(where: {
            $0.isFolder && FileType.fromV2(typeString: $0.type, isFolder: true) == sectionType
        }) {
            return byType
        }
        return children.first(where: {
            $0.isFolder && $0.displayName == fallbackDisplayName
        })
    }

    /// The private-root ("My Files") child. Retained for existing tests and callers.
    static func privateRootChild(in children: [FolderChildV2Data]) -> FolderChildV2Data? {
        sectionRootChild(in: children, sectionType: .privateRootFolder, fallbackDisplayName: Constants.API.FileType.myFilesFolder)
    }

    private func fetchArchivesV2(completion: @escaping (Result<[ArchiveV2Data], Error>) -> Void) {
        if let injected = archivesFetchV2Request {
            injected(completion)
            return
        }
        let endpoint = ArchiveV2Endpoint.searchArchives(
            callerMembershipRoles: ArchiveV2Endpoint.allMembershipRoles,
            pageSize: ArchiveV2Endpoint.defaultPageSize
        )
        APIOperation(endpoint).execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: ArchivesV2Response = JSONHelper.decoding(from: response, with: ArchivesV2Response.decoder),
                    let items = model.items
                else {
                    completion(.failure(APIError.parseError))
                    return
                }
                completion(.success(items))
            case .error(let error, _):
                completion(.failure(error ?? APIError.unknown))
            default:
                completion(.failure(APIError.unknown))
            }
        }
    }

    private func fetchRootChildrenV2(folderId: String, completion: @escaping (Result<[FolderChildV2Data], Error>) -> Void) {
        if let injected = rootChildrenFetchV2Request {
            injected(folderId, completion)
            return
        }
        let endpoint = FolderV2Endpoint.getFolderChildren(folderId: folderId, shareToken: "", pageSize: FolderV2Endpoint.maxChildrenPageSize)
        APIOperation(endpoint).execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: FolderChildrenV2Response = JSONHelper.decoding(from: response, with: FolderChildrenV2Response.decoder),
                    let items = model.items
                else {
                    completion(.failure(APIError.parseError))
                    return
                }
                completion(.success(items))
            case .error(let error, _):
                completion(.failure(error ?? APIError.unknown))
            default:
                completion(.failure(APIError.unknown))
            }
        }
    }

    /// V1 failsafe bootstrap. Overridable so `PublicFilesViewModel` can fall back to
    /// `getPublicRoot` instead of `getRoot`.
    func performV1GetRoot(then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getRoot)

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }

                if model.isSuccessful == true {
                    self.onGetRootSuccess(model, handler)
                } else {
                    handler(.error(message: .errorMessage))
                }

            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))

            default:
                // Terminal failsafe of the whole root-discovery path: never drop the completion, or the caller's
                // spinner hangs. Keeps "complete exactly once" structurally guaranteed.
                handler(.error(message: .errorMessage))
            }
        }
    }
    
    private func onGetRootSuccess(_ model: GetRootResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let myFilesFolder = folderVO.childItemVOS?.first(where: { $0.displayName == Constants.API.FileType.myFilesFolder }),
            let archiveNo = myFilesFolder.archiveNbr,
            let folderLinkId = myFilesFolder.folderLinkID
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        // Stela has no root-discovery route, so the V1 getRoot above stays the bootstrap. With V2 on,
        // seed the navigation target so drill-in descends through `/children`.
        if usesStelaNavigation {
            v2NavigationTarget = FileModel(model: myFilesFolder)
        }

        let params: NavigateMinParams = (archiveNo, folderLinkId, nil)
        navigateMin(params: params, backNavigation: false, then: handler)
    }
    
    func trackOpenFiles(action: AccountEventAction = AccountEventAction.openPrivateWorkspace) {
        trackEvent(action: action)
    }
    
    func trackEvent(action: any EventAction) {
        guard let accountId = AuthenticationManager.shared.session?.account.accountID,
              let payload = EventsPayloadBuilder.build(accountId: accountId,
                                                       eventAction: action,
                                                       entityId: String(accountId),
                                                       data: ["workspace": rootFolderName]) else { return }
        let updateAccountOperation = APIOperation(EventsEndpoint.sendEvent(eventsPayload: payload))
        updateAccountOperation.execute(in: APIRequestDispatcher()) {_ in}
    }
}
