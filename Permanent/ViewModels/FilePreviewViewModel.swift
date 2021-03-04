//
//  WebViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.02.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import UIKit
import WebKit

class FilePreviewViewModel: ViewModelInterface {
    let csrf : String
    var downloader: DownloadManagerGCD? = nil
    
    init(csrf: String) {
        self.csrf = csrf
    }
    
    func getRecord(file: FileViewModel, then handler: @escaping (RecordVO?) -> Void) {
        let downloadInfo = FileDownloadInfoVM(
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        downloader = DownloadManagerGCD(csrf: csrf)
        downloader?.getRecord(downloadInfo) { (record, error) in
            handler(record)
        }
    }
    
    func download(_ record: RecordVO, onFileDownloaded: @escaping DownloadResponse) {
        downloader = DownloadManagerGCD(csrf: csrf)
        downloader?.downloadFileData(record: record, progressHandler: nil, then: onFileDownloaded)
    }
    
    func fileData(withURL url: URL, onCompletion completion: @escaping (Data?, Error?) -> Void) {
        let dataTask = URLSession.shared.dataTask(with: url) { (data, response, error) in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        dataTask.resume()
    }
    
    func cancelDownload() {
        downloader?.cancelDownload()
        downloader = nil
    }
    
}

