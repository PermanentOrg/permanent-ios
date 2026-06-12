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
        nonEmpty(thumbnail256) ?? nonEmpty(thumbnailUrls?.url256)
    }

    var preferredThumbnailURL: String? {
        resolvedThumbnail256 ?? nonEmpty(thumbUrl500) ?? nonEmpty(thumbUrl200) ?? nonEmpty(thumbUrl1000) ?? nonEmpty(thumbUrl2000)
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
