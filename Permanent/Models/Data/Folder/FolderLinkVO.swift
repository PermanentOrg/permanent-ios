//  
//  FolderLinkVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct FolderLinkVO: Codable {
    let folderLinkID, archiveID, folderID: Int?
    let recordID: Int?
    let parentFolderLinkID, parentFolderID, position, linkCount: Int?
    let accessRole, type, status: String?
    let shareDT: JSONNull?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case folderLinkID = "folder_linkId"
        case archiveID = "archiveId"
        case folderID = "folderId"
        case recordID = "recordId"
        case parentFolderLinkID = "parentFolder_linkId"
        case parentFolderID = "parentFolderId"
        case position, linkCount, accessRole, type, status, shareDT, createdDT, updatedDT
    }
}
