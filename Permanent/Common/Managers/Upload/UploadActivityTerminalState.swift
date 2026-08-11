//
//  UploadActivityTerminalState.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.08.2026.
//

import Foundation

/// Decisions about an upload Live Activity's terminal state.
///
/// Extracted from `UploadLiveActivityManager` so it can be tested — the manager is a
/// singleton whose entry points need ActivityKit authorization. See
/// [[live-activity-manager-testability]].
enum UploadActivityTerminalState {
    /// Whether the batch is over. Terminal states are the ones the user should be allowed to
    /// see before the activity disappears.
    static func isTerminal(_ status: UploadActivityAttributes.UploadStatus) -> Bool {
        switch status {
        case .completed, .failed: return true
        case .uploading, .paused, .processing: return false
        }
    }

    /// The state an orphaned activity should be ended with on launch.
    ///
    /// An activity found running with no matching snapshot is normally a zombie from a
    /// previous session and is ended as `.failed`. But one case is not a zombie: a batch that
    /// finished and was mid-`completionHoldInterval` when iOS suspended the app. Its state is
    /// already `.completed`, and relabelling a finished upload "failed" — with its counts
    /// zeroed — tells the user something untrue about their data. Already-terminal states are
    /// therefore preserved exactly.
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
