//  
//  ChildItemVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

struct ChildItemVO: Codable {
    let folderID: Int?
        let archiveNbr: String?
        let archiveID: Int?
        let displayName, displayDT: String?
        let displayEndDT, derivedDT, derivedEndDT: String?
        let note: JSONNull?
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
        let shareDT: JSONNull?
        let pathAsFolderLinkID: [Int]?
        let pathAsText: [JSONAny]?
        let folderLinkID: Int?
        let parentFolderLinkID: Int?
        let parentFolderVOS: [JSONAny]?
        let parentArchiveNbr: JSONNull?
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
        let returnDataSize: JSONNull?
        let archiveArchiveNbr: String?
        let accessVOS: [JSONAny]?
        let posStart, posLimit: JSONNull?
        let createdDT, updatedDT: String?
    
        // in plus fata de folder VO
        let batchNbr: JSONNull?
        let childItemVODescription: String?
        let derivedCreatedDT: JSONNull?
        let encryption: JSONNull?
        let fileDurationInSecs: JSONNull?
        let fileStatus: JSONNull?
        let fileVOS: JSONNull?
        let folderArchiveID: JSONNull?
        let isAttachment, metaToken: JSONNull?
    
        let processedDT: JSONNull?
        let recordExifVO: JSONNull?
        let recordID: Int?
        let refArchiveNbr: JSONNull?
        let saveAs: JSONNull?
        let size: Int?
        let textDataVOS: [JSONAny]?
        let uploadAccountID: JSONNull?
        let uploadFileName: JSONNull?
        let uploadURI: JSONNull?
        let archiveVOS: [JSONAny]?

    enum CodingKeys: String, CodingKey {
        case folderID = "folderId"
        case archiveNbr
        case archiveID = "archiveId"
        case displayName, displayDT, displayEndDT, derivedDT, derivedEndDT, note
        case childItemVODescription = "description"
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
        case parentArchiveNbr, pathAsArchiveNbr
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
        case accessVOS = "AccessVOs"
        case archiveArchiveNbr, returnDataSize, posStart, posLimit
        case recordID = "recordId"
        case uploadFileName
        case uploadAccountID = "uploadAccountId"
        case size, derivedCreatedDT, encryption, metaToken, refArchiveNbr, fileStatus, processedDT
        case folderArchiveID = "folderArchiveId"
        case fileVOS = "FileVOs"
        case textDataVOS = "TextDataVOs"
        case archiveVOS = "ArchiveVOs"
        case saveAs, isAttachment
        case uploadURI = "uploadUri"
        case fileDurationInSecs, batchNbr
        case recordExifVO = "RecordExifVO"
        case createdDT, updatedDT
    }
}
