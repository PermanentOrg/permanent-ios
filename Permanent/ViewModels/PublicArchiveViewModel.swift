//
//  PublicArchiveViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 01.12.2021.
//

import Foundation

class PublicArchiveViewModel: FilesViewModel {
    
    private var _currentArchive: ArchiveVOData?
    override var currentArchive: ArchiveVOData? {
        get {
            return _currentArchive
        }
        
        set {
            _currentArchive = newValue
        }
    }
    
    override var currentFolderIsRoot: Bool { navigationStack.count == 1 }
    
    override var numberOfSections: Int {
        1
    }
    
    override func numberOfRowsInSection(_ section: Int) -> Int {
        return syncedViewModels.count
    }
    
    func heightForSection(_ section: Int) -> Double {
        0
    }
    
    override func fileForRowAt(indexPath: IndexPath) -> FileViewModel {
        switch indexPath.section {
        case 0:
            return syncedViewModels[indexPath.row]
            
        default:
            fatalError()
        }
    }
    
    func getRoot(then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getPublicRoot(archiveNbr: currentArchive!.archiveNbr!))
        
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
            let archiveNo = folderVO.archiveNbr,
            let folderLinkId = folderVO.folderLinkID
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        let params: NavigateMinParams = (archiveNo, folderLinkId, nil)
        navigateMin(params: params, backNavigation: false, then: handler)
    }
    
    func publicURL(forFile file: FileViewModel) -> URL? {
        guard let currentArchive = currentArchive,
              let currentFolder = currentFolder else { return nil }
        
        let baseURLString = APIEnvironment.defaultEnv.publicURL
        let url: URL
        if file.type.isFolder {
            url = URL(string: "\(baseURLString)/archive/\(currentArchive.archiveNbr!)/\(file.archiveNo)/\(file.folderLinkId)")!
        } else {
            url = URL(string: "\(baseURLString)/archive/\(currentArchive.archiveNbr!)/\(currentFolder.archiveNo)/\(currentFolder.folderLinkId)/record/\(file.archiveNo)")!
        }
        
        return url
    }
}
