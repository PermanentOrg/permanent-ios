//
//  FileViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct FileViewModel: Equatable {
    let csrf: String?
    
    let thumbnailURL: String?
    let thumbnailURL2000: String?
    var name: String
    let date: String
    let type: FileType
    var description: String
    let size: Int64
    let uploadFileName: String
    
    let archiveThumbnailURL: String?
    let archiveId: Int
    let archiveNo: String
    let recordId: Int
    
    let folderId: Int
    let parentFolderId: Int
    let parentFolderLinkId: Int
    let folderLinkId: Int
    var fileStatus: FileStatus = .synced
    var fileState: FileState = .enabled
    var minArchiveVOS: [MinArchiveVO] = []
    var tagVOS: [TagVOsaved] = []
    
    init(model: FileInfo, archiveThumbnailURL: String? = nil) {
        self.csrf = nil
        
        self.name = model.name
        self.date = DateUtils.currentDate
        self.description = ""
        self.size = -1
        self.uploadFileName = ""
        self.archiveThumbnailURL = archiveThumbnailURL
        self.thumbnailURL = nil
        self.thumbnailURL2000 = nil
        self.type = .image // TODO:
        self.archiveId = -1
        self.archiveNo = ""
        self.recordId = -1
        self.folderId = model.folder.folderId
        self.parentFolderId = -1
        self.parentFolderLinkId = -1
        self.folderLinkId = model.folder.folderLinkId
        self.fileStatus = .uploading
    }
    
    init(model: ItemVO, csrf: String?, archiveThumbnailURL: String? = nil) {
        self.csrf = csrf
        
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ? model.displayDT!.dateOnly : "-"
            
        self.thumbnailURL = model.thumbURL200
        self.thumbnailURL2000 = model.thumbURL2000
        self.description = model.itemVODescription ?? ""
        self.size = model.size ?? -1
        self.uploadFileName = model.uploadFileName ?? ""
        
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
        
        self.archiveThumbnailURL = archiveThumbnailURL
        self.archiveId = model.archiveID ?? -1
        self.archiveNo = model.archiveNbr ?? ""
        
        self.recordId = model.recordID ?? -1
        
        self.folderId = model.folderID ?? -1
        self.parentFolderId = model.parentFolderID ?? -1
        self.parentFolderLinkId = model.parentFolderLinkID ?? -1
        self.folderLinkId = model.folderLinkID ?? -1
        
        model.shareVOS?.forEach {
            if let fullName = $0.archiveVO?.fullName,
               let thumbnailURL = $0.archiveVO?.thumbURL200,
               let shareStatusURL = $0.status,
               let shareIdURL = $0.shareID,
               let archiveIdURL = $0.archiveVO?.archiveID
            {
                let minArchive = MinArchiveVO(name: fullName, thumbnail: thumbnailURL, shareStatus: shareStatusURL, shareId: shareIdURL, archiveID: archiveIdURL)
                self.minArchiveVOS.append(minArchive)
                
            }
        }
        
        model.tagVOS?.forEach {
            if let name = $0.name {
                let tag = TagVOsaved(name: name, status: "", tagId: -1, type: "", createdDT: "", updatedDT: "")
                self.tagVOS.append(tag)
            }
        }
    }
    
    init(model: MinFolderVO, csrf: String?, archiveThumbnailURL: String? = nil) {
        self.csrf = csrf
        
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ? model.displayDT!.dateOnly : "-"
            
        self.thumbnailURL = model.thumbURL200
        self.thumbnailURL2000 = model.thumbURL2000
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
        self.description = model.childFolderVOS?.description ?? ""
        self.size = -1
        self.uploadFileName = ""
        
        self.archiveThumbnailURL = archiveThumbnailURL
        self.archiveId = model.archiveID ?? -1
        self.archiveNo = model.archiveNbr ?? ""
        
        self.recordId = model.childItemVOS?.first?.recordID ?? -1 // TODO:
        
        self.folderId = model.folderID ?? -1
        self.parentFolderId = model.parentFolderID ?? -1
        self.parentFolderLinkId = model.parentFolderLinkID ?? -1
        self.folderLinkId = model.folderLinkID ?? -1
        
        model.shareVOS?.forEach {
            if let fullName = $0.archiveVO?.fullName,
               let thumbnailURL = $0.archiveVO?.thumbURL200,
               let shareStatusURL = $0.status,
               let shareIdURL = $0.shareID,
               let archiveIdURL = $0.archiveVO?.archiveID
            {
                let minArchive = MinArchiveVO(name: fullName, thumbnail: thumbnailURL, shareStatus: shareStatusURL, shareId: shareIdURL, archiveID: archiveIdURL)
                self.minArchiveVOS.append(minArchive)
            }
        }
    }
}
