//
//  UploadActivityAttributes.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.04.2026.
//

import ActivityKit
import Foundation

struct UploadActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        /// 1-based index of the file currently uploading
        var currentFileIndex: Int
        /// Total number of files in this upload batch
        var totalFiles: Int
        /// Display name of the file currently uploading
        var currentFileName: String
        /// Aggregate progress across all files (0.0–1.0)
        var overallProgress: Double
        /// Current upload status
        var status: UploadStatus
        /// Number of files that completed successfully
        var completedCount: Int
        /// Number of files that failed
        var failedCount: Int
        /// Items the destination folder holds right now. Here, not in the attributes, because
        /// it changes as files land. `nil` when unknown — the card omits the count.
        var folderItemCount: Int?
    }

    enum UploadStatus: String, Codable, Hashable {
        case uploading
        case paused
        case processing
        case completed
        case failed
    }

    /// Timestamp when this upload session started
    var sessionStartTime: Date
    /// Archive number for deep-link navigation to the upload folder
    var archiveNo: String
    /// Folder link ID for deep-link navigation to the upload folder
    var folderLinkId: Int
    /// Destination folder name. Immutable for a batch, so it belongs here, not in
    /// `ContentState`. Empty when unknown — the card drops the title line.
    var folderName: String
    /// Shared workspace rather than Private; drives the badge. `nil` when unknown and never
    /// defaulted to `false`, which would wrongly claim who can see the upload.
    var folderIsShared: Bool?
}
