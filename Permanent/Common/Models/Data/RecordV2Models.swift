//
//  RecordV2Models.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.02.2026.
//

import Foundation

// MARK: - Record V2 Response

struct RecordV2Response: Model {
    let data: RecordV2Data?
}

struct RecordV2Data: Model {
    let recordId: String?
    let displayName: String?
    let archiveId: String?
    let archiveNumber: String?
    let description: String?
    let publicAt: String?
    let downloadName: String?
    let uploadFileName: String?
    let uploadAccountId: String?
    let uploadPayerAccountId: String?
    let size: Int?
    let displayDate: String?
    let displayTimeInEDTF: String?
    let fileCreatedAt: String?
    let imageRatio: Double?
    let thumbnail256: String?
    let thumbUrl200: String?
    let thumbUrl500: String?
    let thumbUrl1000: String?
    let thumbUrl2000: String?
    let thumbnailUrls: ThumbnailUrlsV2?
    let status: String?
    let type: String?
    let createdAt: String?
    let updatedAt: String?
    let altText: String?
    let location: LocationV2?
    let files: [FileV2Data]?
    let folderLinkId: String?
    let folderLinkType: String?
    let parentFolderId: String?
    let parentFolderLinkId: String?
    let parentFolderArchiveNumber: String?
    let tags: [TagV2]?
    let archiveArchiveNumber: String?
    let shares: [RecordShareV2]?
    let pendingShares: [PendingShareV2]?
    let archive: RecordArchiveV2?
}

extension RecordV2Data {
    private func nonEmpty(_ value: String?) -> String? {
        guard let value = value, !value.isEmpty else { return nil }
        return value
    }

    var resolvedThumbnail256: String? {
        // `thumbnailUrls.256` is the access copy: tiny, and blank for HEIC, so it would paint a white
        // blur. Only a real flat `thumbnail256` counts here; callers fall back to `.thumb.wNNN`.
        nonEmpty(thumbnail256)
    }

    var preferredThumbnailURL: String? {
        // Access copy last: a Stela copy gets no `.thumb.wNNN` renditions, so its guarded access-copy
        // thumbnail is the only one it has. Real renditions always win when present.
        resolvedThumbnail256 ?? nonEmpty(thumbUrl500) ?? nonEmpty(thumbUrl200) ?? nonEmpty(thumbUrl1000) ?? nonEmpty(thumbUrl2000) ?? accessCopyThumb256
    }

    /// The Archivematica access-copy thumbnail, HEIC-guarded (blank for HEIC originals).
    /// Mirrors FolderChildV2Data.accessCopyThumb256.
    private var accessCopyThumb256: String? {
        guard !isHEICOriginal, let url = nonEmpty(thumbnailUrls?.url256) else { return nil }
        return url
    }

    /// True when the ORIGINAL file is HEIC/HEIF — `files[]` granular type first, filename
    /// extension fallback. Mirrors FolderChildV2Data.isHEICOriginal.
    var isHEICOriginal: Bool {
        if files?.originalFileIsHEIC == true { return true }
        let name = (uploadFileName ?? downloadName ?? "").lowercased()
        return name.hasSuffix(".heic") || name.hasSuffix(".heif")
    }
}

// MARK: - V2 record → legacy RecordVO adapter (item detail / preview / download)

