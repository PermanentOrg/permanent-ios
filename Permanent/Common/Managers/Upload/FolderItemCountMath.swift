//
//  FolderItemCountMath.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import Foundation

/// The arithmetic behind the item count on the upload Live Activity's folder card.
///
/// Extracted from `UploadLiveActivityManager` purely so it can be tested: the manager is
/// a singleton whose counters are private and whose entry points need ActivityKit
/// authorization, none of which is reachable from a unit test. This is the part where a
/// mistake would be silent — an off-by-one or a `nil` collapsing to `0` shows the user a
/// confidently wrong count — so it lives where it can be checked.
enum FolderItemCountMath {
    /// What the card should show: what the destination folder held when the batch
    /// started, plus everything that has landed since.
    ///
    /// Stays `nil` when the base is unknown. Uploads started from the Share Extension
    /// never list the destination, and counting only this batch would understate the
    /// folder — the card drops the count rather than print a wrong one.
    static func displayed(base: Int?, completedFiles: Int) -> Int? {
        base.map { $0 + completedFiles }
    }

    /// The base count to restore when reattaching to an activity after relaunch.
    ///
    /// Prefers the persisted snapshot. When that predates the field, the base is backed
    /// out of the running activity's own displayed count by subtracting the files already
    /// completed — the inverse of `displayed(base:completedFiles:)`. Clamped at zero,
    /// because the two numbers come from different writes and can disagree.
    static func recoveredBase(
        snapshotBase: Int?,
        activityDisplayedCount: Int?,
        completedFiles: Int
    ) -> Int? {
        if let snapshotBase { return snapshotBase }
        return activityDisplayedCount.map { max(0, $0 - completedFiles) }
    }
}
