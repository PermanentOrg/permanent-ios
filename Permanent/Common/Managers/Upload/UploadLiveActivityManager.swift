//
//  UploadLiveActivityManager.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.04.2026.
//

import Foundation
import ActivityKit
import UIKit
import os.log

/// Disk-persisted snapshot of the manager's in-memory counters so the Live Activity
/// can be reattached after the app is terminated mid-upload.
struct UploadLiveActivitySnapshot: Codable {
    let activityId: String
    var totalFiles: Int
    var completedFiles: Int
    var failedFiles: Int
    var currentFileName: String
    var lastReportedProgress: Double
    var archiveNo: String
    var folderLinkId: Int
    /// Folder item count at batch start; completed files are added for display. Optional so a
    /// snapshot from an older build still decodes rather than looking orphaned.
    var folderBaseItemCount: Int?
}

class UploadLiveActivityManager {
    static let shared = UploadLiveActivityManager()

    private let logger = Logger(subsystem: "com.permanent.ios", category: "LiveActivity")
    private let flowLogger = Logger(subsystem: "com.permanent.ios", category: "UploadFlow")
    private var currentActivity: Activity<UploadActivityAttributes>?

    // Tracking state
    private var totalFiles: Int = 0
    private var completedFiles: Int = 0
    private var failedFiles: Int = 0
    private var currentFileName: String = ""
    private var currentFileProgress: Double = 0.0
    private var lastReportedProgress: Double = 0.0

    // Set once when the batch starts, carried through every content update. `nil` when the
    // caller can't say — the Share Extension never lists the destination.
    private var folderBaseItemCount: Int?

    /// Base count plus what has landed, shown live. `nil` when the base is unknown, so the
    /// card omits it rather than undercount.
    private var displayedFolderItemCount: Int? {
        FolderItemCountMath.displayed(base: folderBaseItemCount, completedFiles: completedFiles)
    }

    /// ActivityKit budgets updates per app, and `updateProgress` fires hundreds of times per file, so
    /// only whole-percent changes push. A change of file always pushes.
    private let minProgressPushDelta: Double = 0.01
    private var lastPushedProgress: Double = 0.0
    private var lastPushedFileName: String = ""

    /// Whether a Live Activity is currently active.
    var isActive: Bool { currentActivity != nil }

    /// Whether any upload Live Activity is visible on the Lock Screen (active or recently ended).
    /// Ended activities remain visible for up to 30 seconds before iOS removes them.
    var hasVisibleActivity: Bool {
        return !Activity<UploadActivityAttributes>.activities.isEmpty
    }

    /// How long a finished batch stays **active** so the island can show its terminal state.
    /// Ending immediately drops it from the island unseen; `.after(...)` only affects the banner.
    private let completionHoldInterval: TimeInterval = 4

    /// A terminal batch waiting out `completionHoldInterval`. Separate from `currentActivity`
    /// so the manager looks idle to a new upload, yet can still end this one first.
    private var finishingActivity: Activity<UploadActivityAttributes>?

    /// Matched to the ~30s background-execution budget: once suspended, no update can land, so the
    /// activity goes stale and truthfully reads as paused. Foregrounding refreshes it.
    private let staleInterval: TimeInterval = 30

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    // MARK: - Launch Reconciliation

