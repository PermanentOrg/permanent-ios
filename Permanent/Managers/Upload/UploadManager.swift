//
//  UploadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/10/2020.
//

import Foundation

class UploadManager {
    
    let uploadQueue: OperationQueue = OperationQueue()
    
    func initialize() {
        let savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        
//        for file in savedFiles {
//
//        }
    }
    
    func upload(files: [FileInfo]) {
        for file in files {
            upload(file: file)
        }
    }
    
    func upload(file: FileInfo) {
        // Save the file data locally
        let fileHelper = FileHelper()
        fileHelper.saveFile(file.fileContents ?? Data(), named: file.id, withExtension: "upd", isDownload: false)
        file.fileContents = nil
        
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
    }
    
    func cancelUpload() {
        
    }
    
    
}
