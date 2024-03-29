//
//  FileModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct FileModel: Equatable, Codable {
    enum ThumbStatus: String, Codable {
        case ok = "status.generic.ok"
        case noThumb = "status.folder.empty"
        case genThumb = "status.folder.genthumb"
        case copying = "status.folder.copying"
        case moving = "status.folder.moving"
        case nested = "status.folder.nested"
        case new = "status.folder.new"
        case brokenThumb = "status.folder.broken_thumbnail"
        case noThumbCandidates = "status.folder.no_thumbnail_candidates"
        case unknown = "N/A"
        
        public init(from decoder: Decoder) throws {
            self = try ThumbStatus(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
        }
    }
    
    let thumbnailURL: String?
    let thumbnailURL500: String?
    let thumbnailURL1000: String?
    let thumbnailURL2000: String?
    let thumbStatus: ThumbStatus?
    
    var name: String
    var date: String
    let type: FileType
    let description: String
    let size: Int64
    let uploadFileName: String
    
    let createdDT: String?
    let modifiedDT: String?
    let uploadedDT: String?
    
    let archiveThumbnailURL: String?
    let archiveId: Int
    let archiveNo: String
    let recordId: Int
    let tagVOS: [TagVOData]?
    
    let folderId: Int
    let parentFolderId: Int
    let parentFolderLinkId: Int
    let folderLinkId: Int
    var fileStatus: FileStatus = .synced
    var fileState: FileState = .enabled
    var minArchiveVOS: [MinArchiveVO] = []
    
    var fileInfoId: String?
    
    var permissions: [Permission]
    var accessRole: AccessRole = .viewer
    
    var sharedByArchive: MinArchiveVO?
    
    init(model: FileInfo, archiveThumbnailURL: String? = nil, permissions: [Permission], thumbnailURL2000: String? = nil) {
        self.name = model.name
        self.date = DateUtils.currentDate
        self.createdDT = nil
        self.uploadedDT = nil
        self.modifiedDT = nil
        self.description = ""
        self.size = -1
        self.uploadFileName = ""
        self.archiveThumbnailURL = archiveThumbnailURL
        self.thumbnailURL = nil
        self.thumbnailURL500 = nil
        self.thumbnailURL1000 = nil
        self.thumbStatus = nil
        self.thumbnailURL2000 = thumbnailURL2000
        self.type = .image // TODO:
        self.archiveId = -1
        self.archiveNo = ""
        self.recordId = -1
        self.folderId = model.folder.folderId
        self.parentFolderId = -1
        self.parentFolderLinkId = -1
        self.folderLinkId = model.folder.folderLinkId
        self.fileStatus = .uploading
        self.fileInfoId = model.id
        self.tagVOS = nil
        
        self.permissions = permissions
    }
    
    init(name: String, recordId: Int, folderLinkId: Int, archiveNbr: String, type: String, permissions: [Permission], thumbnailURL2000: String? = nil) {
        self.name = name
        self.date = DateUtils.currentDate
        self.createdDT = nil
        self.uploadedDT = nil
        self.modifiedDT = nil
        self.description = ""
        self.size = -1
        self.uploadFileName = ""
        self.archiveThumbnailURL = ""
        self.thumbnailURL = nil
        self.thumbnailURL500 = nil
        self.thumbnailURL1000 = nil
        self.thumbnailURL2000 = thumbnailURL2000
        self.thumbStatus = nil
        self.type = FileType(rawValue: type) ?? .miscellaneous
        self.archiveId = -1
        self.archiveNo = archiveNbr
        self.recordId = -1
        self.folderId = -1
        self.parentFolderId = -1
        self.parentFolderLinkId = -1
        self.folderLinkId = folderLinkId
        self.tagVOS = nil
        
        self.permissions = permissions
    }
    
    init(model: ItemVO, archiveThumbnailURL: String? = nil, sharedByArchive: ArchiveVOData? = nil, permissions: [Permission], accessRole: AccessRole) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ? model.displayDT!.dateOnly : "-"
        self.createdDT = model.displayDT
        self.uploadedDT = model.createdDT
        self.modifiedDT = model.updatedDT
            
        self.thumbnailURL = model.thumbURL200
        self.thumbnailURL500 = model.thumbURL500
        self.thumbnailURL1000 = model.thumbURL1000
        self.thumbnailURL2000 = model.thumbURL2000
        self.thumbStatus = model.thumbStatus != nil ? ThumbStatus(rawValue: model.thumbStatus!) : nil
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
        
        self.permissions = permissions
        self.accessRole = accessRole
        self.tagVOS = model.tagVOS
        
        if let fullName = sharedByArchive?.fullName,
           let archiveIdURL = sharedByArchive?.archiveID {
            let minArchive = MinArchiveVO(name: fullName, thumbnail: sharedByArchive?.thumbURL200, shareStatus: "", shareId: 0, archiveID: archiveIdURL, folderLinkID: nil, accessRole: sharedByArchive?.accessRole)
            self.sharedByArchive = minArchive
        }
        
        model.shareVOS?.forEach {
            if let fullName = $0.archiveVO?.fullName,
               let shareStatusURL = $0.status,
               let shareIdURL = $0.shareID,
               let archiveIdURL = $0.archiveVO?.archiveID {
                let minArchive = MinArchiveVO(name: fullName, thumbnail: $0.archiveVO?.thumbURL200, shareStatus: shareStatusURL, shareId: shareIdURL, archiveID: archiveIdURL, folderLinkID: $0.folderLinkID, accessRole: $0.accessRole)
                self.minArchiveVOS.append(minArchive)
            }
        }
    }
    
    init(model: RecordVOData, archiveThumbnailURL: String? = nil, permissions: [Permission], accessRole: AccessRole) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ? model.displayDT!.dateOnly : "-"
        self.createdDT = model.displayDT
        self.uploadedDT = model.createdDT
        self.modifiedDT = model.updatedDT
            
        self.thumbnailURL = model.thumbURL200
        self.thumbnailURL500 = model.thumbURL500
        self.thumbnailURL1000 = model.thumbURL1000
        self.thumbnailURL2000 = model.thumbURL2000
        self.thumbStatus = model.thumbStatus != nil ? ThumbStatus(rawValue: model.thumbStatus!) : nil
        self.description = model.recordVODescription ?? ""
        self.size = Int64(model.size ?? -1)
        self.uploadFileName = model.uploadFileName ?? ""
        
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
        
        self.archiveThumbnailURL = archiveThumbnailURL
        self.archiveId = model.archiveID ?? -1
        self.archiveNo = model.archiveNbr ?? ""
        
        self.recordId = model.recordID ?? -1
        
        self.folderId = -1
        self.parentFolderId = model.parentFolderID ?? -1
        self.parentFolderLinkId = model.parentFolderLinkID ?? -1
        self.folderLinkId = model.folderLinkID ?? -1
        
        self.permissions = permissions
        self.accessRole = accessRole
        self.tagVOS = model.tagVOS
        
        model.shareVOS?.forEach {
            if let fullName = $0.archiveVO?.fullName,
               let thumbnailURL = $0.archiveVO?.thumbURL200,
               let shareStatusURL = $0.status,
               let shareIdURL = $0.shareID,
               let archiveIdURL = $0.archiveVO?.archiveID {
                let minArchive = MinArchiveVO(name: fullName, thumbnail: thumbnailURL, shareStatus: shareStatusURL, shareId: shareIdURL, archiveID: archiveIdURL, folderLinkID: $0.folderLinkID, accessRole: $0.accessRole)
                self.minArchiveVOS.append(minArchive)
            }
        }
    }
    
    init(model: MinFolderVO, archiveThumbnailURL: String? = nil, permissions: [Permission], accessRole: AccessRole) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ? model.displayDT!.dateOnly : "-"
        self.createdDT = model.displayDT
        self.uploadedDT = model.createdDT
        self.modifiedDT = model.updatedDT
            
        self.thumbnailURL = model.thumbURL200
        self.thumbnailURL500 = model.thumbURL500
        self.thumbnailURL1000 = model.thumbURL1000
        self.thumbnailURL2000 = model.thumbURL2000
        self.thumbStatus = model.thumbStatus != nil ? ThumbStatus(rawValue: model.thumbStatus!) : nil
        self.type = FileType(rawValue: model.type ?? "") ?? FileType.miscellaneous
        self.description = model.childFolderVOS?.description ?? ""
        self.size = -1
        self.uploadFileName = ""
         
        self.archiveThumbnailURL = archiveThumbnailURL
        self.archiveId = model.archiveID ?? -1
        self.archiveNo = model.archiveNbr ?? ""
        
        self.recordId = model.childItemVOS?.first?.recordID ?? -1
        
        self.folderId = model.folderID ?? -1
        self.parentFolderId = model.parentFolderID ?? -1
        self.parentFolderLinkId = model.parentFolderLinkID ?? -1
        self.folderLinkId = model.folderLinkID ?? -1
        
        self.permissions = permissions
        self.accessRole = accessRole
        self.tagVOS = model.tagVOS
        
        model.shareVOS?.forEach {
            if let fullName = $0.archiveVO?.fullName,
               let thumbnailURL = $0.archiveVO?.thumbURL200,
               let shareStatusURL = $0.status,
               let shareIdURL = $0.shareID,
               let archiveIdURL = $0.archiveVO?.archiveID {
                let minArchive = MinArchiveVO(name: fullName, thumbnail: thumbnailURL, shareStatus: shareStatusURL, shareId: shareIdURL, archiveID: archiveIdURL, folderLinkID: $0.folderLinkID, accessRole: $0.accessRole)
                self.minArchiveVOS.append(minArchive)
            }
        }
    }
    
    init(model: FolderVOData) {
        self.name = model.displayName ?? "-"
        self.date = model.displayDT != nil ? model.displayDT!.dateOnly : "-"
        self.createdDT = model.displayDT
        self.uploadedDT = model.createdDT
        self.modifiedDT = model.updatedDT
            
        self.thumbnailURL = model.thumbURL200
        self.thumbnailURL500 = model.thumbURL500
        self.thumbnailURL1000 = model.thumbURL1000
        self.thumbnailURL2000 = model.thumbURL2000
        self.thumbStatus = model.thumbStatus != nil ? ThumbStatus(rawValue: model.thumbStatus!) : nil
        self.type = FileType.publicRootFolder
        self.description = model.childFolderVOS?.description ?? ""
        self.size = -1
        self.uploadFileName = ""
        
        self.archiveThumbnailURL = ""
        self.archiveId = model.archiveID ?? -1
        self.archiveNo = model.archiveNbr ?? ""
        
        self.recordId = -1
        
        self.folderId = model.folderID ?? -1
        self.parentFolderId = model.parentFolderID ?? -1
        self.parentFolderLinkId = model.parentFolderLinkID ?? -1
        self.folderLinkId = model.folderLinkID ?? -1
        self.tagVOS = nil
        
        self.permissions = []
    }
    
    var canBeAccessed: Bool {
        return thumbStatus != .copying && thumbStatus != .moving
    }
}