extension RecordV2Data {
    /// Builds a legacy `RecordVO` payload so the existing detail, preview and download code consumes
    /// V2 unchanged. `contentType` is the one gap, derived from each file's granular `type`.
    func toRecordVOPayload() -> [String: Any] {
        func intOf(_ value: String?) -> Int? {
            guard let value = value, let converted = Int(value) else { return nil }
            return converted
        }

        var record: [String: Any] = [:]
        if let value = intOf(recordId) { record["recordId"] = value }
        if let value = intOf(archiveId) { record["archiveId"] = value }
        if let value = archiveNumber { record["archiveNbr"] = value }
        if let value = displayName { record["displayName"] = value }
        if let value = description { record["description"] = value }
        if let value = uploadFileName { record["uploadFileName"] = value }
        if let value = size { record["size"] = value }
        if let value = type { record["type"] = value }
        if let value = displayDate { record["displayDT"] = value }
        if let value = createdAt { record["createdDT"] = value }
        if let value = updatedAt { record["updatedDT"] = value }
        if let value = fileCreatedAt { record["derivedCreatedDT"] = value } // note: V2 has no derivedDT ("Created" row blank)
        if let value = resolvedThumbnail256 { record["thumbnail256"] = value }
        if let value = thumbUrl200 ?? thumbnailUrls?.url200 { record["thumbURL200"] = value }
        if let value = thumbUrl500 ?? thumbnailUrls?.url500 { record["thumbURL500"] = value }
        if let value = thumbUrl1000 ?? thumbnailUrls?.url1000 { record["thumbURL1000"] = value }
        if let value = thumbUrl2000 ?? thumbnailUrls?.url2000 { record["thumbURL2000"] = value }
        if let value = intOf(folderLinkId) { record["folder_linkId"] = value }
        if let value = intOf(parentFolderLinkId) { record["parentFolder_linkId"] = value }
        record["FileVOs"] = (files ?? []).map { $0.toFileVOPayload() }
        if let location = location { record["LocnVO"] = location.toLocnVOPayload() }
        if let tags = tags {
            // tagId is load-bearing: the batch-metadata screen derives its tag state from these VOs and the
            // unlink body sends it, so a nil became `tagId: 0` and unassign no-oped while the chip vanished.
            record["TagVOs"] = tags.compactMap { tag -> [String: Any]? in
                guard let name = tag.name else { return nil }
                var vo: [String: Any] = ["name": name]
                if let id = intOf(tag.tagId) { vo["tagId"] = id }
                if let type = tag.type { vo["type"] = type }
                return vo
            }
        }

        return ["RecordVO": record]
    }
}

extension FileV2Data {
    func toFileVOPayload() -> [String: Any] {
        func intOf(_ value: String?) -> Int? {
            guard let value = value, let converted = Int(value) else { return nil }
            return converted
        }
        var file: [String: Any] = [:]
        if let value = intOf(fileId) { file["fileId"] = value }
        if let value = size { file["size"] = value }
        if let value = format { file["format"] = value }
        if let value = type { file["type"] = value }
        if let value = fileUrl { file["fileURL"] = value }
        if let value = downloadUrl { file["downloadURL"] = value }
        if let value = FileV2Data.mimeType(forFileType: type) { file["contentType"] = value }
        return file
    }

    /// Stela carries no `contentType`, but the preview guards and download logic need a MIME string,
    /// so derive it from the granular file type — `type.file.image.jpeg` becomes `image/jpeg`.
    static func mimeType(forFileType type: String?) -> String? {
        guard let type = type, type.hasPrefix("type.file.") else { return nil }
        let parts = type.split(separator: ".").map(String.init) // ["type","file","<class>","<subtype>"]
        let cls = parts.count > 2 ? parts[2] : ""
        var sub = parts.count > 3 ? parts[3] : ""
        switch cls {
        case "image":
            if sub == "jpg" { sub = "jpeg" }
            return sub.isEmpty ? genericMimeType : "image/\(sub)"
        case "video":
            return sub.isEmpty ? genericMimeType : "video/\(sub)"
        case "audio":
            return sub.isEmpty ? genericMimeType : "audio/\(sub)"
        case "pdf":
            return "application/pdf"
        default:
            // The preview requires a non-nil contentType in both branches and only needs presence, not
            // accuracy — so a generic MIME keeps docs and archives previewable rather than blank.
            return genericMimeType
        }
    }

    /// Fallback MIME for `type.file.*` classes with no specific mapping.
    private static let genericMimeType = "application/octet-stream"
}

