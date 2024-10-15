//
//  UploadManager.swift
//  VSPFetchAssets
//
//  Created by Flaviu Silaghi on 09.10.2024.

import Foundation

class OtherUploadManager {
    
    static let shared = OtherUploadManager()
    
    let uploadQueue: OperationQueue = OperationQueue()
    
    init() {
        uploadQueue.maxConcurrentOperationCount = 1
    }
    
    func upload(files: [FileInfo]) async {
        for file in files {
            let uploadOperation = OtherUploadOperation(file: file) { error in
                if error == nil {
                    FileHelper().deleteFile(at: file.url)
                } else {
                    print("Fail")
                }
            }

            uploadOperation.name = file.id
            uploadQueue.addOperation(uploadOperation)
        }

        await withCheckedContinuation { continuation in // Use continuation to await barrier block
            uploadQueue.addBarrierBlock {
                DispatchQueue.main.async {
                    continuation.resume() // Resume after barrier block executes
                    print(" Resume after barrier block executes")
                }
            }
        }
    }
    
}
