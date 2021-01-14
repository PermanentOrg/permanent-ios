//  
//  ItemVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17.12.2020.
//

struct ItemVO: Model {
    let folderID: Int?
    let archiveNbr: String?
    let archiveID: Int?
    let displayName, displayDT: String?
    let displayEndDT: String?
    let derivedDT: String?
    let derivedEndDT: String?
    let note, itemVODescription, special: JSONAny?
    let sort: String?
    let locnID: JSONAny?
    let timeZoneID: Int?
    let view: String?
    let viewProperty, thumbArchiveNbr: JSONAny?
    let imageRatio, type, thumbStatus: String?
    let thumbURL200: String?
    let thumbURL500: String?
    let thumbURL1000: String?
    let thumbURL2000: String?
    let thumbDT, status: String?
    let publicDT: JSONAny?
    let parentFolderID: Int?
    let folderLinkType: String?
    let folderLinkVOS: [FolderLinkVO]?
    let accessRole: String?
    let position: Int?
    let shareDT, pathAsFolderLinkID: JSONAny?
    let pathAsText: [JSONAny]?
    let folderLinkID, parentFolderLinkID: Int?
    let parentFolderVOS: [JSONAny]?
    let parentArchiveNbr: JSONAny?
    let pathAsArchiveNbr, childFolderVOS, recordVOS: [JSONAny]?
    let locnVO: JSONAny?
    let timezoneVO: TimezoneVO?
    let directiveVOS: JSONAny?
    let tagVOS, sharedArchiveVOS: [JSONAny]?
    let folderSizeVO: JSONAny?
    let attachmentRecordVOS: [JSONAny]?
    let hasAttachments: JSONAny?
    let childItemVOS: [JSONAny]?
    let shareVOS: [ShareVOData]?
    let accessVOS: JSONAny?
    let archiveArchiveNbr: String?
    let returnDataSize, posStart, posLimit, recordID: JSONAny?
    let uploadFileName, uploadAccountID, size, derivedCreatedDT: JSONAny?
    let metaToken, refArchiveNbr, fileStatus, processedDT: JSONAny?
    let folderArchiveID, fileVOS, textDataVOS, archiveVOS: JSONAny?
    let saveAs, isAttachment, uploadURI, fileDurationInSecs: JSONAny?
    let batchNbr, recordExifVO: JSONAny?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case folderID = "folderId"
        case archiveNbr
        case archiveID = "archiveId"
        case displayName, displayDT, displayEndDT, derivedDT, derivedEndDT, note
        case itemVODescription = "description"
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
        case size, derivedCreatedDT, metaToken, refArchiveNbr, fileStatus, processedDT
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
