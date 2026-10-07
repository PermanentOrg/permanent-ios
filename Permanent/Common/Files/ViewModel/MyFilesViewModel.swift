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
    
    /// The archive section-root this workspace lands in. `PublicFilesViewModel` overrides it and
    /// reuses the whole discovery path below.
    var rootSectionType: FileType { .privateRootFolder }
    var rootSectionFallbackDisplayName: String { Constants.API.FileType.myFilesFolder }

    func getRoot(then handler: @escaping ServerResponse) {
        // Stela V2 root discovery, with the V1 bootstrap kept as the
        // automatic failsafe on any error/anomaly.
        getRootV2(then: handler)
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

    /// The private-root ("My Files") child. Retained for existing tests and callers.
    static func privateRootChild(in children: [FolderChildV2Data]) -> FolderChildV2Data? {
        sectionRootChild(in: children, sectionType: .privateRootFolder, fallbackDisplayName: Constants.API.FileType.myFilesFolder)
    }

    /// Kept as the entry point tests and callers know; the selection rule lives in the shared resolver.
    static func sectionRootChild(in children: [FolderChildV2Data], sectionType: FileType, fallbackDisplayName: String) -> FolderChildV2Data? {
        SectionRootResolverV2.sectionRootChild(in: children, sectionType: sectionType, fallbackDisplayName: fallbackDisplayName)
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
        
        // Stela has no root-discovery route, so the V1 getRoot above stays the bootstrap. Seed the
        // navigation target so drill-in descends through `/children`.
        v2NavigationTarget = FileModel(model: myFilesFolder)

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
