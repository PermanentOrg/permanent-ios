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
    
    var publicRootFolder: FolderVOData? {
        didSet {
            guard let thumbURL = publicRootFolder?.thumbURL2000 else { return }
            bannerURL = URL(string: thumbURL)
        }
    }
    
    var bannerURL: URL?
    var profilePicURL: URL?
    
    let uploadQueue = OperationQueue()
    
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
    
    func updateProfilePicture(file: FileModel, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(ArchivesEndpoint.update(archiveVO: archiveData, file: file))
        
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
    
    func getPublicArchive(withArchiveNbr archiveNbr: String, _ completionBlock: @escaping ((ArchiveVOData?) -> Void)) {
        let getArchivesDataOperation = APIOperation(ArchivesEndpoint.getArchivesByArchivesNbr(archivesNbr: [archiveNbr]))
        getArchivesDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<ArchiveVO>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil)
                    return
                }
                
                let archives = model.results
                if let archiveVOData = archives.first?.data?.first?.archiveVO {
                    completionBlock(archiveVOData)
                } else {
                    completionBlock(nil)
                }
                
            case .error:
                completionBlock(nil)
                
            default:
                completionBlock(nil)
            }
        }
    }
    
    func canEditPublicProfilePhoto() -> Bool {
        return !archiveData.permissions().contains(.archiveShare)
    }
}
