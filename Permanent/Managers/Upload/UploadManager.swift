//
//  UploadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation

class UploadManager {
    static let didRefreshQueueNotification = Notification.Name("UploadManager.didRefreshQueueNotification")
    static let didUploadFileNotification = Notification.Name("UploadManager.didUploadFileNotification")
    static let quotaExceededNotification = Notification.Name("UploadManager.quotaExceededNotification")
    
    static let shared: UploadManager = UploadManager()
    
    let uploadQueue: OperationQueue = OperationQueue()
    
    var timer: Timer?
    
    init() {
        uploadQueue.maxConcurrentOperationCount = 3
        
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(refreshQueue), userInfo: nil, repeats: true)
    }
    
    func upload(files: [FileInfo]) {
        var filesSize = 0
        files.forEach { file in
            if let resources = try? file.url.resourceValues(forKeys: [.fileSizeKey]) {
                filesSize += resources.fileSize!
            } else if let fileContents = file.fileContents {
                filesSize += fileContents.count
            }
        }
        
        // Call AccountAPI and figure if there's enough space left
        guard let accountId: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey) else {
            return
        }
        
        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: String(accountId)))
        getUserDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    return
                }

                if model.results[0].data?[0].accountVO?.spaceLeft ?? 0 > filesSize {
                    DispatchQueue.main.async {
                        for file in files {
                            self.upload(file: file)
                        }
                        
                        self.refreshQueue()
                    }
                } else {
                    NotificationCenter.default.post(name: Self.quotaExceededNotification, object: self, userInfo: nil)
                }
               
                return
                
            case .error:
                return
                
            default:
                break
            }
        }
    }
    
    func upload(file: FileInfo, shouldRefreshQueue: Bool = false) {
        // Save the file data locally, otherwise the fileURL will be invalidated next session
        let fileHelper = FileHelper()
        if let fileContents = file.fileContents {
            file.url = fileHelper.saveFile(fileContents, named: file.id, withExtension: "jpeg", isDownload: false) ?? URL(fileURLWithPath: "")
            file.fileContents = nil
        } else {
            do {
                file.url = try fileHelper.copyFile(withURL: file.url)
            } catch {
                print(error)
            }
        }
        
        // Save file metadata
        let savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        if var savedFiles = savedFiles {
            if savedFiles.map({ $0.id }).contains(file.id) == false {
                savedFiles.append(file)
                try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
            }
        } else {
            try? PreferencesManager.shared.setCustomObject([file], forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        }
        
        // Start uploading
        if shouldRefreshQueue {
            refreshQueue()
        }
    }
    
    @objc
    func refreshQueue() {
        do {
            let extensionUploads = try ExtensionUploadManager.shared.savedFiles()
            if extensionUploads.isEmpty == false {
                // Please delete the extension at the bottom of the file when removing this code.
                // It should really be part of the ShareExtension.
                getRoot { [self] status in
                    switch status {
                    case .success(let root):
                        if let items = root.childItemVOS,
                           let uploadsFolder = items.filter({ $0.displayName == "Mobile Uploads" }).first,
                           let folderId = uploadsFolder.folderID,
                           let folderLinkId = uploadsFolder.folderLinkID {
                            // Mobile Uploads Folder Exists
                            extensionUploads.forEach({ $0.folder = FolderInfo(folderId: folderId, folderLinkId: folderLinkId) })
                            
                            upload(files: extensionUploads)
                            ExtensionUploadManager.shared.clearSavedFiles()
                        } else {
                            // Mobile Uploads Folder has to be created
                            let params: NewFolderParams = ("Mobile Uploads", root.folderLinkID ?? 0)
                            createNewFolder(params: params) { [self] folderVO in
                                guard let folderId = folderVO?.folderID, let folderLinkId = folderVO?.folderLinkID else { return }
                                
                                extensionUploads.forEach({ $0.folder = FolderInfo(folderId: folderId, folderLinkId: folderLinkId) })
                                
                                upload(files: extensionUploads)
                                ExtensionUploadManager.shared.clearSavedFiles()
                            }
                        }
                        
                    case .error(let message):
                        break
                    }
                }
            }
        } catch {
            print(error)
        }
        
        DispatchQueue.main.async { [self] in
            var didRefresh = false
            
            let savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
            
            let uploadNames = uploadQueue.operations.compactMap(\.name)
            for file in savedFiles ?? [] where uploadNames.contains(file.id) == false {
                let uploadOperation = UploadOperation(file: file) { error in
                    DispatchQueue.main.async {
                        var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                        savedFiles?.removeAll(where: { $0.id == file.id })
                        
                        if error == nil {
                            FileHelper().deleteFile(at: file.url)
                            
                            try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                        } else {
                            file.didFailUpload = true
                            
                            if var savedFiles = savedFiles {
                                savedFiles.append(file)
                                try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            } else {
                                try? PreferencesManager.shared.setCustomObject([file], forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            }
                        }
                        
                        NotificationCenter.default.post(name: Self.didUploadFileNotification, object: nil, userInfo: ["file": file])
                    }
                }
                uploadOperation.name = file.id
                
                uploadQueue.addOperation(uploadOperation)
                
                didRefresh = true
            }
            
            if didRefresh {
                NotificationCenter.default.post(name: Self.didRefreshQueueNotification, object: nil, userInfo: nil)
            }
        }
    }
    
    func cancelUpload(fileId: String) {
        var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        
        let fileURL = savedFiles?.first(where: { $0.id == fileId })?.url
        
        savedFiles?.removeAll(where: { $0.id == fileId })
        try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        
        uploadQueue.operations.first(where: { $0.name == fileId })?.cancel()
        
        if let fileURL = fileURL {
            FileHelper().deleteFile(at: fileURL)
        }
    }
    
    func cancelAll() {
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        
        let files = uploadQueue.operations.map({ $0 as! UploadOperation }).map(\.file)
        uploadQueue.cancelAllOperations()
        
        files.forEach { file in
            FileHelper().deleteFile(at: file.url)
        }
    }
    
    func inProgressUpload() -> FileInfo? {
        let executingOp = uploadQueue.operations.first(where: { $0.isExecuting })
        return (executingOp as? UploadOperation)?.file
    }
    
    func queuedFiles() -> [FileInfo] {
        return (try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)) ?? []
    }
    
    func operation(forFileId id: String) -> UploadOperation? {
        return uploadQueue.operations.first(where: { $0.name == id }) as? UploadOperation
    }
}

