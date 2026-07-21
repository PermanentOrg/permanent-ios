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
    
    func getRoot(then handler: @escaping ServerResponse) {
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
                break
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
