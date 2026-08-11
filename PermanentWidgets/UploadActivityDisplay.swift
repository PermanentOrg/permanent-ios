//
//  UploadActivityDisplay.swift
//  PermanentWidgets
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import SwiftUI

/// Everything the three presentations draw, resolved from the activity's state in one
/// place so the Lock Screen and the Dynamic Island can never disagree about copy,
/// counts, or accent colour. Built by `UploadActivityLiveActivity.display(for:)`.
///
/// Every view in this target takes plain values like these rather than an
/// `ActivityViewContext`, so each presentation can be rendered at its exact design
/// size outside a running activity and diffed against Figma frame 112916.
///
/// Note this does NOT buy invalidation boundaries: the `LinearGradient` members mean
/// the struct isn't `Equatable`, and the composed views take the whole thing — every
/// update re-evaluates all of it. Fine here and deliberately not engineered around: a
/// Live Activity renders out-of-process from an archived view, at most once per whole
/// percent of progress (see `minProgressPushDelta` in UploadLiveActivityManager.swift).
/// Do not carry this reasoning into an in-app view, where it would be wrong.
struct UploadActivityDisplay {
    /// Header line, e.g. "Uploading to Permanent" — 26269:50898
    let headerTitle: String
    /// Header trailing count, e.g. "3 of 5" — 26269:50899
    let counter: String
    /// Lock Screen second line, left: the current file name — 26269:50846
    let fileLine: String
    /// Lock Screen second line, right: the percentage — 26269:50847
    let fileDetail: String
    /// Emphasised word in the pill row, e.g. "Uploading" — 26268:46411
    let statusWord: String
    /// De-emphasised remainder of the pill row, e.g. " • 4 of 6"
    let pillDetail: String
    let progress: Double
    /// Empty when unknown; the folder card drops its title line rather than show a blank.
    let folderName: String
    /// `nil` when the destination's item count isn't known — see
    /// `UploadActivityAttributes.ContentState.folderItemCount`.
    let folderItemCount: Int?
    /// `nil` when the workspace isn't known, so the badge is omitted rather than
    /// defaulting to Private — see `UploadActivityAttributes.folderIsShared`.
    let folderIsShared: Bool?
    let barFill: LinearGradient
    let ringTint: LinearGradient
    /// SF Symbol shown inside the progress ring to name the state. `nil` while uploading,
    /// where the moving arc already says it.
    let ringGlyph: String?
    /// A short actionable hint for the expanded island, e.g. "Tap to resume". `nil` when
    /// there is nothing for the user to do.
    let hint: String?
    /// True only while uploading. The design gives a folder card to that state; the
    /// others get the minimum-height pill row in the expanded island.
    let showsFolderCard: Bool
}

// MARK: - Preview samples
//
// Copy matches Figma frame 112916 exactly, so a preview can be diffed against the
// design render rather than eyeballed.

#if DEBUG
extension UploadActivityDisplay {
    static let previewUploading = UploadActivityDisplay(
        headerTitle: "Uploading to Permanent",
        counter: "3 of 5",
        fileLine: "arctic-fox-4366x3010-northern-hemisphere-animation.heic",
        fileDetail: "65%",
        statusWord: "Uploading",
        pillDetail: " • 4 of 6",
        progress: 0.65,
        folderName: "Northern Lights 2022",
        folderItemCount: 32,
        folderIsShared: false,
        barFill: UploadActivityStyle.progressFill,
        ringTint: UploadActivityStyle.brandOrange,
        ringGlyph: nil,
        hint: nil,
        showsFolderCard: true
    )

    static let previewShared = UploadActivityDisplay(
        headerTitle: "Uploading to Permanent",
        counter: "3 of 5",
        fileLine: "arctic-fox-4366x3010-northern-hemisphere-animation.heic",
        fileDetail: "65%",
        statusWord: "Uploading",
        pillDetail: " • 4 of 6",
        progress: 0.65,
        folderName: "Northern Lights 2022",
        folderItemCount: 32,
        folderIsShared: true,
        barFill: UploadActivityStyle.progressFill,
        ringTint: UploadActivityStyle.brandOrange,
        ringGlyph: nil,
        hint: nil,
        showsFolderCard: true
    )

    static let previewPaused = UploadActivityDisplay(
        headerTitle: "Upload Paused",
        counter: "3 of 5",
        fileLine: "Tap to resume",
        fileDetail: "65%",
        statusWord: "Paused",
        pillDetail: " • 4 of 6",
        progress: 0.65,
        folderName: "Northern Lights 2022",
        folderItemCount: 32,
        folderIsShared: false,
        barFill: UploadActivityStyle.brandOrange,
        ringTint: UploadActivityStyle.brandOrange,
        ringGlyph: "pause.fill",
        hint: "Tap to resume",
        showsFolderCard: false
    )

    /// Worst case: an upload re-queued from a queue persisted before `FolderInfo`
    /// carried the folder's name, count and workspace. The card must degrade rather
    /// than invent values — see `DestinationFolderCard`.
    static let previewUnknownFolder = UploadActivityDisplay(
        headerTitle: "Uploading to Permanent",
        counter: "1 of 3",
        fileLine: "IMG_4021.heic",
        fileDetail: "38%",
        statusWord: "Uploading",
        pillDetail: " • 1 of 3",
        progress: 0.38,
        folderName: "",
        folderItemCount: nil,
        folderIsShared: nil,
        barFill: UploadActivityStyle.progressFill,
        ringTint: UploadActivityStyle.brandOrange,
        ringGlyph: nil,
        hint: nil,
        showsFolderCard: true
    )
}
#endif
