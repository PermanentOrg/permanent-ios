//
//  FilesViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation
import UIKit.UITableView

typealias FileMetaParams = (folderId: Int, folderLinkId: Int, filename: String, csrf: String)
typealias NavigateMinParams = (archiveNo: String, folderLinkId: Int, csrf: String)
typealias GetLeanItemsParams = (archiveNo: String, folderLinkIds: [Int], csrf: String)

class FilesViewModel: NSObject, ViewModelInterface {
    var viewModels: [FileViewModel] = []
    var csrf: String = ""
    var navigationStack: [FileViewModel] = []
    var uploadQueue: [FileInfo] = []
    
    weak var delegate: FilesViewModelDelegate?
}

protocol FilesViewModelDelegate: ViewModelDelegateInterface {
    func getRoot(then handler: @escaping ServerResponse)
    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse)
    func getLeanItems(params: GetLeanItemsParams, then handler: @escaping ServerResponse)
    func uploadFiles(_ files: [URL], then handler: @escaping ServerResponse)
}

extension FilesViewModel: FilesViewModelDelegate {
    
    // this method takes care of multiple upload process
    // sets up a queue and calls uploadFileMeta and uploadFile
    func uploadFiles(_ fileURLS: [URL], then handler: @escaping ServerResponse) {
        let files = fileURLS.map {
            FileInfo(withFileURL: $0,
                     filename: $0.lastPathComponent,
                     name: $0.lastPathComponent,
                     mimeType: "application/pdf") // TODO:
        }
        
        
        uploadQueue.removeAll() // ??
        uploadQueue.append(contentsOf: files)
        
        // TODO: Handle multiple files
        guard
            let file = files.first,
            let currentFolder = navigationStack.last else { return }
        
        let params: FileMetaParams = (currentFolder.folderId, currentFolder.folderLinkId, file.filename ?? "-", csrf)
        uploadFileMeta(file, withParams: params, then: handler)
    }
    
    func uploadSingleFile(_ file: FileInfo, withParams: FileMetaParams, then handler: @escaping ServerResponse) {
    }
    
    // Uploads the file meta to the server.
    // Must be executed before the actual upload of the file.
    
    private func uploadFileMeta(_ file: FileInfo, withParams params: FileMetaParams, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.uploadFileMeta(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: UploadFileMetaResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: Translations.errorMessage))
                    return
                }
                
                if model.isSuccessful == true,
                   let recordId = model.results?.first?.data?.first?.recordVO?.recordID {
                   
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.uploadFile(file, recordId: recordId, then: handler)
                    }
                    
                } else {
                    handler(.error(message: Translations.errorMessage))
                }
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    
    // Uploads the file to the server.
    
    func uploadFile(_ file: FileInfo, recordId: Int, then handler: @escaping ServerResponse) {
        let boundary = UploadManager.instance.createBoundary()
        let apiOperation = APIOperation(FilesEndpoint.upload(file: file, usingBoundary: boundary, recordId: recordId))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(_, _):
                handler(.success)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    func getLeanItems(params: GetLeanItemsParams, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getLeanItems(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: Translations.errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetLeanItemsSuccess(model, handler)
                    
                } else {
                    handler(.error(message: Translations.errorMessage))
                }
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    func getRoot(then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getRoot)
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: Translations.errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetRootSuccess(model, handler)
                    
                } else {
                    handler(.error(message: Translations.errorMessage))
                }
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.navigateMin(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: Translations.errorMessage))
                    return
                }
                
                self.onNavigateMinSuccess(model, backNavigation, handler)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    private func onGetLeanItemsSuccess(_ model: NavigateMinResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS
        else {
            handler(.error(message: Translations.errorMessage))
            return
        }
        
        self.viewModels.removeAll()
        
        childItems.forEach {
            let file = FileViewModel(model: $0)
            self.viewModels.append(file)
        }
        
        handler(.success)
    }
    
    private func onNavigateMinSuccess(_ model: NavigateMinResponse, _ backNavigation: Bool, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS,
            let archiveNo = folderVO.archiveNbr,
            let csrf = model.csrf
        else {
            handler(.error(message: Translations.errorMessage))
            return
        }
        
        let folderLinkIds: [Int] = childItems
            .compactMap { $0.folderLinkID }
        
        if !backNavigation {
            let file = FileViewModel(model: folderVO)
            self.navigationStack.append(file)
        }
        
        let params: GetLeanItemsParams = (archiveNo, folderLinkIds, csrf)
        getLeanItems(params: params, then: handler)
    }
    
    private func onGetRootSuccess(_ model: GetRootResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS,
            let myFilesFolder = childItems.first(where: { $0.displayName == Constants.API.FileType.MY_FILES_FOLDER }),
            let archiveNo = myFilesFolder.archiveNbr,
            let folderLinkId = myFilesFolder.folderLinkID,
            let csrf = model.csrf
        else {
            handler(.error(message: Translations.errorMessage))
            return
        }
        
        self.csrf = csrf
        
        let params: NavigateMinParams = (archiveNo, folderLinkId, csrf)
        navigateMin(params: params, backNavigation: false, then: handler)
    }
}
