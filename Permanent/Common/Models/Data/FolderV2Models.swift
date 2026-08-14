//
//  FolderV2Models.swift
//  Permanent
//
//  Created by Lucian Cerbu on 23.01.2026.
//

import Foundation

// MARK: - Folder Response

struct FolderV2Response: Model {
    let items: [FolderV2Data]?
}

struct FolderV2Data: Model {
    let folderId: String?
    let displayName: String?
    let size: Int?
    let folderLinkId: String?
    let type: String?
    let status: String?
    let sort: String?
    let view: String?
    let imageRatio: Double?
    let description: String?
    let displayTimestamp: String?
    let createdAt: String?
    let updatedAt: String?
    let archive: FolderArchiveV2?
    let parentFolder: ParentFolderV2?
    let paths: FolderPathsV2?
    let thumbnailUrls: ThumbnailUrlsV2?
    let shares: [RecordShareV2]?
    let pendingShares: [PendingShareV2]?

    init(folderId: String? = nil,
         displayName: String? = nil,
         size: Int? = nil,
         folderLinkId: String? = nil,
         type: String? = nil,
         status: String? = nil,
         sort: String? = nil,
         view: String? = nil,
         imageRatio: Double? = nil,
         description: String? = nil,
         displayTimestamp: String? = nil,
         createdAt: String? = nil,
         updatedAt: String? = nil,
         archive: FolderArchiveV2? = nil,
         parentFolder: ParentFolderV2? = nil,
         paths: FolderPathsV2? = nil,
         thumbnailUrls: ThumbnailUrlsV2? = nil,
         shares: [RecordShareV2]? = nil,
         pendingShares: [PendingShareV2]? = nil) {
        self.folderId = folderId
        self.displayName = displayName
        self.size = size
        self.folderLinkId = folderLinkId
        self.type = type
        self.status = status
        self.sort = sort
        self.view = view
        self.imageRatio = imageRatio
        self.description = description
        self.displayTimestamp = displayTimestamp
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.archive = archive
        self.parentFolder = parentFolder
        self.paths = paths
        self.thumbnailUrls = thumbnailUrls
        self.shares = shares
        self.pendingShares = pendingShares
    }
}

struct FolderArchiveV2: Model {
    let id: String?
    let name: String?
}

struct ParentFolderV2: Model {
    let id: String?
    // Added in stela PR #773 — the parent's folder_link id, needed by the
    // legacy V1 write payloads (relocate/delete) that still run on V2-fetched items.
    let folderLinkId: String?
}

struct FolderPathsV2: Model {
    let names: [String]?
    // The full breadcrumb trail — every ancestor's folder-link id and archive number — so navigation
    // context is data rather than a hand-maintained stack.
    let folderLinkIds: [String]?
    let archiveNumbers: [String]?
}

struct ThumbnailUrlsV2: Model {
    let url256: String?
    let url200: String?
    let url500: String?
    let url1000: String?
    let url2000: String?
    
    enum CodingKeys: String, CodingKey {
        case url256 = "256"
        case url200 = "200"
        case url500 = "500"
        case url1000 = "1000"
        case url2000 = "2000"
    }
}

// MARK: - Folder Children Response

struct FolderChildrenV2Response: Model {
    let items: [FolderChildV2Data]?
    let pagination: PaginationV2?
}

struct FolderChildV2Data: Model {
    // Record fields (present for files)
    let recordId: String?
    // Folder fields (present for subfolders)
    let folderId: String?
    
    // Common fields
    let displayName: String?
    let archiveId: String?
    let archiveNumber: String?
    let type: String?
    let status: String?
    let size: Int?
    let imageRatio: Double?
    let displayDate: String?
    let fileCreatedAt: String?
    let createdAt: String?
    let updatedAt: String?
    let description: String?
    let downloadName: String?
    let uploadFileName: String?
    let thumbnail256: String?
    let thumbUrl200: String?
    let thumbUrl500: String?
    let thumbUrl1000: String?
    let thumbUrl2000: String?
    let folderLinkId: String?
    let folderLinkType: String?
    let parentFolderId: String?
    let parentFolderLinkId: String?
    let files: [FileV2Data]?
    let archive: FolderArchiveV2?

    // A record child sends parent ids and thumb URLs flat; a folder child nests them. `JSONDecoder`
    // does not flatten, so both shapes are decoded and resolved flat-then-nested below.
    let parentFolder: ParentFolderV2?
    let thumbnailUrls: ThumbnailUrlsV2?
    // Folders date themselves via displayTimestamp; records use displayDate.
    let displayTimestamp: String?
    // Per-item access (folder/record both carry it under Stela). Unused on the
    // Private Files path (permissions are archive-derived) but decoded for reuse.
    let shares: [RecordShareV2]?

