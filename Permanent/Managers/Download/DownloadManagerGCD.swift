//
//  DownloadManager.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.01.2021.
//

import Foundation

typealias GetRecordResponse = (_ file: RecordVO?, _ errorMessage: Error?) -> Void
typealias GetFolderResponse = (_ folder: FolderVO?, _ errorMessage: Error?) -> Void

class DownloadManagerGCD: Downloader {
    fileprivate var operation: APIOperation?
 
    init() {
    }
    
    func fileVO(forRecordVO recordVO: RecordVO, fileType: FileType) -> FileVO? {
        if fileType == .video,
           let fileVO = recordVO.recordVO?.fileVOS?.first(where: {$0.format == "file.format.converted"}) {
            return fileVO
        } else {
            return recordVO.recordVO?.fileVOS?.first
        }
    }
    
    func download(_ file: FileViewModel,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?,
                  completion: VoidAction?) {
        let downloadInfo = FileDownloadInfoVM(
            fileType: file.type,
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        startDownload(downloadInfo, onDownloadStart: onDownloadStart, onFileDownloaded: onFileDownloaded, progressHandler: progressHandler, completion: completion)
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
            
            self?.downloadFileData(record: record, fileType: file.fileType, progressHandler: progressHandler, then: handler)
        }
    }
    
    func getRecord(_ file: FileDownloadInfo, then handler: @escaping GetRecordResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getRecord(itemInfo: (file.folderLinkId, file.parentFolderLinkId)))
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
    
    func getFolder(_ file: FileDownloadInfo, then handler: @escaping GetFolderResponse) {
        let apiOperation = APIOperation(FilesEndpoint.getFolder(itemInfo: (file.folderLinkId, file.parentFolderLinkId)))
        self.operation = apiOperation
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<FolderVO> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<FolderVO>.decoder
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
    
    func downloadFileData(record: RecordVO, fileType: FileType, progressHandler: ProgressHandler?, then handler: @escaping DownloadResponse) {
        guard
            let fileVO = fileVO(forRecordVO: record, fileType: fileType),
            let downloadURL = fileVO.downloadURL,
            let url = URL(string: downloadURL),
            let uploadFileName = record.recordVO?.uploadFileName,
            let displayName = record.recordVO?.displayName
        else {
            return handler(nil, APIError.invalidResponse)
        }
        
        // If the file was converted, then it most certainly is an mp4
        // Otherwise, the file was not converted, we use the original filename + extension
        let fileName: String
        if fileType == .video && fileVO.contentType == "video/mp4" {
            fileName = displayName + ".mp4"
        } else {
            fileName = uploadFileName
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
