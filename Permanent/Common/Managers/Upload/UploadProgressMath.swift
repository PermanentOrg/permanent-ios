//
//  UploadProgressMath.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.08.2026.
//

import Foundation

/// Progress arithmetic for the upload Live Activity, kept free of ActivityKit so it is testable
/// without an authorized activity.
enum UploadProgressMath {
    /// The ceiling on displayed progress while a file is still registering, so a batch never reads
    /// 100% next to an unfinished count.
    static let inFlightCeiling: Double = 0.99

    /// Byte-weighted progress, uncapped so it reaches 1.0 as the last byte lands. A failed file
    /// counts as done — it sends no more bytes, and omitting it lags the bar by one file.
    static func rawByteProgress(
        completedFiles: Int,
        failedFiles: Int,
        currentFileProgress: Double,
        totalFiles: Int
    ) -> Double {
        guard totalFiles > 0 else { return 0 }
        return (Double(completedFiles + failedFiles) + currentFileProgress) / Double(totalFiles)
    }

    /// What the bar should show: byte-weighted, but held at `inFlightCeiling` until every file has
    /// finished, because a file's bytes landing is not the same as its record existing.
    static func displayed(
        completedFiles: Int,
        failedFiles: Int,
        currentFileProgress: Double,
        totalFiles: Int
    ) -> Double {
        guard totalFiles > 0 else { return 0 }
        guard completedFiles + failedFiles < totalFiles else { return 1.0 }
        let raw = rawByteProgress(
            completedFiles: completedFiles,
            failedFiles: failedFiles,
            currentFileProgress: currentFileProgress,
            totalFiles: totalFiles
        )
        return min(raw, inFlightCeiling)
    }

    /// True once every byte is uploaded but registrations are still outstanding — the window the
    /// ceiling covers. Reported as `.processing` so a long registration reads as work, not a stall.
    static func isAwaitingRegistration(
        completedFiles: Int,
        failedFiles: Int,
        currentFileProgress: Double,
        totalFiles: Int
    ) -> Bool {
        guard totalFiles > 0, completedFiles + failedFiles < totalFiles else { return false }
        return rawByteProgress(
            completedFiles: completedFiles,
            failedFiles: failedFiles,
            currentFileProgress: currentFileProgress,
            totalFiles: totalFiles
        ) >= 1.0
    }
}
