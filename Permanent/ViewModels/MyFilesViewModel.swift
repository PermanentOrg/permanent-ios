//
//  MyFilesViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 19.02.2021.
//

import Foundation

class MyFilesViewModel: FilesViewModel {
    
    override var currentFolderIsRoot: Bool { navigationStack.count == 1 }
    
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
            let myFilesFolder = folderVO.childItemVOS?.first(where: { $0.displayName == Constants.API.FileType.MY_FILES_FOLDER }),
            let archiveNo = myFilesFolder.archiveNbr,
            let folderLinkId = myFilesFolder.folderLinkID,
            let csrf = model.csrf
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        self.csrf = csrf
        
        let archiveId = myFilesFolder.archiveID
        PreferencesManager.shared.set(archiveId, forKey: Constants.Keys.StorageKeys.archiveIdStorageKey)
        
        // Workaround until we implement multiple archives
        // Modify `archiveNbr` received from server and add '0000'
        
        if let rootArchiveNbr = myFilesFolder.archiveNbr {
            let archiveNbrPrefix = String(rootArchiveNbr.prefix(5))
            let archiveNbr = archiveNbrPrefix + "0000"
            
            PreferencesManager.shared.set(archiveNbr, forKey: Constants.Keys.StorageKeys.archiveNbrStorageKey)
        }
        
        
        let params: NavigateMinParams = (archiveNo, folderLinkId, csrf)
        navigateMin(params: params, backNavigation: false, then: handler)
    }
    
}
