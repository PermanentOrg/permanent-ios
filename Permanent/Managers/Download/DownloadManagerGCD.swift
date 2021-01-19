//
//  DownloadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.01.2021.
//

import Foundation

class DownloadManagerGCD: Downloader {
    fileprivate var csrf: String!
    
    // fileprivate var downloadInProgress: Bool = false
    
    // fileprivate var downloadQueue: [SharedFileViewModel] = []
    
    fileprivate var serialQueue: DispatchQueue!
    
    fileprivate var operation: APIOperation?
    
    init(csrf: String) {
        self.csrf = csrf
        serialQueue = DispatchQueue(label: "permanent.download.queue")
    }
    
    func download(_ file: FileDownloadInfo,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?) {
        serialQueue.async {
            self.startDownload(file,
                               onDownloadStart: onDownloadStart,
                               onFileDownloaded: onFileDownloaded,
                               progressHandler: progressHandler)
        }
    }
    
    func cancelDownload() {
        operation?.cancel()
    }
    
    fileprivate func startDownload(_ file: FileDownloadInfo,
                                   onDownloadStart: @escaping VoidAction,
                                   onFileDownloaded: @escaping DownloadResponse,
                                   progressHandler: ProgressHandler?) {
        onDownloadStart()
        
        downloadFile(file, progressHandler: progressHandler) { url, error in
            
            self.operation = nil
                
            if let url = url {
                onFileDownloaded(url, nil)
            } else {
                onFileDownloaded(nil, error)
            }
        }
    }
    
    
    
    fileprivate func downloadFile(_ file: FileDownloadInfo, progressHandler: ProgressHandler?, then handler: @escaping DownloadResponse) {
        getRecord(file) { record, errorMessage in

            guard let record = record else {
                return handler(nil, errorMessage)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.downloadFileData(record: record, progressHandler: progressHandler, then: handler)
            }
        }
    }
    
    fileprivate func getRecord(_ file: FileDownloadInfo, then handler: @escaping GetRecordResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getRecord(itemInfo: (file.folderLinkId, file.parentFolderLinkId, csrf)))
        self.operation = apiOperation
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<RecordVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<RecordVO>.decoder
                    ),
                    model.isSuccessful
                    
                else {
                    handler(nil, APIError.parseError(nil))
                    return
                }
                 
                handler(model.results.first?.data?.first, nil)
                    
            case .error(let error, _):
                handler(nil, error)
                    
            default:
                break
            }
        }
    }
    
    fileprivate func downloadFileData(record: RecordVO, progressHandler: ProgressHandler?, then handler: @escaping DownloadResponse) {
        guard
            let downloadURL = record.recordVO?.fileVOS?.first?.downloadURL,
            let url = URL(string: downloadURL),
            let fileName = record.recordVO?.uploadFileName
        else {
            return handler(nil, APIError.invalidResponse)
        }
        
        let apiOperation = APIOperation(FilesEndpoint.download(url: url, filename: fileName, progressHandler: progressHandler))
        self.operation = apiOperation
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            
            switch result {
            case .file(let fileURL, _):
                guard let url = fileURL else {
                    handler(nil, APIError.invalidResponse)
                    return
                }
            
                handler(url, nil)
    
            case .error(let error, _):
                handler(nil, error as? APIError)
                
            default:
                break
            }
        }
    }
}