    /// On launch, reattaches to a previous session's activity when a snapshot matches it, leaves
    /// activities alone while metadata shows uploads in flight, and ends genuine orphans.
    func reconcileOnLaunch() {
        let runningActivities = Activity<UploadActivityAttributes>.activities
        let snapshot = loadSnapshot()

        // An activity stuck in `.processing` is a leftover from the old processing-timer path, and by
        // then every file has completed — so flip it to `.completed` and let it dismiss.
        let stuckProcessing = runningActivities.filter { $0.content.state.status == .processing && $0.activityState != .ended }
        for activity in stuckProcessing {
            let finalState = UploadActivityAttributes.ContentState(
                currentFileIndex: activity.content.state.totalFiles,
                totalFiles: activity.content.state.totalFiles,
                currentFileName: "",
                overallProgress: 1.0,
                status: .completed,
                completedCount: activity.content.state.completedCount,
                failedCount: activity.content.state.failedCount,
                folderItemCount: activity.content.state.folderItemCount
            )
            logger.info("🔼 Migrating stuck .processing Live Activity id=\(activity.id, privacy: .public) to .completed")
            Task {
                await activity.end(
                    .init(state: finalState, staleDate: nil),
                    dismissalPolicy: .after(Date().addingTimeInterval(120))
                )
            }
        }
        let stuckIds = Set(stuckProcessing.map { $0.id })
        let remainingActivities = runningActivities.filter { !stuckIds.contains($0.id) }

        if let snapshot = snapshot,
           let reattached = remainingActivities.first(where: { $0.id == snapshot.activityId && $0.activityState != .ended }) {
            currentActivity = reattached
            totalFiles = snapshot.totalFiles
            completedFiles = snapshot.completedFiles
            failedFiles = snapshot.failedFiles
            currentFileName = snapshot.currentFileName
            lastReportedProgress = snapshot.lastReportedProgress
            // Fall back to backing the count out of the live activity's own state
            // when the snapshot predates this field.
            folderBaseItemCount = FolderItemCountMath.recoveredBase(
                snapshotBase: snapshot.folderBaseItemCount,
                activityDisplayedCount: reattached.content.state.folderItemCount,
                completedFiles: snapshot.completedFiles
            )

            flowLogger.info("🔼 [LIVE ACTIVITY] Reattached id=\(reattached.id, privacy: .public) completed=\(self.completedFiles, privacy: .public)/\(self.totalFiles, privacy: .public) failed=\(self.failedFiles, privacy: .public)")

            // End any other activities that don't match — they're zombies from
            // earlier sessions that were never cleaned up.
            for activity in remainingActivities where activity.id != reattached.id {
                Task { await activity.end(nil, dismissalPolicy: .immediate) }
            }

            // If the counters already say the batch is finished, push the terminal state now — otherwise
            // the manager waits for a `fileCompleted` that never comes.
            if totalFiles > 0, completedFiles + failedFiles >= totalFiles {
                endActivity()
            }
            return
        }

        guard !remainingActivities.isEmpty else {
            clearSnapshot()
            return
        }

        let inFlightMetadata = BackgroundUploadMetadata.loadAll()
        if !inFlightMetadata.isEmpty {
            logger.info("🔼 Found \(remainingActivities.count) Live Activities and \(inFlightMetadata.count) in-flight background uploads but no snapshot — preserving activities")
            return
        }

        logger.info("🔼 Found \(remainingActivities.count) stale Live Activities from previous session — ending them")

        for activity in remainingActivities {
            // Preserves an already-terminal state: a batch suspended mid-hold has no snapshot
            // and looks like a zombie, but it finished.
            let finalState = UploadActivityTerminalState.orphanFinalState(
                existing: activity.content.state
            )
            Task {
                await activity.end(
                    .init(state: finalState, staleDate: nil),
                    dismissalPolicy: .immediate
                )
            }
        }

        currentActivity = nil
        resetState()
        clearSnapshot()
    }

    // MARK: - Snapshot Persistence

    private var snapshotStorageKey: String { Constants.Keys.StorageKeys.uploadLiveActivitySnapshotKey }

    private func persistSnapshot(archiveNo: String? = nil, folderLinkId: Int? = nil) {
        guard let activity = currentActivity else { return }
        let existing = loadSnapshot()
        let snapshot = UploadLiveActivitySnapshot(
            activityId: activity.id,
            totalFiles: totalFiles,
            completedFiles: completedFiles,
            failedFiles: failedFiles,
            currentFileName: currentFileName,
            lastReportedProgress: lastReportedProgress,
            archiveNo: archiveNo ?? existing?.archiveNo ?? activity.attributes.archiveNo,
            folderLinkId: folderLinkId ?? existing?.folderLinkId ?? activity.attributes.folderLinkId,
            folderBaseItemCount: folderBaseItemCount
        )
        if let data = try? JSONEncoder().encode(snapshot) {
            UserDefaults.standard.set(data, forKey: snapshotStorageKey)
        }
    }

    private func loadSnapshot() -> UploadLiveActivitySnapshot? {
        guard let data = UserDefaults.standard.data(forKey: snapshotStorageKey) else { return nil }
        return try? JSONDecoder().decode(UploadLiveActivitySnapshot.self, from: data)
    }

