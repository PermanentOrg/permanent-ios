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
         thumbnailUrls: ThumbnailUrlsV2? = nil) {
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
    }
}

struct FolderArchiveV2: Model {
    let id: String?
    let name: String?
}

struct ParentFolderV2: Model {
    let id: String?
}

struct FolderPathsV2: Model {
    let names: [String]?
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
    
    /// Returns true if this item is a folder (has folderId but no recordId)
    var isFolder: Bool {
        return folderId != nil && recordId == nil
    }
    
    /// Returns the item ID (recordId for files, folderId for folders)
    var itemId: String? {
        return recordId ?? folderId
    }
    
    /// Returns the best available thumbnail URL
    var bestThumbnailURL: String? {
        thumbnail256 ?? thumbUrl500 ?? thumbUrl200 ?? thumbUrl1000 ?? thumbUrl2000
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

struct PaginationV2: Model {
    let nextCursor: String?
    let nextPage: String?
    let totalPages: Int?
}
