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

    /// Private Files opts into Stela V2 navigation via the in-app
    /// `FeatureFlags.useStelaNavigation` constant. `PublicFilesViewModel` inherits this
    /// (same owner workspace), and `SearchFilesViewModel` opts in with its own override —
    /// so flipping the flag switches My Files, Public Files, AND Search drill-in to V2.
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

    /// Test seam: overrides the raw `/folders/{id}/children` fetch used by `getRootV2` to
    /// resolve the "My Files" child. Distinct from `getFolderChildrenV2` (which commits to
    /// `viewModels`); this one only returns the decoded items.
    var rootChildrenFetchV2Request: ((String, @escaping (Result<[FolderChildV2Data], Error>) -> Void) -> Void)?

    /// The archive section-root this workspace lands in — My Files = the private root.
    /// `PublicFilesViewModel` overrides these to land in the public root, reusing the whole
    /// V2 discovery path below (the only per-workspace difference is which section child and
    /// which V1 failsafe).
    var rootSectionType: FileType { .privateRootFolder }
    var rootSectionFallbackDisplayName: String { Constants.API.FileType.myFilesFolder }

    func getRoot(then handler: @escaping ServerResponse) {
        // Stela V2 root discovery (VSP-1787), gated by `useStelaNavigation`, with the V1
        // bootstrap kept as the automatic failsafe on any error/anomaly.
        if usesStelaNavigation {
            getRootV2(then: handler)
        } else {
            performV1GetRoot(then: handler)
        }
    }

    /// Root discovery without V1: resolve the workspace's section-root folder purely from
    /// Stela reads, seed it as the V2 navigation target, then list it via the existing
    /// children path. If resolution fails for ANY reason, fall back to `performV1GetRoot`.
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

    /// Resolves the "My Files" folder as a `FileModel` from Stela reads only: the archive's
    /// `rootFolderId` (matched by `archiveNbr` in the archives list) → that root's children →
    /// the `type.folder.root.private` child (display-name fallback). Applies the same id
    /// sanity gate the navigation relies on. Returns nil on ANY failure (no current archive,
    /// network error, archive not listed, missing/invalid My Files child, bad id) so the
    /// caller can fall back to V1. Side-effect-free (no navigation, no V1) — the
    /// unit-testable core of `getRootV2`.
    func resolveMyFilesTargetV2(completion: @escaping (FileModel?) -> Void) {
        resolveSectionRootTargetV2(sectionType: .privateRootFolder, fallbackDisplayName: Constants.API.FileType.myFilesFolder, completion: completion)
    }

    /// Resolves an archive SECTION-ROOT (private "My Files", public, …) as a `FileModel` from
    /// Stela reads only: the archive's `rootFolderId` (matched by `archiveNbr` in the archives
    /// list) → that root's children → the child whose Stela `type` maps to `sectionType`
    /// (display-name fallback). Applies the same id sanity gate the navigation relies on.
    /// Returns nil on ANY failure (no current archive, network error, archive not listed,
    /// missing/invalid section child, bad id) so the caller can fall back to V1.
    /// Side-effect-free (no navigation, no V1) — the unit-testable core of `getRootV2`.
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
                // Guard the ids the V2 navigation and its V1 `navigateMin` failsafe rely on:
                // a folderId/folderLinkId that resolved to the -1 sentinel, or an empty
                // archiveNo, is a contract break — return nil so the caller uses V1 rather
                // than a target whose listing/failsafe keys on a bad id.
                guard model.folderId > 0, model.folderLinkId > 0, !model.archiveNo.isEmpty else {
                    completion(nil)
                    return
                }
                completion(model)
            }
        }
    }

    /// Selects a section-root child (private / public / app root) among an archive root's
    /// children. Matches the Stela section `type` first (normalized via `FileType.fromV2`),
    /// then falls back to the display name — parity with the V1 `childItemVOS` lookup and a
    /// safety net until a live Stela `type` value is confirmed for every environment.
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
                // Terminal failsafe of the whole root-discovery path — never drop the
                // completion (a dropped handler hangs the caller's spinner, the exact
                // VSP-1777 bug). `getRoot` is a `.data` request so only .json/.error fire
                // today; this keeps "complete exactly once" structurally guaranteed.
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
        
        // Stela has no root-discovery route, so the V1 getRoot above stays as the
        // bootstrap. When V2 is on, seed the navigation target (the My Files root) so
        // navigateMin descends into it via /folders/{id}/children.
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
