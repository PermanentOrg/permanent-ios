//
//  FilesViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation
import Photos.PHAsset

typealias FolderInfo = (folderId: Int, folderLinkId: Int)
typealias NewFolderParams = (filename: String, folderLinkId: Int, csrf: String)
typealias FileMetaParams = (folderId: Int, folderLinkId: Int, filename: String, csrf: String)
typealias NavigateMinParams = (archiveNo: String, folderLinkId: Int, csrf: String)
typealias GetLeanItemsParams = (archiveNo: String, folderLinkIds: [Int], csrf: String)
typealias FileMetaUploadResponse = (_ recordId: Int?, _ errorMessage: String?) -> Void
typealias FileUploadResponse = (_ file: FileInfo?, _ errorMessage: String?) -> Void
typealias VoidAction = () -> Void

protocol FilesViewModelDelegate: ViewModelDelegateInterface {
    func getRoot(then handler: @escaping ServerResponse)
    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse)
    func getLeanItems(params: GetLeanItemsParams, then handler: @escaping ServerResponse)
    func didChooseFromPhotoLibrary(_ assets: [PHAsset], completion: @escaping ([URL]) -> Void)
    func createNewFolder(params: NewFolderParams, then handler: @escaping ServerResponse)
    func uploadFiles(_ fileURLS: [URL],
                     toFolder folder: FolderInfo,
                     onUploadStart: @escaping VoidAction,
                     onFileUploaded: @escaping FileUploadResponse,
                     then handler: @escaping ServerResponse)
}

class FilesViewModel: NSObject, ViewModelInterface {
    var csrf: String = ""
    var viewModels: [FileViewModel] = []
    var navigationStack: [FileViewModel] = []
    var uploadQueue: [FileInfo] = []
    var uploadInProgress: Bool = false
    var uploadFolder: FolderInfo?
    
    weak var delegate: FilesViewModelDelegate?
    
    // MARK: - Table View Logic
    
    func title(forSection section: Int) -> String {
        guard uploadInProgress, uploadingInCurrentFolder else {
            return Translations.name
        }
        
        switch section {
        case FileListType.uploading.rawValue: return Translations.uploads
        case FileListType.synced.rawValue: return Translations.name
        default: fatalError() // We cannot have more than 2 sections.
        }
    }
    
    var uploadingInCurrentFolder: Bool {
        uploadFolder?.folderId == navigationStack.last?.folderId
    }
    
    var shouldDisplayBackgroundView: Bool {
        viewModels.isEmpty && uploadQueue.isEmpty
    }
    
    var numberOfSections: Int {
        uploadInProgress && uploadingInCurrentFolder ? 2 : 1
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        // If the upload is not in progress, we have only one section.
        guard uploadInProgress, uploadingInCurrentFolder else {
            return viewModels.count
        }
    
        switch section {
        case FileListType.uploading.rawValue: return uploadQueue.count
        case FileListType.synced.rawValue: return viewModels.count
        default: fatalError() // We cannot have more than 2 sections.
        }
    }
    
    func cellForRowAt(indexPath: IndexPath) -> FileViewModel {
        guard uploadInProgress, uploadingInCurrentFolder else {
            return viewModels[indexPath.row]
        }
        
        switch indexPath.section {
        case FileListType.uploading.rawValue:
            let fileInfo = uploadQueue[indexPath.row]
            var fileViewModel = FileViewModel(model: fileInfo)
            
            // If the first item in queue, set the `uploading` status.
            fileViewModel.fileStatus = indexPath.row == 0 ? .uploading : .waiting
            return fileViewModel
            
        case FileListType.synced.rawValue:
            return viewModels[indexPath.row]
            
        default:
            fatalError()
        }
    }
    
    private func getFiles(from urls: [URL]) -> [FileInfo] {
        return urls.compactMap { (url) -> FileInfo? in
            // TODO: Test
            guard let mimeType = UploadManager.instance.getMimeType(forExtension: url.pathExtension) else {
                return nil
            }
            
            return FileInfo(withFileURL: url,
                            filename: url.lastPathComponent,
                            name: url.lastPathComponent,
                            mimeType: mimeType)
        }
    }
}

extension FilesViewModel: FilesViewModelDelegate {
    func createNewFolder(params: NewFolderParams, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.newFolder(params: params))
            
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: NavigateMinResponse = JSONHelper.convertToModel(from: response),
                    let folderVO = model.results?.first?.data?.first?.folderVO
                else {
                    handler(.error(message: Translations.errorMessage))
                    return
                }
                    
                let folder = FileViewModel(model: folderVO)
                self.viewModels.insert(folder, at: 0)
                handler(.success)
                    
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
    
