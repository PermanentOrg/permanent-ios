//
//  UploadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation

class UploadManager {
    
    static let didRefreshQueueNotification = Notification.Name("UploadManager.didRefreshQueueNotification")
    static let quotaExceededNotification = Notification.Name("UploadManager.quotaExceededNotification")
    
    static let shared: UploadManager = UploadManager()
    
    let uploadQueue: OperationQueue = OperationQueue()
    
    var timer: Timer?
    
    init() {
        uploadQueue.maxConcurrentOperationCount = 1
        
        timer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(refreshQueue), userInfo: nil, repeats: true)
    }
    
    func upload(files: [FileInfo]) {
        var filesSize = 0
        files.forEach { file in
            if let resources = try? file.url.resourceValues(forKeys:[.fileSizeKey]) {
                filesSize += resources.fileSize!
            }
        }
        
        // Call AccountAPI and figure if there's enough space left
        guard let accountId: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey),
              let csrf: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.csrfStorageKey) else {
            return
        }
        
        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: String(accountId), csrf: csrf))
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
        do {
            file.url = try fileHelper.copyFile(withURL: file.url)
        } catch {
            
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
        DispatchQueue.main.async { [self] in
            var didRefresh = false
            
            let savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
            
            let uploadNames = uploadQueue.operations.compactMap(\.name)
            for file in savedFiles ?? [] where uploadNames.contains(file.id) == false {
                let csrf: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.csrfStorageKey) ?? ""
                let uploadOperation = UploadOperation(file: file, csrf: csrf) { error in
                    DispatchQueue.main.async {
                        // Clear everything once the upload succeded
                        if error == nil {
                            var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            savedFiles?.removeAll(where: { $0.id == file.id })
                            try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                            
                            FileHelper().deleteFile(at: file.url)
                        } else {
                            // Find a neat way to print the error?
                        }
                    }
                }
                uploadOperation.name = file.id
                
                uploadQueue.addOperation(uploadOperation)
                
                didRefresh = true
            }
            
            if didRefresh {
                NotificationCenter.default.post(name: UploadManager.didRefreshQueueNotification, object: nil, userInfo: nil)
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
        
        refreshQueue()
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
    
    func queuedFiles() -> [FileInfo]? {
        let files = (uploadQueue.operations as! [UploadOperation]).map(\.file)
        return files
    }
    
    func operation(forFileId id: String) -> UploadOperation? {
        return uploadQueue.operations.filter({ $0.name == id }).first as? UploadOperation
    }
}