    private func clearSnapshot() {
        UserDefaults.standard.removeObject(forKey: snapshotStorageKey)
    }

    // MARK: - Lifecycle

    func startActivity(
        totalFiles: Int,
        firstFileName: String,
        archiveNo: String = "",
        folderLinkId: Int = 0,
        folderName: String = "",
        folderItemCount: Int? = nil,
        folderIsShared: Bool? = nil
    ) {
        let authInfo = ActivityAuthorizationInfo()
        flowLogger.info("🔼 [LIVE ACTIVITY] startActivity called — areActivitiesEnabled=\(authInfo.areActivitiesEnabled, privacy: .public) totalFiles=\(totalFiles, privacy: .public) currentActivity=\(self.currentActivity != nil, privacy: .public)")

        guard authInfo.areActivitiesEnabled else {
            flowLogger.warning("🔼 [LIVE ACTIVITY] Live Activities are not enabled by the user")
            return
        }

        // A previous batch may still be holding its terminal state for the island. End it now:
        // two live activities would both be shown, and its counts belong to the old batch.
        endFinishingActivityNow()

        // If there's already an active upload session, add to it instead
        if currentActivity != nil {
            addFilesToBatch(count: totalFiles)
            return
        }

        self.totalFiles = totalFiles
        self.completedFiles = 0
        self.failedFiles = 0
        self.currentFileName = firstFileName
        self.currentFileProgress = 0.0
        self.lastPushedProgress = 0.0
        self.lastPushedFileName = ""
        self.folderBaseItemCount = folderItemCount

        let attributes = UploadActivityAttributes(
            sessionStartTime: Date(),
            archiveNo: archiveNo,
            folderLinkId: folderLinkId,
            folderName: folderName,
            folderIsShared: folderIsShared
        )
        let initialState = UploadActivityAttributes.ContentState(
            currentFileIndex: 1,
            totalFiles: totalFiles,
            currentFileName: firstFileName,
            overallProgress: 0.0,
            status: .uploading,
            completedCount: 0,
            failedCount: 0,
            folderItemCount: displayedFolderItemCount
        )

        do {
            currentActivity = try Activity.request(
                attributes: attributes,
                content: .init(state: initialState, staleDate: Date() + staleInterval),
                pushType: nil
            )
            persistSnapshot(archiveNo: archiveNo, folderLinkId: folderLinkId)
            flowLogger.info("🔼 [LIVE ACTIVITY] Started for \(totalFiles, privacy: .public) files, id=\(self.currentActivity?.id ?? "nil", privacy: .public)")
        } catch {
            flowLogger.error("🔼 [LIVE ACTIVITY] Failed to start: \(error.localizedDescription, privacy: .public)")
        }
    }

    func updateProgress(fileInfoId: String, fileName: String, fileIndex: Int, fileProgress: Double) {
        guard currentActivity != nil else { return }

        currentFileName = fileName
        currentFileProgress = fileProgress

        let overallProgress = calculateOverallProgress()

        // Never let displayed progress go backwards — clamp to the high-water mark
        let displayProgress = max(overallProgress, lastReportedProgress)
        lastReportedProgress = displayProgress

        // Skip pushes that wouldn't visibly change the Lock Screen. Moving to a
        // new file and reaching 100% always push; see `minProgressPushDelta`.
        let fileChanged = fileName != lastPushedFileName
        guard fileChanged
                || displayProgress >= 1.0
                || displayProgress - lastPushedProgress >= minProgressPushDelta
        else { return }

        lastPushedProgress = displayProgress
        lastPushedFileName = fileName

        let state = UploadActivityAttributes.ContentState(
            currentFileIndex: min(fileIndex, totalFiles),
            totalFiles: totalFiles,
            currentFileName: fileName,
            overallProgress: displayProgress,
            status: .uploading,
            completedCount: completedFiles,
            failedCount: failedFiles,
            folderItemCount: displayedFolderItemCount
        )

        Task {
            await currentActivity?.update(.init(state: state, staleDate: Date() + staleInterval))
        }
    }

