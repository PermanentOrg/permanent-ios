//  
//  Downloadable.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.01.2021.
//

import Foundation

protocol Downloader {
    
    //func download(fromURL: URL)
    
    func download(_ file: SharedFileViewModel,
                  onDownloadStart: @escaping VoidAction,
                  onFileDownloaded: @escaping DownloadResponse,
                  progressHandler: ProgressHandler?,
                  then handler: @escaping ServerResponse)
    
}
