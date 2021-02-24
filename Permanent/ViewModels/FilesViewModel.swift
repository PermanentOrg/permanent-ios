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
typealias GetPresignedUrlParams = (folderId: Int, folderLinkId: Int, fileMimeType: String?, filename: String, fileSize: Int, derivedCreatedDT: String?, csrf: String)
typealias RegisterRecordParams = (folderId: Int, folderLinkId: Int, filename: String, derivedCreatedDT: String?, csrf: String, s3Url: String, destinationUrl: String)
typealias NavigateMinParams = (archiveNo: String, folderLinkId: Int, csrf: String)
typealias GetLeanItemsParams = (archiveNo: String, sortOption: SortOption, folderLinkIds: [Int], csrf: String, folderLinkId: Int)
typealias FileMetaUploadResponse = (_ recordId: Int?, _ errorMessage: String?) -> Void
typealias FileUploadResponse = (_ file: FileInfo?, _ errorMessage: String?) -> Void

typealias VoidAction = () -> Void
typealias ItemInfoParams = (file: FileViewModel, csrf: String)
typealias GetRecordParams = (folderLinkId: Int, parentFolderLinkId: Int, csrf: String)

typealias ItemPair = (source: FileViewModel, destination: FileViewModel)
typealias RelocateParams = (items: ItemPair, action: FileAction, csrf: String)
typealias DownloadResponse = (_ downloadURL: URL?, _ errorMessage: Error?) -> Void
typealias GetRecordResponse = (_ file: RecordVO?, _ errorMessage: Error?) -> Void

class FilesViewModel: NSObject, ViewModelInterface {
    var csrf: String = ""
    var viewModels: [FileViewModel] = []
    var navigationStack: [FileViewModel] = []
    var uploadQueue: [FileInfo] = []
    var downloadQueue: [FileViewModel] = []
    var activeSortOption: SortOption = .nameAscending
    var uploadInProgress: Bool = false
    var downloadInProgress: Bool {
        downloader != nil
    }
    var uploadFolder: FolderInfo?
    var fileAction: FileAction = .none
    
    var selectedFile: FileViewModel?
    var currentFolder: FileViewModel? { navigationStack.last }
    
    lazy var searchViewModels: [FileViewModel] = { [] }()
    private var downloader: Downloader?
    
    var isSearchActive: Bool = false
    
    // MARK: - Table View Logic
    
    var currentFolderIsRoot: Bool { true }
    
    func removeCurrentFolderFromHierarchy() -> FileViewModel? {
        navigationStack.popLast()
    }
    
    func shouldPerformAction(forSection section: Int) -> Bool {
        guard uploadOrDownloadInProgress else { return true }
        
        // Perform action only for synced items
        return section == FileListType.synced.rawValue
    }
    
    func title(forSection section: Int) -> String {
        guard uploadOrDownloadInProgress else { return activeSortOption.title }
        
        switch section {
        case FileListType.downloading.rawValue: return .downloads
        case FileListType.uploading.rawValue: return .uploads
        case FileListType.synced.rawValue: return activeSortOption.title
        default: fatalError() // We cannot have more than 3 sections.
        }
    }

    var uploadOrDownloadInProgress: Bool {
        return
            uploadInProgress && uploadingInCurrentFolder || waitingToUpload || // UPLOAD
            downloadInProgress // DOWNLOAD
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
        uploadOrDownloadInProgress ? 3 : 1
    }
    
    var queueItemsForCurrentFolder: [FileInfo] {
        uploadQueue.filter { $0.folder.folderId == navigationStack.last?.folderId }
    }
    
    var syncedViewModels: [FileViewModel] {
        isSearchActive ? searchViewModels : viewModels
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        // If the upload or download is not in progress, we have only one section.
        guard uploadOrDownloadInProgress else { return syncedViewModels.count }

        switch section {
        case FileListType.downloading.rawValue: return downloadQueue.count
        case FileListType.uploading.rawValue: return queueItemsForCurrentFolder.count
        case FileListType.synced.rawValue: return syncedViewModels.count
        default: fatalError() // We cannot have more than 2 sections.
        }
    }
    