    func fileCompleted(success: Bool) {
        if success {
            completedFiles += 1
        } else {
            failedFiles += 1
        }
        persistSnapshot()

        // Check if all files have been processed
        if completedFiles + failedFiles >= totalFiles {
            // End-of-batch safety net: reconcile the in-flight set against the destination, for files
            // counted failed whose record the server actually has. Counts are corrected before ending.
            UploadManager.shared.verifyInterruptedUploads { [weak self] found, _ in
                guard let self = self else { return }
                if found > 0 {
                    self.completedFiles += found
                    self.failedFiles = max(0, self.failedFiles - found)
                    self.flowLogger.info("🔼 [LIVE ACTIVITY] Verification corrected counts: +\(found, privacy: .public) success, -\(found, privacy: .public) failed")
                }
                self.endActivity()
            }
        } else if isBatchActuallyEmpty() {
            // Self-heal: the counter says unfinished but the pipeline is drained, so a file was filtered
            // out silently. End the activity rather than wait forever.
            flowLogger.info("🔼 [LIVE ACTIVITY] Self-heal — queue and savedFiles empty but counter says \(self.completedFiles, privacy: .public)+\(self.failedFiles, privacy: .public) < \(self.totalFiles, privacy: .public). Forcing end.")
            totalFiles = completedFiles + failedFiles
            endActivity()
        } else {
            let overallProgress = calculateOverallProgress()
            let displayProgress = max(overallProgress, lastReportedProgress)
            lastReportedProgress = displayProgress
            let state = UploadActivityAttributes.ContentState(
                currentFileIndex: completedFiles + failedFiles + 1,
                totalFiles: totalFiles,
                currentFileName: currentFileName,
                overallProgress: displayProgress,
                status: .uploading,
                completedCount: completedFiles,
                failedCount: failedFiles,
                folderItemCount: displayedFolderItemCount
            )
            Task {
                await currentActivity?.update(.init(state: state, staleDate: Date() + staleInterval))
            }
        }
    }

    /// True when no operation is executing and the persisted queue is empty. A safety net for
    /// silent-removal bugs that would otherwise leave the activity waiting forever.
    private func isBatchActuallyEmpty() -> Bool {
        let activeOps = UploadManager.shared.uploadQueue.operations.contains { !$0.isFinished && !$0.isCancelled }
        if activeOps { return false }
        let savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        return savedFiles?.isEmpty != false
    }

    func addFilesToBatch(count: Int) {
        totalFiles += count
        // Rescale the high-water mark against the new total, or a `lastReportedProgress` from a smaller
        // batch locks the bar at an inflated percentage until the real ratio catches up.
        lastReportedProgress = totalFiles > 0
            ? Double(completedFiles) / Double(totalFiles)
            : 0
        persistSnapshot()
        logger.info("🔼 Added \(count) files to batch, new total: \(self.totalFiles)")

        // Update the activity with new totals
        let overallProgress = calculateOverallProgress()
        let state = UploadActivityAttributes.ContentState(
            currentFileIndex: completedFiles + failedFiles + 1,
            totalFiles: totalFiles,
            currentFileName: currentFileName,
            overallProgress: overallProgress,
            status: .uploading,
            completedCount: completedFiles,
            failedCount: failedFiles,
            folderItemCount: displayedFolderItemCount
        )
        Task {
            await currentActivity?.update(.init(state: state, staleDate: Date() + staleInterval))
        }
    }

    func endActivity() {
        guard currentActivity != nil else { return }

        logger.info("🔼 Uploads finished — completed: \(self.completedFiles), failed: \(self.failedFiles)")

        endWithFinalStatus(failedFiles > 0 ? .failed : .completed)
    }

