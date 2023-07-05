//
//  WebViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.02.2021.
//

import UIKit
import WebKit
import AVKit

class FilePreviewViewModel: ViewModelInterface {
    let file: FileModel
    var name: String
    var publicURL: URL?
    
    var recordVO: RecordVO?
    var isEditable: Bool {
        return file.permissions.contains(.edit)
    }
    
    weak var delegate: FilePreviewNavigationControllerDelegate?
    
    var downloader: DownloadManagerGCD? = nil
    
    let tagsRepository: TagsRepository
    
    init(file: FileModel, tagsRepository: TagsRepository = TagsRepository()) {
        self.tagsRepository = tagsRepository
        self.file = file
        name = file.name
    }
    
    func getRecord(file: FileModel, then handler: @escaping (RecordVO?) -> Void) {
        let downloadInfo = FileDownloadInfoVM(
            fileType: file.type,
            folderLinkId: file.folderLinkId,
            parentFolderLinkId: file.parentFolderLinkId
        )
        
        downloader = DownloadManagerGCD()
        downloader?.getRecord(downloadInfo) { [weak self] (record, error) in
            self?.onRecordCallback(file: file, record: record, error: error, then: handler)
        }
    }
    
    func onRecordCallback(file: FileModel, record: RecordVO?, error: Error?, then handler: @escaping (RecordVO?) -> Void) {
        if record != nil && error == nil {
            recordVO = record
            
            handler(record)
        } else {
            getRecord(file: file, then: handler)
        }
    }
    
    func download(_ record: RecordVO, fileType: FileType, onFileDownloaded: @escaping DownloadResponse) {
        downloader = DownloadManagerGCD()
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
        var fileVO: FileVO? = recordVO?.recordVO?.fileVOS?.first

        if file.type == .video || file.type == .audio {
            if let uwFileVO = recordVO?.recordVO?.fileVOS?.first,
               let url = URL(string: uwFileVO.downloadURL),
               AVAsset(url: url).isPlayable {
                fileVO = uwFileVO
            } else if let uwFileVO = recordVO?.recordVO?.fileVOS?.first(where: {$0.format == "file.format.converted"}) {
                fileVO = uwFileVO
            }
        }
        
        return fileVO
    }
    
    func fileThumbnailURL() -> String? {
        let stringURL: String? = recordVO?.recordVO?.thumbURL2000
        return stringURL
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
    
    func update(file: FileModel, name: String?, description: String?, date: Date?, location: LocnVO?, completion: @escaping ((Bool) -> Void)) {
        let params: UpdateRecordParams = (name, description, date, location, file.recordId, file.folderLinkId, file.archiveNo)
        let apiOperation = APIOperation(FilesEndpoint.update(params: params))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            DispatchQueue.main.async {
                switch result {
                case .json( _, _):
                    self.getRecord(file: file) { (record) in
                        NotificationCenter.default.post(name: .filePreviewVMDidSaveData, object: self)
                        completion(true)
                    }
                    
                case .error(_, _):
                    NotificationCenter.default.post(name: .filePreviewVMSaveDataFailed, object: self)
                    completion(false)
                    
                default:
                    NotificationCenter.default.post(name: .filePreviewVMSaveDataFailed, object: self)
                    completion(false)
                }
            }
        }
    }
    
    func validateLocation(lat: Double, long: Double, completion: @escaping ((LocnVO?) -> Void)) {
        let params: GeomapLatLongParams = (lat, long)
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
        if inMetadataScreen && isEditable {
            address == "" ? (address = "Tap to set".localized()) : ()
        }
        return address
    }
    
    func getTagsByArchive(archiveId: Int, completion: @escaping (([TagVO]?) -> Void)) {
        let tags = tagsRepository.getTagsByArchive(archiveId: archiveId) { tags, error in
            if let tags = tags {
                completion(tags)
            } else {
                completion(nil)
            }
        }
        completion(tags)
    }
    
    func addTag(tagNames: [String], completion: @escaping (([TagLinkVO]?) -> Void)) {
        tagsRepository.assignTag(tagNames: tagNames, recordId: recordVO?.recordVO?.recordID ?? 0) { tags, error in
            if let tags = tags {
                self.getRecord(file: self.file) { (record) in
                    completion(tags)
                }
            } else {
                completion(nil)
            }
        }
    }
    
    func unassignTag(tagVO: [TagVO], completion: @escaping ((String?) -> Void)) {
        tagsRepository.unassignTag(tagVO: tagVO, recordId: recordVO?.recordVO?.recordID ?? 0) { error in
            if error == nil {
                self.getRecord(file: self.file) { (record) in
                    completion(nil)
                }
            } else {
                completion(error.debugDescription)
            }
        }
    }
    
    func deleteTag(tagVO: [TagVO], completion: @escaping ((String?) -> Void)) {
        tagsRepository.deleteTag(tagVO: tagVO) { error in
            if error == nil {
                self.getRecord(file: self.file) { (record) in
                    completion(nil)
                }
            } else {
                completion(error.debugDescription)
            }
        }
    }
}
