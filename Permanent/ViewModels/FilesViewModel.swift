//
//  FilesViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation
import Photos.PHAsset
import CoreImage

typealias FileMetaUploadResponse = (_ recordId: Int?, _ errorMessage: String?) -> Void
typealias FileUploadResponse = (_ file: FileInfo?, _ errorMessage: String?) -> Void

typealias VoidAction = () -> Void

typealias DownloadResponse = (_ downloadURL: URL?, _ errorMessage: Error?) -> Void

enum PublicRootRequestStatus: Equatable {
    static func == (lhs: PublicRootRequestStatus, rhs: PublicRootRequestStatus) -> Bool {
        return true
    }
    case success(folder: FolderVOData?)
    case error(message: String?)
}

class FilesViewModel: NSObject, ViewModelInterface {
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
    private var downloader: DownloadManagerGCD?

    var currentArchive: ArchiveVOData? { return AuthenticationManager.shared.session?.selectedArchive }
    var archivePermissions: [Permission] {
        return currentArchive?.permissions() ?? [.read]
    }
    var archiveAccessRole: AccessRole {
        return AccessRole.roleForValue(currentArchive?.accessRole)
    }
    
    var timer: Timer?
    var timerRunCount: Int = 0
    
    var isGridView: Bool {
        get {
            AuthenticationManager.shared.session?.isGridView ?? false
        }
        
        set {
            AuthenticationManager.shared.session?.isGridView = newValue
        }
    }
    
    // MARK: - Table View Logic
    
    var currentFolderIsRoot: Bool { true }
    
    func removeCurrentFolderFromHierarchy() -> FileViewModel? {
        navigationStack.popLast()
    }
    
    func shouldPerformAction(forSection section: Int) -> Bool {
        // Perform action only for synced items
        return section == FileListType.synced.rawValue
    }
    
    func hasCancelButton(forSection section: Int) -> Bool {
        return FileListType.uploading.rawValue == section
    }
    
    func title(forSection section: Int) -> String {
        switch section {
        case FileListType.downloading.rawValue: return .downloads
        case FileListType.uploading.rawValue: return .uploads
        case FileListType.synced.rawValue: return activeSortOption.title
        default: return "" // We cannot have more than 3 sections.
        }
    }
    
    var shouldDisplayBackgroundView: Bool {
        syncedViewModels.isEmpty && uploadQueue.isEmpty
    }
    
    var numberOfSections: Int {
        3
    }
    
    var queueItemsForCurrentFolder: [FileInfo] {
        uploadQueue.filter { $0.folder.folderId == navigationStack.last?.folderId }
    }
    
    var syncedViewModels: [FileViewModel] {
        return viewModels
    }

    func numberOfRowsInSection(_ section: Int) -> Int {
        switch section {
        case FileListType.downloading.rawValue: return downloadQueue.count
        case FileListType.uploading.rawValue: return queueItemsForCurrentFolder.count
        case FileListType.synced.rawValue: return syncedViewModels.count
        default: fatalError() // We cannot have more than 2 sections.
        }
    }
    
    func fileForRowAt(indexPath: IndexPath) -> FileViewModel {
        switch indexPath.section {
        case FileListType.downloading.rawValue:
            return downloadQueue[indexPath.row]

        case FileListType.uploading.rawValue:
            let fileInfo = queueItemsForCurrentFolder[indexPath.row]
            var fileViewModel = FileViewModel(model: fileInfo, permissions: archivePermissions)
            
            // If the first item in queue, set the `uploading` status.
            let currentFileUpload = UploadManager.shared.inProgressUpload()
            fileViewModel.fileStatus = currentFileUpload?.id == fileInfo.id ? .uploading : .waiting
            
            fileViewModel.fileStatus = fileInfo.didFailUpload ? .failed : fileViewModel.fileStatus
            
            return fileViewModel
            
        case FileListType.synced.rawValue:
            return syncedViewModels[indexPath.row]
            
        default:
            fatalError()
        }
    }
    
    func clearDownloadQueue() {
        downloadQueue.removeAll()
        
        // delete from prefs
    }
    
    @discardableResult
    func refreshUploadQueue() -> Bool {
        let savedFiles: [FileInfo]? = UploadManager.shared.queuedFiles()
        
        if savedFiles?.map(\.id) != uploadQueue.map(\.id) {
            uploadQueue = savedFiles ?? []
            
            return true
        }
        
        return false
    }
    
    func removeSyncedFile(_ file: FileViewModel) {
        guard let index = viewModels.firstIndex(where: { $0 == file }) else {
            return
        }
        
        viewModels.remove(at: index)
    }
    
    func updateTimerCount() {
        timerRunCount += 1
        if timerRunCount == 1 {
            timerRunCount = 0
            invalidateTimer()
        }
    }
    
    func invalidateTimer() {
        if timer != nil {
            timer?.invalidate()
            timerRunCount = 0
        }
    }

