//
//  UploadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation

class UploadManager {
    
    static let didRefreshQueueNotification = Notification.Name("UploadManager.didRefreshQueueNotification")
    
    static let shared: UploadManager = UploadManager()
    
    let uploadQueue: OperationQueue = OperationQueue()
    
    init() {
        uploadQueue.maxConcurrentOperationCount = 1
    }
    
    func upload(files: [FileInfo]) {
        for file in files {
            upload(file: file)
        }
        
        refreshQueue()
    }
    
    func upload(file: FileInfo, shouldRefreshQueue: Bool = false) {
        // Save the file data locally
        let fileHelper = FileHelper()
        fileHelper.saveFile(file.fileContents ?? Data(), named: file.id, withExtension: "upd", isDownload: false)
//        file.fileContents = nil
        
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
    
    func refreshQueue() {
        let savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        
        let uploadNames = uploadQueue.operations.compactMap(\.name)
        for file in savedFiles ?? [] where uploadNames.contains(file.id) == false {
            let csrf: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.csrfStorageKey) ?? ""
            let uploadOperation = UploadOperation(file: file, csrf: csrf) { error in
//                if error == nil {
                    var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
                    savedFiles?.removeAll(where: { $0.id == file.id })
                    try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
//                }
                
                self.refreshQueue()
            }
            uploadOperation.name = file.id
            
            uploadQueue.addOperation(uploadOperation)
        }
        
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: UploadManager.didRefreshQueueNotification, object: nil, userInfo: nil)
        }
    }
    
    func cancelUpload(fileId: String) {
        var savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        savedFiles?.removeAll(where: { $0.id == fileId })
        try? PreferencesManager.shared.setCustomObject(savedFiles, forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        
        uploadQueue.operations.first(where: { $0.name == fileId })?.cancel()
    }
    
    func cancelAll() {
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        uploadQueue.cancelAllOperations()
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