    private func saveUploadProgressLocally(files: [FileInfo]) {
        let stringURLS: [String] = files.map { $0.url.absoluteString }
        PreferencesManager.shared.set(stringURLS, forKey: Constants.Keys.StorageKeys.uploadFilesURLS)
    }
    
    // this method takes care of multiple upload process
    // sets up a queue and calls uploadFileMeta and uploadFileData
    func uploadFiles(_ fileURLS: [URL],
                     toFolder folder: FolderInfo,
                     onUploadStart: @escaping VoidAction,
                     onFileUploaded: @escaping FileUploadResponse,
                     then handler: @escaping ServerResponse)
    {
        // Convert from [URL] to [FileInfo]
        let files = getFiles(from: fileURLS)
        
        guard let file = files.first else {
            return handler(.error(message: Translations.errorMessage))
        }
        
        uploadQueue.append(contentsOf: files)
        uploadFolder = folder
        
        PreferencesManager.shared.set(folder.folderId, forKey: Constants.Keys.StorageKeys.uploadFolderId)
        PreferencesManager.shared.set(folder.folderLinkId, forKey: Constants.Keys.StorageKeys.uploadFolderLinkId)
        saveUploadProgressLocally(files: files)
        
        onUploadStart()
        
        // User is already uploading, so we just return.
        if uploadInProgress {
            return
        }
        
        uploadInProgress = true
        
        let params: FileMetaParams = (folder.folderId, folder.folderLinkId, file.filename ?? "-", csrf)
        handleRecursiveFileUpload(file, withParams: params, onFileUploaded: onFileUploaded, then: handler)
    }
    
    func handleRecursiveFileUpload(_ file: FileInfo,
                                   withParams params: FileMetaParams,
                                   onFileUploaded: @escaping FileUploadResponse,
                                   then handler: @escaping ServerResponse)
    {
        upload(file, withParams: params) { status in
            switch status {
            case .success:
                onFileUploaded(file, nil)
                
                self.moveToSyncedFilesIfNeeded(file)
                
                // Remove the first item from queue and save progress.
                self.uploadQueue.removeFirst()
                self.saveUploadProgressLocally(files: self.uploadQueue)
                
                // Check if the queue is not empty, and upload the next item otherwise.
                if let nextFile = self.uploadQueue.first {
                    let params: FileMetaParams = (params.folderId, params.folderLinkId, nextFile.filename ?? "-", self.csrf)
                    self.handleRecursiveFileUpload(nextFile, withParams: params, onFileUploaded: onFileUploaded, then: handler)
                } else {
                    self.uploadInProgress = false
                    return handler(.success)
                }
                
            case .error(let message):
                onFileUploaded(nil, message)
                self.uploadInProgress = false
                handler(.error(message: message))
            }
        }
    }
    
    private func upload(_ file: FileInfo, withParams params: FileMetaParams, then handler: @escaping ServerResponse) {
        uploadFileMeta(file, withParams: params) { id, errorMessage in
            
            guard let recordId = id else {
                return handler(.error(message: errorMessage))
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.uploadFileData(file, recordId: recordId, then: handler)
            }
        }
    }
    
    // Uploads the file meta to the server.
    // Must be executed before the actual upload of the file.
    
    private func uploadFileMeta(_ file: FileInfo, withParams params: FileMetaParams, then handler: @escaping FileMetaUploadResponse) {
        let apiOperation = APIOperation(FilesEndpoint.uploadFileMeta(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: UploadFileMetaResponse = JSONHelper.convertToModel(from: response) else {
                    handler(nil, Translations.errorMessage)
                    return
                }
                
                if model.isSuccessful == true,
                    let recordId = model.results?.first?.data?.first?.recordVO?.recordID
                {
                    handler(recordId, nil)
                    
                } else {
                    handler(nil, Translations.errorMessage)
                }
                
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                break
            }
        }
    }
    
    // Uploads the file to the server.
    
    private func uploadFileData(_ file: FileInfo, recordId: Int, then handler: @escaping ServerResponse) {
        let boundary = UploadManager.instance.createBoundary()
        let apiOperation = APIOperation(FilesEndpoint.upload(file: file, usingBoundary: boundary, recordId: recordId))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json:
                handler(.success)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                
            default:
                break
            }
        }
    }
    
    private func moveToSyncedFilesIfNeeded(_ file: FileInfo) {
        if self.uploadingInCurrentFolder {
            var newFile = FileViewModel(model: file)
            newFile.fileStatus = .synced
            self.viewModels.prepend(newFile)
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
        
        viewModels.removeAll()
        
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
            navigationStack.append(file)
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
