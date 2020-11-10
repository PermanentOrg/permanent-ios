//
//  FilesViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation
import Photos.PHAsset

typealias NewFolderParams = (filename: String, folderLinkId: Int, csrf: String)
typealias FileMetaParams = (folderId: Int, folderLinkId: Int, filename: String, csrf: String)
typealias NavigateMinParams = (archiveNo: String, folderLinkId: Int, csrf: String)
typealias GetLeanItemsParams = (archiveNo: String, folderLinkIds: [Int], csrf: String)
typealias FileMetaUploadResponse = (_ recordId: Int?, _ errorMessage: String?) -> Void
typealias FileUploadResponse = (_ file: FileInfo?, _ errorMessage: String?) -> Void
typealias VoidAction = () -> Void
typealias UploadQueue = [FolderInfo: [FileInfo]]
typealias DeleteFileParams = (file: FileViewModel, csrf: String)

protocol FilesViewModelDelegate: ViewModelDelegateInterface {
    func getRoot(then handler: @escaping ServerResponse)
    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse)
    func getLeanItems(params: GetLeanItemsParams, then handler: @escaping ServerResponse)
    func didChooseFromPhotoLibrary(_ assets: [PHAsset], completion: @escaping ([URL]) -> Void)
    func createNewFolder(params: NewFolderParams, then handler: @escaping ServerResponse)
    func uploadFiles(_ files: [FileInfo],
                     onUploadStart: @escaping VoidAction,
                     onFileUploaded: @escaping FileUploadResponse,
                     progressHandler: ProgressHandler?,
                     then handler: @escaping ServerResponse)
    func removeFromQueue(_ position: Int)
    func delete(_ file: FileViewModel, then handler: @escaping ServerResponse)
}

class FilesViewModel: NSObject, ViewModelInterface {
    var csrf: String = ""
    var viewModels: [FileViewModel] = []
    var navigationStack: [FileViewModel] = []
    var uploadQueue: [FileInfo] = []
    var uploadInProgress: Bool = false
    var uploadFolder: FolderInfo?
    
    lazy var searchViewModels: [FileViewModel] = { [] }()
    
    var isSearchActive: Bool = false
    
    weak var delegate: FilesViewModelDelegate?
    
    // MARK: - Table View Logic
    
    func title(forSection section: Int) -> String {
        guard uploadInProgress, uploadingInCurrentFolder || waitingToUpload else {
            return .name
        }
        
        switch section {
        case FileListType.uploading.rawValue: return .uploads
        case FileListType.synced.rawValue: return .name
        default: fatalError() // We cannot have more than 2 sections.
        }
    }
    
    var waitingToUpload: Bool {
        uploadQueue.contains(where: { $0.folder.folderId == navigationStack.last?.folderId }) && !uploadingInCurrentFolder
    }
    
    var shouldRefreshList: Bool {
        uploadFolder?.folderId == navigationStack.last?.folderId
    }
    
    var uploadingInCurrentFolder: Bool {
        uploadFolder?.folderId == navigationStack.last?.folderId
    }
    
    var shouldDisplayBackgroundView: Bool {
        syncedViewModels.isEmpty && uploadQueue.isEmpty
    }
    
    var numberOfSections: Int {
        uploadInProgress && (uploadingInCurrentFolder || waitingToUpload) ? 2 : 1
    }
    
    var queueItemsForCurrentFolder: [FileInfo] {
        uploadQueue.filter { $0.folder.folderId == navigationStack.last?.folderId }
    }
    
    var syncedViewModels: [FileViewModel] {
        isSearchActive ? searchViewModels : viewModels
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        // If the upload is not in progress, we have only one section.
        guard uploadInProgress, uploadingInCurrentFolder || waitingToUpload else {
            return syncedViewModels.count
        }
    
        switch section {
        case FileListType.uploading.rawValue: return queueItemsForCurrentFolder.count
        case FileListType.synced.rawValue: return syncedViewModels.count
        default: fatalError() // We cannot have more than 2 sections.
        }
    }
    
    func fileForRowAt(indexPath: IndexPath) -> FileViewModel {
        guard uploadInProgress, uploadingInCurrentFolder || waitingToUpload else {
            return syncedViewModels[indexPath.row]
        }
        
        switch indexPath.section {
        case FileListType.uploading.rawValue:
            let fileInfo = queueItemsForCurrentFolder[indexPath.row]
            var fileViewModel = FileViewModel(model: fileInfo)
            
            // If the first item in queue, set the `uploading` status.
            fileViewModel.fileStatus = indexPath.row == 0 && uploadingInCurrentFolder ?
                .uploading :
                .waiting
            return fileViewModel
            
        case FileListType.synced.rawValue:
            return syncedViewModels[indexPath.row]
            
        default:
            fatalError()
        }
    }
    
