//  
//  ShareVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09.12.2020.
//

import Foundation

struct ShareVO: Model {
    let shareID, folderLinkID, archiveID: Int?
    let accessRole, type, status, requestToken: String?
    let previewToggle: JSONAny?
    let folderVO: FolderVO?
    let recordVO: RecordVO?
    let archiveVO: ArchiveVO?
    let accountVO: AccountVO?
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
