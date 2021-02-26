//
//  DownloadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.01.2021.
//

import Foundation

class DownloadManagerGCD: Downloader {
    fileprivate var csrf: String!
    
    fileprivate var operation: APIOperation?
 
    init(csrf: String) {
        self.csrf = csrf
    }
    
    func download(_ file: FileDownloadInfo,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?,
                  completion: VoidAction? = nil) {
        startDownload(file, onDownloadStart: onDownloadStart, onFileDownloaded: onFileDownloaded, progressHandler: progressHandler, completion: completion)
    }
    
    func cancelDownload() {
        operation?.cancel()
    }
    
    fileprivate func startDownload(_ file: FileDownloadInfo,
                                   onDownloadStart: @escaping VoidAction,
                                   onFileDownloaded: @escaping DownloadResponse,
                                   progressHandler: ProgressHandler?,
                                   completion: VoidAction? = nil) {
        onDownloadStart()
        
        downloadFile(file, progressHandler: progressHandler) { [weak self] url, error in
            self?.operation = nil
                
            if let url = url {
                onFileDownloaded(url, nil)
            } else {
                onFileDownloaded(nil, error)
            }
            
            completion?()
        }
    }
    
    
    
    func downloadFile(_ file: FileDownloadInfo, progressHandler: ProgressHandler?, then handler: @escaping DownloadResponse) {
        getRecord(file) { [weak self] record, errorMessage in
            guard let record = record else {
                return handler(nil, errorMessage)
            }
            
            self?.downloadFileData(record: record, progressHandler: progressHandler, then: handler)
        }
    }
    
    func getRecord(_ file: FileDownloadInfo, then handler: @escaping GetRecordResponse) {
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
    
    func downloadFileData(record: RecordVO, progressHandler: ProgressHandler?, then handler: @escaping DownloadResponse) {
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
