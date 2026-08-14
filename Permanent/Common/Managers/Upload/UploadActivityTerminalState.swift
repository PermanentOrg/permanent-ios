//
//  UploadActivityTerminalState.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.08.2026.
//

import Foundation

/// Terminal-state decisions for an upload Live Activity. Split out of
/// `UploadLiveActivityManager`, whose entry points need ActivityKit authorization to test.
enum UploadActivityTerminalState {
    /// Whether the batch is over. Terminal states are the ones the user should be allowed to
    /// see before the activity disappears.
    static func isTerminal(_ status: UploadActivityAttributes.UploadStatus) -> Bool {
        switch status {
        case .completed, .failed: return true
        case .uploading, .paused, .processing: return false
        }
    }

    /// How to end an activity found running with no snapshot. Usually a zombie, so `.failed` —
    /// but a terminal state is kept exactly, since relabelling a finished upload would lie.
    static func orphanFinalState(
        existing: UploadActivityAttributes.ContentState
    ) -> UploadActivityAttributes.ContentState {
        guard !isTerminal(existing.status) else { return existing }
        return UploadActivityAttributes.ContentState(
            currentFileIndex: 0,
            totalFiles: 0,
            currentFileName: "",
            overallProgress: 0.0,
            status: .failed,
            completedCount: 0,
            failedCount: 0,
            folderItemCount: existing.folderItemCount
        )
    }
}