    private func saveUploadProgressLocally(files: [FileInfo]) {
        try? PreferencesManager.shared.setCustomObject(files, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
    }
    
    func clearUploadQueue() {
        uploadQueue.removeAll()
        
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
    }
    
    func removeSyncedFile(_ file: FileViewModel) {
        guard let index = viewModels.firstIndex(where: { $0 == file }) else {
            return
        }
        
        viewModels.remove(at: index)
    }
    
    func searchFiles(byQuery query: String) {
        let searchedItems = viewModels.filter {
            $0.name.lowercased().starts(with: query.lowercased())
        }
        searchViewModels.removeAll()
        searchViewModels.append(contentsOf: searchedItems)
    }
}

extension FilesViewModel: FilesViewModelDelegate {
    func delete(_ file: FileViewModel, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.delete(params: (file, csrf)))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful
                    
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                handler(.success)
                    
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))
                    
            default:
                break
            }
        }
    }
    
    func removeFromQueue(_ position: Int) {
        guard queueItemsForCurrentFolder.count >= position else {
            return
        }
        
        // Find the selected file from current folder
        let fileInfo = queueItemsForCurrentFolder[position]
        
        // Find it in the entire queue.
        
        guard let fileQueueIndex = uploadQueue.firstIndex(of: fileInfo) else {
            return
        }
        
        uploadQueue.remove(at: fileQueueIndex)
    }
    
    func createNewFolder(params: NewFolderParams, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.newFolder(params: params))
            
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: NavigateMinResponse = JSONHelper.convertToModel(from: response),
                    let folderVO = model.results?.first?.data?.first?.folderVO
                else {
                    handler(.error(message: .errorMessage))
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
    
    // this method takes care of multiple upload process
    // sets up a queue and calls uploadFileMeta and uploadFileData
    func uploadFiles(_ files: [FileInfo],
                     onUploadStart: @escaping VoidAction,
                     onFileUploaded: @escaping FileUploadResponse,
                     progressHandler: ProgressHandler?,
                     then handler: @escaping ServerResponse)
    {
        guard let file = files.first else {
            return handler(.error(message: .errorMessage))
        }
        
        uploadQueue.append(contentsOf: files)
        saveUploadProgressLocally(files: uploadQueue)
        
        onUploadStart()
        
        // User is already uploading, so we just return.
        if uploadInProgress {
            return
        }
        
        uploadInProgress = true
        uploadFolder = file.folder
        
        let params: FileMetaParams = (
            file.folder.folderId,
            file.folder.folderLinkId,
            file.name,
            csrf
        )
                    
        handleRecursiveFileUpload(
            file,
            withParams: params,
            onFileUploaded: onFileUploaded,
            progressHandler: progressHandler,
            then: handler
        )
    }
    
    func handleRecursiveFileUpload(_ file: FileInfo,
                                   withParams params: FileMetaParams,
                                   onFileUploaded: @escaping FileUploadResponse,
                                   progressHandler: ProgressHandler?,
                                   then handler: @escaping ServerResponse)
    {
        upload(file, withParams: params, progressHandler: progressHandler) { status in
            switch status {
            case .success:
                onFileUploaded(file, nil)
                
                self.moveToSyncedFilesIfNeeded(file)
                
                // Check if the queue is not empty, and upload the next item otherwise.
                if self.uploadQueue.isEmpty {
                    self.uploadInProgress = false
                    return handler(.success)
                } else {
                    // Remove the first item from queue and save progress.
                    self.uploadQueue.removeFirst()
                    
                    guard let nextFile = self.uploadQueue.first else {
                        self.uploadInProgress = false
                        return handler(.success)
                    }
                    
                    self.saveUploadProgressLocally(files: self.uploadQueue)
                    self.uploadFolder = nextFile.folder
                    
                    let params: FileMetaParams = (
                        nextFile.folder.folderId,
                        nextFile.folder.folderLinkId,
                        nextFile.name,
                        self.csrf
                    )
                    
                    self.handleRecursiveFileUpload(
                        nextFile,
                        withParams: params,
                        onFileUploaded: onFileUploaded,
                        progressHandler: progressHandler,
                        then: handler
                    )
                }

            case .error(let message):
                onFileUploaded(nil, message)
                self.uploadInProgress = false
                handler(.error(message: message))
            }
        }
    }
    
    private func upload(_ file: FileInfo, withParams params: FileMetaParams, progressHandler: ProgressHandler?, then handler: @escaping ServerResponse) {
        uploadFileMeta(file, withParams: params) { id, errorMessage in
            
            guard let recordId = id else {
                return handler(.error(message: errorMessage))
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.uploadFileData(
                    file,
                    recordId: recordId,
                    progressHandler: progressHandler,
                    then: handler
                )
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
                    handler(nil, .errorMessage)
                    return
                }
                
                if model.isSuccessful == true,
                    let recordId = model.results?.first?.data?.first?.recordVO?.recordID
                {
                    handler(recordId, nil)
                    
                } else {
                    handler(nil, .errorMessage)
                }
                
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                break
            }
        }
    }
    
    // Uploads the file to the server.
    
    private func uploadFileData(_ file: FileInfo, recordId: Int, progressHandler: ProgressHandler?, then handler: @escaping ServerResponse) {
        let boundary = UploadManager.instance.createBoundary()
        let apiOperation = APIOperation(FilesEndpoint.upload(
            file: file,
            usingBoundary: boundary,
            recordId: recordId,
            progressHandler: progressHandler
        ))
        
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
        if uploadingInCurrentFolder {
            var newFile = FileViewModel(model: file)
            newFile.fileStatus = .synced
            viewModels.prepend(newFile)
        }
    }
    
    func getLeanItems(params: GetLeanItemsParams, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getLeanItems(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    self.onGetLeanItemsSuccess(model, handler)
                    
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
    
    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.navigateMin(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: NavigateMinResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
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
            handler(.error(message: .errorMessage))
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
            handler(.error(message: .errorMessage))
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
            handler(.error(message: .errorMessage))
            return
        }
        
        self.csrf = csrf
        
        let params: NavigateMinParams = (archiveNo, folderLinkId, csrf)
        navigateMin(params: params, backNavigation: false, then: handler)
    }
}
