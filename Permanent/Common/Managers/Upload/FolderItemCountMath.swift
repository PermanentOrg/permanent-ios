//
//  FolderItemCountMath.swift
//  Permanent
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import Foundation

/// Item count on the upload Live Activity's folder card. Split out of
/// `UploadLiveActivityManager` so this — where a mistake would be silent — can be tested.
enum FolderItemCountMath {
    /// What the folder held when the batch started, plus everything that has landed since.
    /// Stays `nil` when the base is unknown, so the card drops the count instead of guessing.
    static func displayed(base: Int?, completedFiles: Int) -> Int? {
        base.map { $0 + completedFiles }
    }

    /// The base to restore when reattaching after relaunch. Prefers the snapshot; otherwise
    /// inverts `displayed`, clamped at zero since the two numbers can disagree.
    static func recoveredBase(
        snapshotBase: Int?,
        activityDisplayedCount: Int?,
        completedFiles: Int
    ) -> Int? {
        if let snapshotBase { return snapshotBase }
        return activityDisplayedCount.map { max(0, $0 - completedFiles) }
    }
}
