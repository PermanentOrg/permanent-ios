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
        /// How many items the destination folder holds right now — the folder's
        /// count when the batch started, plus everything that has landed since.
        /// Lives here rather than in the attributes because it changes as files
        /// complete, and the design surfaces it live ("32 items • Private").
        ///
        /// `nil` when the count isn't known: uploads started from the Share
        /// Extension never list the destination, and showing a count that counts
        /// only this batch would understate the folder. The folder card omits the
        /// count entirely in that case rather than print a wrong one.
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
    /// Display name of the destination folder, shown on the folder card. Immutable
    /// for the life of a batch, so it belongs here rather than in `ContentState`.
    /// Empty when unknown — the card drops the title line rather than show a blank.
    var folderName: String
    /// Whether the destination sits in the Shared workspace rather than Private.
    /// Drives the badge text and colour on the folder card.
    ///
    /// `nil` when unknown, and deliberately not defaulted to `false`: an upload
    /// re-queued from a queue persisted before `FolderInfo.isShared` existed has no
    /// value to report, and labelling a Shared destination "Private" is a wrong claim
    /// about who can see the upload. The card omits the badge instead.
    var folderIsShared: Bool?
}
