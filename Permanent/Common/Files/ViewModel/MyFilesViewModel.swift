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
    var isPickingProfilePicture: Bool = false
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
        
        let params: NavigateMinParams = (archiveNo, folderLinkId, nil)
        navigateMin(params: params, backNavigation: false, then: handler)
    }
}
