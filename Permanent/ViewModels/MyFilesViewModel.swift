//
//  MyFilesViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 19.02.2021.
//

import Foundation

protocol MyFilesViewModelPickerDelegate: AnyObject {
    func myFilesVMDidPickFile(viewModel: MyFilesViewModel, file: FileViewModel)
}

class MyFilesViewModel: FilesViewModel {
    var isPickingImage: Bool = false
    weak var pickerDelegate: MyFilesViewModelPickerDelegate?
    
    override var currentFolderIsRoot: Bool { navigationStack.count == 1 }
    
    override var selectedFile: FileViewModel? {
        get {
            return try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.selectedFileKey)
        }
        
        set {
            try? PreferencesManager.shared.setCodableObject(newValue, forKey: Constants.Keys.StorageKeys.selectedFileKey)
        }
    }
    
    override var fileAction: FileAction {
        get {
            return (try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.selectedFileActionKey)) ?? .none
        }
        
        set {
            try? PreferencesManager.shared.setCodableObject(newValue, forKey: Constants.Keys.StorageKeys.selectedFileActionKey)
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
        
        let prefsManager = PreferencesManager(withGroupName: ExtensionUploadManager.appSuiteGroup)
        if let myFilesArchive = model.results?.first?.data?.first?.folderVO?.childItemVOS?.filter({ $0.displayName == "My Files"}),
            let folderID = myFilesArchive.first?.folderID,
            let folderLinkId = myFilesArchive.first?.folderLinkID,
            let archiveThumbnail = model.results?.first?.data?.first?.folderVO?.thumbURL500 {
            prefsManager.set(folderID, forKey: Constants.Keys.StorageKeys.archiveFolderId)
            prefsManager.set(folderLinkId, forKey: Constants.Keys.StorageKeys.archiveFolderLinkId)
        }
        
        let params: NavigateMinParams = (archiveNo, folderLinkId, nil)
        navigateMin(params: params, backNavigation: false, then: handler)
    }
}