extension LocnVO {
    /// Maps the picked V1 location into the V2 `LocationInput` body. The server updates the existing
    /// row in place, so re-applying is safe; only the fields it accepts are sent.
    func toLocationInputPayload() -> [String: Any] {
        var location: [String: Any] = [:]
        if let value = displayName, !value.isEmpty { location["name"] = value }
        if let value = locality, !value.isEmpty { location["city"] = value }
        if let value = adminOneName, !value.isEmpty { location["state"] = value }
        if let value = country, !value.isEmpty { location["country"] = value }
        if let value = latitude { location["latitude"] = value }
        if let value = longitude { location["longitude"] = value }
        let street = [streetNumber, streetName].compactMap { $0 }.filter { !$0.isEmpty }.joined(separator: " ")
        if !street.isEmpty { location["sublocation"] = street }
        return location
    }
}

extension LocationV2 {
    /// Maps to the subset of LocnVO JSON keys the detail map cell reads
    /// (streetNumber/streetName/locality/country + latitude/longitude).
    func toLocnVOPayload() -> [String: Any] {
        var locn: [String: Any] = [:]
        if let value = streetNumber { locn["streetNumber"] = value }
        if let value = streetName { locn["streetName"] = value }
        if let value = locality { locn["locality"] = value }
        if let value = country { locn["country"] = value }
        if let value = countryCode { locn["countryCode"] = value }
        if let value = displayName { locn["displayName"] = value }
        if let value = latitude { locn["latitude"] = value }
        if let value = longitude { locn["longitude"] = value }
        return locn
    }
}

struct LocationV2: Model {
    let id: String?
    let streetNumber: String?
    let streetName: String?
    let locality: String?
    let county: String?
    let state: String?
    let latitude: Double?
    let longitude: Double?
    let country: String?
    let countryCode: String?
    let displayName: String?
}

struct TagV2: Model {
    let tagId: String?
    let name: String?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case tagId = "id"  // Stela sends the tag id under "id" (as a JSON number)
        case name, type
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        // The API sends "id" as a JSON number, though a string is tolerated. Decoding it string-only
        // yields nil silently, which made tag unassign send `tagId: 0` and fail.
        if let intId = try? container.decode(Int.self, forKey: .tagId) {
            tagId = String(intId)
        } else if let stringId = try? container.decode(String.self, forKey: .tagId) {
            tagId = stringId
        } else {
            tagId = nil
        }
        name = try? container.decode(String.self, forKey: .name)
        type = try? container.decode(String.self, forKey: .type)
    }
}

struct RecordShareV2: Model {
    let shareId: String?
    let accessRole: String?
    let status: String?
    let archive: RecordShareArchiveV2?
    
    enum CodingKeys: String, CodingKey {
        case shareId = "id"  // Map "id" from JSON to shareId
        case accessRole
        case status
        case archive
    }
}

struct RecordShareArchiveV2: Model {
    let archiveId: String?
    let thumbnail256: String?
    let thumbUrl200: String?
    let thumbUrl500: String?
    let thumbUrl1000: String?
    let thumbUrl2000: String?
    let thumbnailUrls: ThumbnailUrlsV2?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case archiveId = "id"  // Map "id" from JSON to archiveId
        case thumbnail256
        case thumbUrl200
        case thumbUrl500
        case thumbUrl1000
        case thumbUrl2000
        case thumbnailUrls
        case name
    }
}

extension RecordShareArchiveV2 {
    private func nonEmpty(_ value: String?) -> String? {
        guard let value = value, !value.isEmpty else { return nil }
        return value
    }

    var resolvedThumbnail256: String? {
        nonEmpty(thumbnail256) ?? nonEmpty(thumbnailUrls?.url256)
    }

    var preferredThumbnailURL: String? {
        resolvedThumbnail256 ?? nonEmpty(thumbUrl500) ?? nonEmpty(thumbUrl200) ?? nonEmpty(thumbUrl1000) ?? nonEmpty(thumbUrl2000)
    }
}

struct RecordArchiveV2: Model {
    let id: String?
    let archiveNumber: String?
    let name: String?
}

struct PendingShareV2: Model {
    let id: String?
    let email: String?
    let name: String?
    let accessRole: String?
}
