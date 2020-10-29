//  
//  RecordVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26/10/2020.
//

import Foundation

// MARK: - RecordVO
struct RecordVO: Codable {
    let recordID, archiveID: Int?
    let archiveNbr: String?
    let publicDT, note: JSONNull?
    let displayName, uploadFileName: String?
    let uploadAccountID, size: Int?
    let recordVODescription: JSONNull?
    let displayDT: String?
    let displayEndDT, derivedDT, derivedEndDT, derivedCreatedDT: JSONNull?
    let locnID: Int?
    let timeZoneID: Int?
    let view, viewProperty: JSONNull?
    let imageRatio: Int?
    let encryption, metaToken: String?
    let refArchiveNbr: JSONNull?
    let type, thumbStatus: String?
    let thumbURL200, thumbURL500, thumbURL1000, thumbURL2000: JSONNull?
    let thumbDT, fileStatus: JSONNull?
    let status: String?
    let processedDT: JSONNull?
    let folderLinkVOS: [FolderLinkVO]?
    let folderLinkID, parentFolderID, position: Int?
    let accessRole: String?
    let folderArchiveID: Int?
    let folderLinkType: String?
    let pathAsFolderLinkID, pathAsText: JSONNull?
    let parentFolderLinkID: Int?
    let parentFolderVOS, parentArchiveNbr, parentDisplayName, pathAsArchiveNbr: JSONNull?
    let locnVO, timezoneVO, fileVOS, directiveVOS: JSONNull?
    let tagVOS, textDataVOS, archiveVOS: [JSONAny]?
    let saveAs, attachmentRecordVOS, isAttachment, hasAttachments: JSONNull?
    let uploadURI, fileDurationInSecs: JSONNull?
    let batchNbr: Int?
    let recordExifVO: JSONNull?
    let shareVOS: [JSONAny]?
    let accessVO, searchScore, archiveArchiveNbr: JSONNull?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case recordID = "recordId"
        case archiveID = "archiveId"
        case archiveNbr, publicDT, note, displayName, uploadFileName
        case uploadAccountID = "uploadAccountId"
        case size
        case recordVODescription = "description"
        case displayDT, displayEndDT, derivedDT, derivedEndDT, derivedCreatedDT
        case locnID = "locnId"
        case timeZoneID = "timeZoneId"
        case view, viewProperty, imageRatio, encryption, metaToken, refArchiveNbr, type, thumbStatus, thumbURL200, thumbURL500, thumbURL1000, thumbURL2000, thumbDT, fileStatus, status, processedDT
        case folderLinkVOS = "FolderLinkVOs"
        case folderLinkID = "folder_linkId"
        case parentFolderID = "parentFolderId"
        case position, accessRole
        case folderArchiveID = "folderArchiveId"
        case folderLinkType = "folder_linkType"
        case pathAsFolderLinkID = "pathAsFolder_linkId"
        case pathAsText
        case parentFolderLinkID = "parentFolder_linkId"
        case parentFolderVOS = "ParentFolderVOs"
        case parentArchiveNbr, parentDisplayName, pathAsArchiveNbr
        case locnVO = "LocnVO"
        case timezoneVO = "TimezoneVO"
        case fileVOS = "FileVOs"
        case directiveVOS = "DirectiveVOs"
        case tagVOS = "TagVOs"
        case textDataVOS = "TextDataVOs"
        case archiveVOS = "ArchiveVOs"
        case saveAs
        case attachmentRecordVOS = "AttachmentRecordVOs"
        case isAttachment, hasAttachments
        case uploadURI = "uploadUri"
        case fileDurationInSecs, batchNbr
        case recordExifVO = "RecordExifVO"
        case shareVOS = "ShareVOs"
        case accessVO = "AccessVO"
        case searchScore, archiveArchiveNbr, createdDT, updatedDT
    }
}
