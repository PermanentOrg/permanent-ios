//  
//  DownloadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.01.2021.
//

import Foundation

class DownloadManager: Downloader {
    
    fileprivate var csrf: String!
    
    fileprivate var downloadInProgress: Bool = false
    
    fileprivate var downloadQueue: [SharedFileViewModel] = []
    
    init(csrf: String) {
        self.csrf = csrf
    }
    
    func download(_ file: SharedFileViewModel,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?,
                  then handler: @escaping ServerResponse)
    {
        
        var downloadFile = file
        downloadFile.status = .downloading
        downloadQueue.append(downloadFile)
        
        // save progress lcoally: TODO
        
        onDownloadStart()
        
        if downloadInProgress {
            return
        }
        
        downloadInProgress = true
        
        handleRecursiveFileDownload(
            downloadFile,
            onFileDownloaded: onFileDownloaded,
            progressHandler: progressHandler,
            then: handler
        )
    }
    
    func handleRecursiveFileDownload(_ file: SharedFileViewModel,
                                     onFileDownloaded: @escaping FileDownloadResponse,
                                     progressHandler: ProgressHandler?,
                                     then handler: @escaping ServerResponse)
    {
        downloadFile(file, progressHandler: progressHandler) { url, errorMessage in
            
            if let url = url {
                onFileDownloaded(url, nil)
                
                if self.downloadQueue.isEmpty {
                    self.downloadInProgress = false
                    return handler(.success)
                } else {
                    // Remove the first item from queue and save progress.
                    self.downloadQueue.removeFirst()
                    
                    guard let nextFile = self.downloadQueue.first else {
                        self.downloadInProgress = false
                        return handler(.success)
                    }
                    
                    // save progress in prefs
                    
                    self.handleRecursiveFileDownload(nextFile,
                                                     onFileDownloaded: onFileDownloaded,
                                                     progressHandler: progressHandler,
                                                     then: handler)
                }
            } else {
                onFileDownloaded(nil, errorMessage)
                self.downloadInProgress = false
                
                handler(.error(message: errorMessage))
            }
        }
    }
    
    
    fileprivate func downloadFile(_ file: SharedFileViewModel, progressHandler: ProgressHandler?, then handler: @escaping DownloadResponse) {
        getRecord(file) { record, errorMessage in

            guard let record = record else {
                return handler(nil, errorMessage)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.downloadFileData(record: record, progressHandler: progressHandler, then: handler)
            }
        }
    }
    
    
    fileprivate func getRecord(_ file: SharedFileViewModel, then handler: @escaping GetRecordResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getRecord(itemInfo: (file.folderLinkId, file.parentFolderLinkId, csrf)))
        
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
                    handler(nil, .errorMessage)
                    return
                }
                
                handler(model.results.first?.data?.first, nil)
                    
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                    
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
            return handler(nil, .errorMessage)
        }
        
        let apiOperation = APIOperation(FilesEndpoint.download(url: url, filename: fileName, progressHandler: progressHandler))
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            
            switch result {
            case .file(let fileURL, _):
                guard let url = fileURL else {
                    handler(nil, .errorMessage)
                    return
                }
            
                handler(url, nil)
    
            case .error(let error, _):
                handler(nil, error?.localizedDescription)
                
            default:
                break
            }
        }
    }
    
}