    func fileForRowAt(indexPath: IndexPath) -> FileViewModel {
        guard uploadOrDownloadInProgress else { return syncedViewModels[indexPath.row] }

        switch indexPath.section {
        case FileListType.downloading.rawValue:
            return downloadQueue[indexPath.row]

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
    
    func clearDownloadQueue() {
        downloadQueue.removeAll()
        
        // delete from prefs
    }
    
    func removeSyncedFile(_ file: FileViewModel) {
        guard let index = viewModels.firstIndex(where: { $0 == file }) else {
            return
        }
        
        viewModels.remove(at: index)
    }
    
    func searchFiles(byQuery query: String) {
        let searchedItems = viewModels.filter {
            $0.name.lowercased().contains(query.lowercased())
        }
        searchViewModels.removeAll()
        searchViewModels.append(contentsOf: searchedItems)
    }
}

extension FilesViewModel {
    func relocate(file: FileViewModel, to destination: FileViewModel, then handler: @escaping ServerResponse) {
        let parameters: RelocateParams = ((file, destination), fileAction, csrf)

        let apiOperation = APIOperation(FilesEndpoint.relocate(params: parameters))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let httpResponse, _):
                guard
                    let response = httpResponse,
                    let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted),
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let isSuccessful = json["isSuccessful"] as? Bool, isSuccessful else {
                    
                    return handler(.error(message: .errorMessage))
                }
                
                handler(.success)
                
            case .error(let error, _):
                handler(.error(message: error?.localizedDescription))

            default:
                break
            }
        }
    }
    
    func cancelDownload() {
        downloadQueue.safeRemoveFirst()
        
        downloader?.cancelDownload()
        downloader = nil
    }
    
    func download(_ file: FileViewModel, onDownloadStart: @escaping VoidAction, onFileDownloaded: @escaping DownloadResponse, progressHandler: ProgressHandler?) {
        var downloadFile = file
        downloadFile.fileStatus = .downloading
        downloadQueue.append(downloadFile)
        
        let downloadInfo = FileDownloadInfoVM(
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        downloader = DownloadManagerGCD(csrf: csrf)
        downloader?.download(downloadInfo,
                            onDownloadStart: onDownloadStart,
                            onFileDownloaded: onFileDownloaded,
                            progressHandler: progressHandler,
                            completion: {
                                self.downloader = nil
                                self.downloadQueue.safeRemoveFirst()
                            })

    }
    
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
        saveUploadProgressLocally(files: uploadQueue)
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
        getPresignedUrl(file: file, withParams: GetPresignedUrlParams(params.folderId, params.folderLinkId, file.mimeType, params.filename, file.fileContents?.count ?? 0, nil, params.csrf), progressHandler: progressHandler, then: handler)
    }

    private func getPresignedUrl(file: FileInfo, withParams params: GetPresignedUrlParams, progressHandler: ProgressHandler?, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getPresignedUrl(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            switch result {
            case .json(let response, _):
                guard let model: GetPresignedUrlResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }

                if model.isSuccessful == true, let s3Url = model.results?.first?.data?.first?.simpleVO?.value?.presignedPost?.url,
                   let destinationUrl = model.results?.first?.data?.first?.simpleVO?.value?.destinationUrl, let fields = model.results?.first?.data?.first?.simpleVO?.value?.presignedPost?.fields {
                    DispatchQueue.main.async {
                        self?.uploadFileDataToS3(file, params: params, s3Url: s3Url, destinationUrl: destinationUrl, fields: fields, progressHandler: progressHandler, then: handler)
                    }
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

    private func registerRecord(file: FileInfo, withParams params: RegisterRecordParams, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.registerRecord(params: params))
        apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
            switch result {
            case .json(let response, _):
                guard let model: UploadFileMetaResponse = JSONHelper.convertToModel(from: response) else {
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

    // Uploads the file to the server.
    private func uploadFileDataToS3(_ file: FileInfo, params: GetPresignedUrlParams, s3Url: String, destinationUrl: String ,fields: [String:String]?, progressHandler: ProgressHandler?, then handler: @escaping ServerResponse) {
        let boundary = UploadManager.instance.createBoundary()
        let apiOperation = APIOperation(FilesEndpoint.upload(s3Url: s3Url, file: file, fields: fields, progressHandler: progressHandler, usingBoundry: boundary))
        apiOperation.execute(in: APIRequestDispatcher()) {[weak self] result in
            switch result {
            case .json:
                self?.registerRecord(file: file, withParams: RegisterRecordParams(folderId: params.folderId, folderLinkId: params.folderLinkId, filename: params.filename, derivedCreatedDT: nil, csrf: params.csrf, s3Url: s3Url, destinationUrl: destinationUrl), then: handler)
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
            let folderLinkId = folderVO.folderLinkID,
            let csrf = model.csrf
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        let folderLinkIds: [Int] = childItems.compactMap { $0.folderLinkID }
        
        if !backNavigation {
            let file = FileViewModel(model: folderVO)
            navigationStack.append(file)
        }
        
        let params: GetLeanItemsParams = (archiveNo, activeSortOption, folderLinkIds, csrf, folderLinkId)
        getLeanItems(params: params, then: handler)
    }
}
