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
    let file: FileViewModel
    var csrf: String { file.csrf ?? "" }
    
    var recordVO: RecordVO?
    var isEditable: Bool {
        let accessRole = recordVO?.recordVO?.accessRole?.lowercased() ?? ""
        return accessRole.contains("editor") ||
            accessRole.contains("curator") ||
            accessRole.contains("manager") ||
            accessRole.contains("owner")
    }
    
    var downloader: DownloadManagerGCD? = nil
    
    init(file: FileViewModel) {
        self.file = file
    }
    
    func getRecord(file: FileViewModel, then handler: @escaping (RecordVO?) -> Void) {
        let downloadInfo = FileDownloadInfoVM(
            fileType: file.type,
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        downloader = DownloadManagerGCD(csrf: csrf)
        downloader?.getRecord(downloadInfo) { (record, error) in
            self.recordVO = record
            
            handler(record)
        }
    }
    
    func download(_ record: RecordVO, fileType: FileType, onFileDownloaded: @escaping DownloadResponse) {
        downloader = DownloadManagerGCD(csrf: csrf)
        downloader?.downloadFileData(record: record, fileType: fileType, progressHandler: nil, then: onFileDownloaded)
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
    
    func fileVO() -> FileVO? {
        if file.type == .video,
           let fileVO = recordVO?.recordVO?.fileVOS?.first(where: {$0.format == "file.format.converted"}) {
            return fileVO
        } else {
            return recordVO?.recordVO?.fileVOS?.first
        }
    }
    
    func fileName() -> String? {
        guard let fileVO = self.fileVO(),
              let uploadFileName = self.recordVO?.recordVO?.uploadFileName,
              let displayName = self.recordVO?.recordVO?.displayName
        else {
            return ""
        }
        
        // If the file was converted, then it most certainly is an mp4
        // Otherwise, the file was not converted, we use the original filename + extension
        let fileName: String
        if self.file.type == .video && fileVO.contentType == "video/mp4" {
            fileName = displayName + ".mp4"
        } else {
            fileName = uploadFileName
        }
        return fileName
    } 
    
    func update(file: FileViewModel, name: String?, description: String?, date: Date?, location: LocnVO?, completion: @escaping ((Bool) -> Void)) {
        let params: UpdateRecordParams = (name, description, date, location, file.recordId, file.folderLinkId, file.archiveNo, csrf)
        let apiOperation = APIOperation(FilesEndpoint.update(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json( _, _):
                self.getRecord(file: file) { (record) in
                    completion(true)
                }
                
            case .error(_, _):
                completion(false)
                
            default:
                completion(false)
            }
        }
    }
    
    func validateLocation(lat: Double, long: Double, completion: @escaping ((LocnVO?) -> Void)) {
        let params: GeomapLatLongParams = (lat, long, csrf)
        let apiOperation = APIOperation(LocationEndpoint.geomapLatLong(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let json, _):
                guard let model: APIResults<LocnVOData> = JSONHelper.decoding(from: json, with: APIResults<LocnVOData>.decoder), model.isSuccessful else {
                    completion(nil)
                    return
                }
                let locnVO: LocnVO? = model.results.first?.data?.first?.locnVO
                completion(locnVO)
                
            case .error(_, _):
                completion(nil)
                
            default:
                completion(nil)
            }
        }
    }
    
    func getAddressString(_ items: [String?], _ inMetadataScreen: Bool = true) -> String {
        var address = items.compactMap { $0 }.joined(separator: ", ")
        if inMetadataScreen {
            address == "" ? (address = "(tap to set)") : ()
        }
        return address
    }
    
}