    func relocate(file: FileViewModel, to destination: FileViewModel, then handler: @escaping ServerResponse) {
        let parameters: RelocateParams = ((file, destination), fileAction)

        let apiOperation = APIOperation(FilesEndpoint.relocate(params: parameters))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            self.selectedFile = nil
            self.fileAction = .none

            switch result {
            case .json(let httpResponse, _):
                guard
                    let response = httpResponse,
                    let data = try? JSONSerialization.data(withJSONObject: response, options: .prettyPrinted),
                    let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
                    let isSuccessful = json["isSuccessful"] as? Bool, isSuccessful else {
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
    
    func publish(file: FileViewModel, then handler: @escaping ServerResponse) {
        fileAction = .copy
        guard let archiveNbr = currentArchive?.archiveNbr else { return }
        
        getPublicRoot(archiveNbr: archiveNbr, then: { status in
            switch status {
            case .success(let folder):
                if let rootFolder = folder {
                    let publicRoot = FileViewModel(model: rootFolder)
                    self.relocate(file: file, to: publicRoot, then: handler)
                } else {
                    handler(.error(message: .errorMessage))
                }
                
            case .error(let message):
                handler(.error(message: message))
            }
        })
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
            fileType: file.type,
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        downloader = DownloadManagerGCD()
        downloader?.download(
            downloadInfo,
            onDownloadStart: onDownloadStart,
            onFileDownloaded: onFileDownloaded,
            progressHandler: progressHandler,
            completion: {
                self.downloader = nil
                self.downloadQueue.safeRemoveFirst()
            }
        )}

    func download(file: FileViewModel, onDownloadStart: @escaping VoidAction, onFileDownloaded: @escaping DownloadResponse) {
        let downloadInfo = FileDownloadInfoVM(
            fileType: file.type,
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        downloader = DownloadManagerGCD()
        downloader?.download(
            downloadInfo,
            onDownloadStart: onDownloadStart,
            onFileDownloaded: onFileDownloaded,
            progressHandler: nil,
            completion: {
                self.downloader = nil
                self.downloadQueue.safeRemoveFirst()
            }
        )}
    
    func delete(_ file: FileViewModel, then handler: @escaping ServerResponse) {
        let apiOperation = APIOperation(FilesEndpoint.delete(params: (file)))
        
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
        UploadManager.shared.cancelUpload(fileId: queueItemsForCurrentFolder[position].id)
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

                let folder = FileViewModel(model: folderVO, permissions: self.archivePermissions, accessRole: self.archiveAccessRole)
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
            
            photo.getURL { descriptor in
                guard let fileDescriptor = descriptor else {
                    dispatchGroup.leave()
                    return
                }
                
                do {
                    let localURL = try FileHelper().copyFile(withURL: fileDescriptor.url, name: fileDescriptor.name)
                    urls.append(localURL)
                } catch {
                    print(error)
                }
                
                dispatchGroup.leave()
            }
        }
        
        dispatchGroup.notify(queue: .main, execute: {
            completion(urls)
        })
    }
    
    // this method takes care of multiple upload process
    // sets up a queue and calls uploadFileMeta and uploadFileData
    func uploadFiles(_ files: [FileInfo]) {
        UploadManager.shared.upload(files: files)
    }
    
    func cancelUploadsInFolder() {
        let uploadIds = queueItemsForCurrentFolder.map({ $0.id })
        uploadIds.forEach { id in
            UploadManager.shared.cancelUpload(fileId: id)
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
    
    func onGetLeanItemsSuccess(_ model: NavigateMinResponse, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        viewModels.removeAll()
        
        childItems.forEach {
            let file = FileViewModel(model: $0, permissions: self.archivePermissions, accessRole: self.archiveAccessRole)
            self.viewModels.append(file)
        }
        
        handler(.success)
    }

    func onNavigateMinSuccess(_ model: NavigateMinResponse, _ backNavigation: Bool, _ handler: @escaping ServerResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO,
            let childItems = folderVO.childItemVOS,
            let archiveNo = folderVO.archiveNbr,
            let folderLinkId = folderVO.folderLinkID
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        let folderLinkIds: [Int] = childItems.compactMap { $0.folderLinkID }
        
        if !backNavigation {
            let file = FileViewModel(model: folderVO, permissions: archivePermissions, accessRole: archiveAccessRole)
            navigationStack.append(file)
        }
        
        let params: GetLeanItemsParams = (archiveNo, activeSortOption, folderLinkIds, folderLinkId)
        getLeanItems(params: params, then: handler)
    }
    
    func changeArchive(withArchiveId toArchiveId: Int, archiveNbr: String, completion: @escaping ((Bool) -> Void)) {
        let changeArchiveOperation = APIOperation(ArchivesEndpoint.change(archiveId: toArchiveId, archiveNbr: archiveNbr))
        changeArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<ArchiveVO>.decoder),
                    model.isSuccessful
                else {
                    completion(false)
                    return
                }
                
                if let archive = model.results[0].data?[0].archiveVO {
                    AuthenticationManager.shared.session?.selectedArchive = archive
                    
                    completion(true)
                } else {
                    completion(false)
                }
                return
                
            case .error:
                completion(false)
                return
                
            default:
                completion(false)
                return
            }
        }
    }
    
    func rename(file: FileViewModel, name: String?, then handler: @escaping ServerResponse) {
        var params: UpdateRecordParams
        var apiOperation: APIOperation
        
        if file.type.isFolder {
            params = (name, nil, nil, nil, file.folderId, file.folderLinkId, file.archiveNo)
            apiOperation = APIOperation(FilesEndpoint.renameFolder(params: params))
        } else {
            params = (name, nil, nil, nil, file.recordId, file.folderLinkId, file.archiveNo)
            apiOperation = APIOperation(FilesEndpoint.update(params: params))
        }
        
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
    
    func getPublicRoot(archiveNbr: String, then handler: @escaping (PublicRootRequestStatus) -> Void) {
        let apiOperation = APIOperation(FilesEndpoint.getPublicRoot(archiveNbr: archiveNbr))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: GetRootResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    handler(.success(folder: model.results?.first?.data?.first?.folderVO))
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
}