    /// Returns true if this item is a folder (has folderId but no recordId)
    var isFolder: Bool {
        return folderId != nil && recordId == nil
    }

    /// Returns the item ID (recordId for files, folderId for folders)
    var itemId: String? {
        return recordId ?? folderId
    }

    // Resolve the flat (record) field first, then the nested (folder) field.
    var resolvedParentFolderId: String? { parentFolderId ?? parentFolder?.id }
    var resolvedParentFolderLinkId: String? { parentFolderLinkId ?? parentFolder?.folderLinkId }
    // The access copy is a valid last resort for list and grid slots, since a Stela copy has no
    // `.thumb.wNNN` renditions at all — but never for HEIC, whose access copy is blank.
    var resolvedThumb256: String? { thumbnail256 }
    var resolvedThumb200: String? { thumbUrl200 ?? thumbnailUrls?.url200 ?? accessCopyThumb256 }
    var resolvedThumb500: String? { thumbUrl500 ?? thumbnailUrls?.url500 ?? accessCopyThumb256 }
    var resolvedThumb1000: String? { thumbUrl1000 ?? thumbnailUrls?.url1000 }
    var resolvedThumb2000: String? { thumbUrl2000 ?? thumbnailUrls?.url2000 }

    /// The access-copy thumbnail, HEIC-guarded: nil for HEIC originals, whose access copies come
    /// back blank, and the real small thumbnail for everything else.
    private var accessCopyThumb256: String? {
        guard !isHEICOriginal, let url = thumbnailUrls?.url256, !url.isEmpty else { return nil }
        return url
    }

    /// True when the original is HEIC or HEIF, from the granular `type` in `files[]`, falling back
    /// to the filename extension for listings that omit it.
    var isHEICOriginal: Bool {
        if files?.originalFileIsHEIC == true { return true }
        let name = (uploadFileName ?? downloadName ?? "").lowercased()
        return name.hasSuffix(".heic") || name.hasSuffix(".heif")
    }

    /// Returns the best available thumbnail URL (flat for records, nested for folders)
    var bestThumbnailURL: String? {
        resolvedThumb256 ?? resolvedThumb500 ?? resolvedThumb200 ?? resolvedThumb1000 ?? resolvedThumb2000
    }
}

// MARK: - String → Int boundary (Stela ids are numeric-as-string; convert here only)

/// The one detection point for "Stela opaque ids are numeric". Only for the six opaque ids —
/// never `archiveNumber`, which is a dash-and-alpha string and stays a String end to end.
enum StelaIdBoundary {
    static func logNonNumeric(value: String, field: String, itemId: String?) {
        // Non-fatal in production; surfaces loudly in DEBUG/staging via the assertion
        // at the call site, so a contract break is caught before any user rollout.
        print("[Stela] non-numeric id '\(value)' for \(field) on item \(itemId ?? "nil") — fell back to -1")
    }
}

extension FolderChildV2Data {
    /// Converts a Stela String id to the legacy `Int` id at the migration boundary.
    /// Returns -1 (the existing "missing id" sentinel) for nil/empty/non-numeric input.
    func intId(_ value: String?, field: StaticString) -> Int {
        guard let value, !value.isEmpty else { return -1 }
        if let converted = Int(value) { return converted }
        assertionFailure("Stela V2 id '\(value)' for \(field) (item \(itemId ?? "nil")) is not Int-convertible")
        StelaIdBoundary.logNonNumeric(value: value, field: "\(field)", itemId: itemId)
        return -1
    }
}

struct FileV2Data: Model {
    let fileId: String?
    let size: Int?
    let type: String?
    let format: String?
    let fileUrl: String?
    let downloadUrl: String?
}

extension Array where Element == FileV2Data {
    /// True when the original upload is HEIC or HEIF, the type whose access-copy thumbnail comes back
    /// blank. Excludes `thumbnailUrls.256` from the fallbacks for those files only.
    var originalFileIsHEIC: Bool {
        contains { file in
            guard (file.format ?? "").contains("original") else { return false }
            let type = (file.type ?? "").lowercased()
            return type.contains("heic") || type.contains("heif")
        }
    }
}

struct PaginationV2: Model {
    let nextCursor: String?
    let nextPage: String?
    let totalPages: Int?
}
