//  
//  SharebyURLVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.12.2020.
//

import Foundation

struct SharebyURLVO: Model {
    let shareByURLVO: SharebyURLVOData?
    
    enum CodingKeys: String, CodingKey {
        case shareByURLVO = "Shareby_urlVO"
    }
}

struct SharebyURLVOData: Model {
    let sharebyURLID: Int?
    let status, urlToken: String?
    let folderLinkID: JSONAny?
    let shareURL: String?
    let uses: Int?
    var maxUses: Int?
    var autoApproveToggle: Int?
    var previewToggle: Int?
    let defaultAccessRole: String?
    var expiresDT: String?
    let byAccountID, byArchiveID: Int?
    let createdDT, updatedDT: String?
    let accountVO: AccountVOData?
    let folderData: FolderVOData?
    let recordData: RecordVOData?
    let archiveVO: ArchiveVOData?
    let shareVO: ShareVOData?

    enum CodingKeys: String, CodingKey {
        case sharebyURLID = "shareby_urlId"
        case folderLinkID = "folder_linkId"
        case status, urlToken
        case shareURL = "shareUrl"
        case uses, maxUses, autoApproveToggle, previewToggle, defaultAccessRole, expiresDT
        case byAccountID = "byAccountId"
        case byArchiveID = "byArchiveId"
        case createdDT, updatedDT
        case folderData = "FolderVO"
        case recordData = "RecordVO"
        case archiveVO = "ArchiveVO"
        case accountVO = "AccountVO"
        case shareVO = "ShareVO"
    }
}
