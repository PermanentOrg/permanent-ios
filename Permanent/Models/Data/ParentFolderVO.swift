//  
//  ParentFolderVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 11/11/2020.
//

import Foundation

struct ParentFolderVO: Model {
    let folderID: Int?
    let archiveNbr: String?
    let archiveID: Int?
    let displayName, displayDT, displayEndDT, derivedDT: String?
    let derivedEndDT: String?
    let note: String?
    let parentFolderVODescription: String?
    let special: JSONNull?
    let sort: String?
    let locnID: String?
    let timeZoneID: Int?
    let view: String?
    let viewProperty, thumbArchiveNbr: JSONNull?
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
    let shareDT, pathAsFolderLinkID: JSONNull?
    let pathAsText: [JSONAny]?
    let folderLinkID, parentFolderLinkID: Int?
    let parentFolderVOS: [JSONAny]?
    let parentArchiveNbr, parentDisplayName: JSONNull?
    let pathAsArchiveNbr, childFolderVOS, recordVOS: [JSONAny]?
    let locnVO: JSONNull?
    let timezoneVO: TimezoneVO?
    let directiveVOS: JSONNull?
    let tagVOS, sharedArchiveVOS: [JSONAny]?
    let folderSizeVO: JSONNull?
    let attachmentRecordVOS: [AttachmentRecordVO]?
    let hasAttachments: Bool?
    let childItemVOS, shareVOS: [JSONAny]?
    let accessVO, accessVOS: JSONNull?
    let archiveArchiveNbr: String?
    let returnDataSize, posStart, posLimit, searchScore: JSONNull?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case folderID = "folderId"
        case archiveNbr
        case archiveID = "archiveId"
        case displayName, displayDT, displayEndDT, derivedDT, derivedEndDT, note
        case parentFolderVODescription = "description"
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
