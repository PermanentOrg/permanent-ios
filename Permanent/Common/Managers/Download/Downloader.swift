//  
//  Downloadable.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.01.2021.
//

import Foundation

protocol Downloader {
    
    func download(_ file: FileModel,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?,
                  completion: VoidAction?)
    
    func download(_ file: FileDownloadInfo,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?,
                  completion: VoidAction?)
    
    func cancelDownload()

    func getRecord(_ file: FileDownloadInfo, then handler: @escaping GetRecordResponse)
    func getFolder(_ file: FileDownloadInfo, then handler: @escaping GetFolderResponse)
}