    private func endWithFinalStatus(_ status: UploadActivityAttributes.UploadStatus) {
        guard let activity = currentActivity else { return }

        let finalState = UploadActivityAttributes.ContentState(
            currentFileIndex: totalFiles,
            totalFiles: totalFiles,
            currentFileName: "",
            overallProgress: 1.0,
            status: status,
            completedCount: completedFiles,
            failedCount: failedFiles,
            folderItemCount: displayedFolderItemCount
        )

        let dismissDelay: TimeInterval = status == .completed ? 120 : 30
        let hold = completionHoldInterval

        // Park the activity in the finishing slot and clear live state FIRST, so a new upload
        // arriving during the hold finds an idle manager and a reference it can dispose of.
        endFinishingActivityNow()
        finishingActivity = activity
        currentActivity = nil
        resetState()

        Task { [weak self] in
            // Keep it active so the island can render the terminal state. The staleDate covers
            // iOS suspending us before the `end` below runs.
            await activity.update(
                .init(state: finalState, staleDate: Date().addingTimeInterval(hold + 30))
            )
            try? await Task.sleep(for: .seconds(hold))
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .after(Date().addingTimeInterval(dismissDelay))
            )
            await MainActor.run { self?.releaseFinishingActivity(activity) }
        }
    }

    /// Ends a held terminal-state activity right now. Called when a new batch starts, so the
    /// previous batch's checkmark never sits alongside a fresh upload.
    private func endFinishingActivityNow() {
        guard let activity = finishingActivity else { return }
        finishingActivity = nil
        logger.info("🔼 Ending held terminal activity early — a new batch is starting")
        Task { await activity.end(nil, dismissalPolicy: .immediate) }
    }

    /// Clears the slot only if it still holds this activity; a newer batch may already have
    /// replaced it via `endFinishingActivityNow()`.
    private func releaseFinishingActivity(_ activity: Activity<UploadActivityAttributes>) {
        if finishingActivity?.id == activity.id {
            finishingActivity = nil
        }
    }

    func cancelActivity() {
        // A cancel should clear any held terminal state too — the user asked for it gone.
        endFinishingActivityNow()

        guard let activity = currentActivity else { return }

        logger.info("🔼 Cancelling upload Live Activity")

        Task {
            await activity.end(nil, dismissalPolicy: .immediate)
        }

        currentActivity = nil
        resetState()
    }

    func fileCancelled() {
        guard totalFiles > 1 else {
            cancelActivity()
            return
        }

        totalFiles -= 1
        persistSnapshot()

        // Check if all remaining files have been processed
        if completedFiles + failedFiles >= totalFiles {
            endActivity()
        }
    }

    // MARK: - Foreground Resume

    @objc private func appWillEnterForeground() {
        dismissEndedActivities()

        guard currentActivity != nil else { return }

        // Refresh the Live Activity with current state and a new stale date
        // so it immediately recovers from any stale appearance.
        let overallProgress = calculateOverallProgress()
        let displayProgress = max(overallProgress, lastReportedProgress)
        lastReportedProgress = displayProgress

        let state = UploadActivityAttributes.ContentState(
            currentFileIndex: completedFiles + failedFiles + 1,
            totalFiles: totalFiles,
            currentFileName: currentFileName,
            overallProgress: displayProgress,
            status: .uploading,
            completedCount: completedFiles,
            failedCount: failedFiles,
            folderItemCount: displayedFolderItemCount
        )

        logger.info("🔼 App entering foreground — refreshing Live Activity state")
        Task {
            await currentActivity?.update(.init(state: state, staleDate: Date() + staleInterval))
        }
    }

    private func dismissEndedActivities() {
        let activities = Activity<UploadActivityAttributes>.activities
        for activity in activities where activity.activityState == .ended {
            logger.info("🔼 Dismissing ended Live Activity on foreground")
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
            }
        }
    }

    // MARK: - Private

    private func calculateOverallProgress() -> Double {
        guard totalFiles > 0 else { return 0.0 }

        // Cap below 100% while any file is in flight: a file whose bytes are all uploaded isn't done
        // until its registration lands, and "100%" beside "3 of 4" looks finished when it isn't.
        let processed = completedFiles + failedFiles
        guard processed < totalFiles else { return 1.0 }

        let raw = (Double(completedFiles) + currentFileProgress) / Double(totalFiles)
        return min(raw, 0.99)
    }

    private func resetState() {
        totalFiles = 0
        completedFiles = 0
        failedFiles = 0
        currentFileName = ""
        currentFileProgress = 0.0
        lastReportedProgress = 0.0
        lastPushedProgress = 0.0
        lastPushedFileName = ""
        folderBaseItemCount = nil
        clearSnapshot()
    }
}