extension UploadManager {
    typealias RootResponse = (RootStatus) -> Void
    
    enum RootStatus {
        case success(root: MinFolderVO)
        case error(message: String?)
    }
    
    func getRoot(then handler: @escaping RootResponse) {
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
    
    private func onGetRootSuccess(_ model: GetRootResponse, _ handler: @escaping RootResponse) {
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
    
    func navigateMin(params: NavigateMinParams, backNavigation: Bool, then handler: @escaping RootResponse) {
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
    
    private func onNavigateMinSuccess(_ model: NavigateMinResponse, _ backNavigation: Bool, _ handler: @escaping RootResponse) {
        guard
            let folderVO = model.results?.first?.data?.first?.folderVO
        else {
            handler(.error(message: .errorMessage))
            return
        }
        
        handler(.success(root: folderVO))
    }
    
    func createNewFolder(params: NewFolderParams, then handler: @escaping ((MinFolderVO?) -> Void)) {
        let apiOperation = APIOperation(FilesEndpoint.newFolder(params: params))

        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: NavigateMinResponse = JSONHelper.convertToModel(from: response),
                    let folderVO = model.results?.first?.data?.first?.folderVO
                else {
                    handler(nil)
                    return
                }

                handler(folderVO)

            case .error(_, _):
                handler(nil)

            default:
                break
            }
        }
    }
}
