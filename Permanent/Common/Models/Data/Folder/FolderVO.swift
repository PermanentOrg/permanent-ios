//  
//  FolderVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct FolderVO: Model {
    let folderVO: FolderVOData?
    
    enum CodingKeys: String, CodingKey {
        case folderVO = "FolderVO"
    }
}

struct FolderVOData: Model {
    let folderID: Int?
    let archiveNbr: String?
    let archiveID: Int?
    let displayName, displayDT: String?
    let displayEndDT, derivedDT, derivedEndDT: String?
    let note: String?
    let voDescription: String?
    let special: JSONAny?
    let sort: String?
    let locnID: Int?
    let timeZoneID: Int?
    let view: String?
    let viewProperty, thumbArchiveNbr: String?
    let type, thumbStatus: String?
    let imageRatio: JSONAny?
    let thumbURL200: String?
    let thumbURL500: String?
    let thumbURL1000: String?
    let thumbURL2000: String?
    let thumbDT, status: String?
    let publicDT: String?
    let parentFolderID: Int?
    let folderLinkType: String?
    let folderLinkVOS: [FolderLinkVO]?
    let accessRole: String?
    let position: Int?
    let pathAsFolderLinkID: [Int?]?
    let shareDT: JSONAny?
    let pathAsText: [String]?
    let folderLinkID: Int?
    let parentFolderLinkID: Int?
    let parentFolderVOS: [JSONAny]?
    let parentArchiveNbr, parentDisplayName: JSONAny?
    let pathAsArchiveNbr, childFolderVOS, recordVOS: [JSONAny]?
    let locnVO: LocnVO?
    let timezoneVO: TimezoneVO?
    let directiveVOS: JSONAny?
    let tagVOS, sharedArchiveVOS: [JSONAny]?
    let folderSizeVO: FolderSizeVO?
    let attachmentRecordVOS: [AttachmentRecordVO]?
    let hasAttachments: Bool?
    let childItemVOS: [FolderVOData]?
    let shareVOS: [ShareVOData]?
    let accessVO, returnDataSize: JSONAny?
    let archiveArchiveNbr: String?
    let accessVOS: [JSONAny]?
    let posStart, posLimit, searchScore: JSONAny?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case folderID = "folderId"
        case archiveNbr
        case archiveID = "archiveId"
        case displayName, displayDT, displayEndDT, derivedDT, derivedEndDT, note
        case voDescription = "description"
        case special, sort
        case locnID = "locnId"
        case timeZoneID = "timeZoneId"
        case view, viewProperty, thumbArchiveNbr, imageRatio, type, thumbStatus, thumbURL200, thumbURL500, thumbURL1000, thumbURL2000, thumbDT, status, publicDT
        case parentFolderID = "parentFolderId"
        case folderLinkType = "folder_linkType"
        case folderLinkVOS = "FolderLinkVOs"
        case accessRole, position, shareDT
        case pathAsFolderLinkID = "pathAsFolder_linkId"
        case pathAsText
        case folderLinkID = "folder_linkId"
        case parentFolderLinkID = "parentFolder_linkId"
        case parentFolderVOS = "ParentFolderVOs"
        case parentArchiveNbr, parentDisplayName, pathAsArchiveNbr
        case childFolderVOS = "ChildFolderVOs"
        case recordVOS = "RecordVOs"
        case locnVO = "LocnVO"
        case timezoneVO = "TimezoneVO"
        case directiveVOS = "DirectiveVOs"
        case tagVOS = "TagVOs"
        case sharedArchiveVOS = "SharedArchiveVOs"
        case folderSizeVO = "FolderSizeVO"
        case attachmentRecordVOS = "AttachmentRecordVOs"
        case hasAttachments
        case childItemVOS = "ChildItemVOs"
        case shareVOS = "ShareVOs"
        case accessVO = "AccessVO"
        case accessVOS = "AccessVOs"
        case archiveArchiveNbr, returnDataSize, posStart, posLimit, searchScore, createdDT, updatedDT
    }
}
