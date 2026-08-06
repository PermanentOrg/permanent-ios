//
//  RecordVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26/10/2020.
//

struct RecordVO: Model {
    let recordVO: RecordVOData?

    enum CodingKeys: String, CodingKey {
        case recordVO = "RecordVO"
    }
}

struct RecordVOData: Model {
    let recordID, archiveID: Int?
    let archiveNbr: String?
    let publicDT, note: String?
    let displayName, uploadFileName: String?
    let uploadAccountID, size: Int?
    let recordVODescription: String?
    let displayDT: String?
    let displayEndDT, derivedDT, derivedEndDT, derivedCreatedDT: String?
    let locnID: Int?
    let timeZoneID: Int?
    let view, viewProperty: JSONAny?
    let imageRatio: JSONAny?
    let encryption, metaToken: String?
    let refArchiveNbr: JSONAny?
    let type, thumbStatus: String?
    let thumbnail256: String?
    let thumbURL200, thumbURL500, thumbURL1000, thumbURL2000: String?
    let thumbDT, fileStatus: String?
    let status: String?
    let processedDT: String?
    let folderLinkVOS: [FolderLinkVO]?
    let folderLinkID, parentFolderID, position: Int?
    let accessRole: String?
    let folderArchiveID: Int?
    let folderLinkType: String?
    let pathAsFolderLinkID, pathAsText: [String]?
    let parentFolderLinkID: Int?
    let parentArchiveNbr, parentDisplayName, pathAsArchiveNbr: JSONAny?
    let parentFolderVOS: [ParentFolderVO]?
    let locnVO, directiveVOS: LocnVO?
    let timezoneVO: TimezoneVO?
    let fileVOS: [FileVO]?
    let textDataVOS: [JSONAny]?
    let archiveVOS: [ArchiveVOData]?
    let tagVOS: [TagVOData]?
    let saveAs: JSONAny?
    let attachmentRecordVOS: [AttachmentRecordVO]?
    let isAttachment, hasAttachments: Bool?
    let uploadURI, fileDurationInSecs: JSONAny?
    let batchNbr: Int?
    let recordExifVO: RecordExifVO?
    let shareVOS: [ShareVOData]?
    let accessVO, searchScore: JSONAny?
    let archiveArchiveNbr: String?
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
        case view, viewProperty, imageRatio, encryption, metaToken, refArchiveNbr, type, thumbStatus, thumbnail256, thumbURL200, thumbURL500, thumbURL1000, thumbURL2000, thumbDT, fileStatus, status, processedDT
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

extension RecordVOData {
    private func nonEmpty(_ value: String?) -> String? {
        guard let value = value, !value.isEmpty else { return nil }
        return value
    }

    var preferredThumbnailURL: String? {
        resolvedThumbnail256 ?? nonEmpty(thumbURL500) ?? nonEmpty(thumbURL200) ?? nonEmpty(thumbURL1000) ?? nonEmpty(thumbURL2000)
    }

    /// `thumbnail256` on the V1 payload is the Archivematica access-copy thumbnail
    /// (`/access_copies/…/thumbnails/….jpg`), which comes back blank for a HEIC original.
    /// Preferring it unconditionally painted the file-type placeholder on every HEIC photo in a
    /// listing while the `.thumb.wNNN` renditions sitting beside it in the same payload were
    /// perfectly good — `thumbStatus` is `ok` and the full-res preview always loaded, which is
    /// what made this look like a backend gap rather than a client one.
    ///
    /// Mirrors the V2 guard (`RecordV2Data.accessCopyThumb256` / `isHEICOriginal`) added for the
    /// same payload quirk; V2 only ever reached it via `thumbnailUrls.256`, so the V1 field of
    /// the same name was left unguarded. Deliberately narrow: only HEIC skips the 256, so every
    /// non-HEIC record keeps the exact source it resolved before.
    ///
    /// Internal, not private: `FileModel.thumbnailURL256` must be built from this rather than the
    /// raw field, because `FileModel.preferredThumbnailURL` tries the 256 slot FIRST and that slot
    /// feeds the full-screen preview's blurred placeholder. Assigning the raw field there would
    /// fix listings and leave the preview blurring a blank image — the white-square bug. Named to
    /// match `RecordV2Data.resolvedThumbnail256`, which plays the identical role on V2.
    var resolvedThumbnail256: String? {
        guard !isHEICOriginal else { return nil }
        return nonEmpty(thumbnail256)
    }

    /// True when the ORIGINAL upload was HEIC/HEIF. V1 carries no granular `files[]` type, so
    /// this is a filename-extension test only — the V2 model checks `files[].originalFileIsHEIC`
    /// first and falls back to this same suffix check.
    var isHEICOriginal: Bool {
        let name = (uploadFileName ?? "").lowercased()
        return name.hasSuffix(".heic") || name.hasSuffix(".heif")
    }
}
