//
//  PublicProfilePicturesViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 17.01.2022.
//

import Foundation
import Photos

class PublicProfilePicturesViewModel: ViewModelInterface {
    var archiveData: ArchiveVOData!
    
    var publicRootFolder: FolderVOData?
    var rootFolder: FolderVOData?
    
    let uploadQueue = OperationQueue()
    
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
                    let mainFolder = model.results?.first?.data?.first?.folderVO
                    self.rootFolder = mainFolder?.childItemVOS?.first(where: { $0.displayName == Constants.API.FileType.myFilesFolder })
                    
                    handler(.success)
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
    
    func getPublicRoot(then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getPublicRoot(archiveNbr: archiveData.archiveNbr!))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    self.publicRootFolder = model.results?.first?.data?.first?.folderVO
                    handler(.success)
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
    
    func uploadFile(_ file: FileInfo, completionBlock: @escaping (() -> Void)) {
        let fileHelper = FileHelper()
        if let fileContents = file.fileContents {
            file.url = fileHelper.saveFile(fileContents, named: file.id, withExtension: "jpeg", isDownload: false) ?? URL(fileURLWithPath: "")
            file.fileContents = nil
        } else {
            do {
                file.url = try fileHelper.copyFile(withURL: file.url)
            } catch {
                
            }
        }
        
        let uploadFileOp = UploadOperation(file: file) { error in
            print(error)
        }
        let completionOp = BlockOperation { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2) {
                self?.updateBanner(thumbArchiveNbr: uploadFileOp.uploadedFile!.archiveNbr!, then: { status in
                    completionBlock()
                })
            }
        }
        completionOp.addDependency(uploadFileOp)
        
        uploadQueue.addOperations([uploadFileOp, completionOp], waitUntilFinished: false)
    }
    
    func updateBanner(thumbArchiveNbr: String, then handler: @escaping ServerResponse) {
        guard
            let publicRootFolder = publicRootFolder,
            let publicFolderId = publicRootFolder.folderID,
            let publicFolderArchiveNbr = publicRootFolder.archiveNbr,
            let publicFolderLinkId = publicRootFolder.folderLinkID
        else {
            return
        }
        
        let params: UpdateRootColumnsParams = (thumbArchiveNbr: thumbArchiveNbr, folderId: publicFolderId, folderArchiveNbr: publicFolderArchiveNbr, folderLinkId: publicFolderLinkId)
        let apiOperation = APIOperation(FilesEndpoint.updateRootColumns(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    handler(.success)
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
    
    func didChooseFromPhotoLibrary(_ assets: [PHAsset], completion: @escaping ([URL]) -> Void) {
        let dispatchGroup = DispatchGroup()
        var urls: [URL] = []
        
        assets.forEach { photo in
            dispatchGroup.enter()
            
            photo.getURL { url in
                guard let imageURL = url else {
                    dispatchGroup.leave()
                    return
                }
                
                urls.append(imageURL)
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main, execute: {
            completion(urls)
        })
    }
}
