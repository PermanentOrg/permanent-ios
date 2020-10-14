//  
//  MinFolderVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct MinFolderVO: Codable {
    let folderID: Int?
    let archiveNbr: String?
    let archiveID: Int?
    let displayName, displayDT: String?
    let displayEndDT, derivedDT, derivedEndDT: String?
    let note: JSONNull?
    let voDescription: String?
    let special: JSONNull?
    let sort: String?
    let locnID: JSONNull?
    let timeZoneID: Int?
    let view: String?
    let viewProperty, thumbArchiveNbr: JSONNull?
    let imageRatio, type, thumbStatus: String?
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
    let pathAsFolderLinkID: [Int]?
    let shareDT: JSONNull?
    let pathAsText: [String]?
    let folderLinkID: Int?
    let parentFolderLinkID: Int?
    let parentFolderVOS: [JSONAny]?
    let parentArchiveNbr, parentDisplayName: JSONNull?
    let pathAsArchiveNbr, childFolderVOS, recordVOS: [JSONAny]?
    let locnVO: JSONNull?
    let timezoneVO: TimezoneVO?
    let directiveVOS: JSONNull?
    let tagVOS, sharedArchiveVOS: [JSONAny]?
    let folderSizeVO: FolderSizeVO?
    let attachmentRecordVOS: [JSONAny]?
    let hasAttachments: JSONNull?
    let childItemVOS: [ChildItemVO]?
    let shareVOS: [JSONAny]?
    let accessVO, returnDataSize: JSONNull?
    let archiveArchiveNbr: String?
    let accessVOS: [JSONAny]?
    let posStart, posLimit, searchScore: JSONNull?
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
