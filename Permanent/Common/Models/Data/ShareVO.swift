//  
//  ShareVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09.12.2020.
//

import Foundation

struct ShareVO: Model {
    let shareVO: ShareVOData
    
    enum CodingKeys: String, CodingKey {
        case shareVO = "ShareVO"
    }
}

struct ShareVOData: Model {
    let shareID, folderLinkID, archiveID: Int?
    var accessRole: String?
    let type, status, requestToken: String?
    let previewToggle: JSONAny?
    let folderVO: FolderVOData?
    let recordVO: RecordVOData?
    let archiveVO: ArchiveVOData?
    let accountVO: AccountVOData?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case shareID = "shareId"
        case folderLinkID = "folder_linkId"
        case archiveID = "archiveId"
        case accessRole, type, status, requestToken, previewToggle
        case folderVO = "FolderVO"
        case recordVO = "RecordVO"
        case archiveVO = "ArchiveVO"
        case accountVO = "AccountVO"
        case createdDT, updatedDT
    }
}
