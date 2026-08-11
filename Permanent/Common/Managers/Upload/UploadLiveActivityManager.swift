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
    /// The destination folder's item count when the batch started; completed files
    /// are added on top of it for display. Optional so a snapshot written by an
    /// older build still decodes, instead of forcing the activity to be treated as
    /// orphaned on the next launch. The folder's name and access level need no
    /// field here — they're immutable, so they come back off `activity.attributes`.
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

    // Destination folder detail, shown on the Live Activity's folder card. Set once
    // when the batch starts and carried through every content update. `nil` when the
    // caller couldn't tell us — the Share Extension never lists the destination.
    private var folderBaseItemCount: Int?

    /// Item count to display: what the folder held when the batch started, plus
    /// everything that has landed since. The design shows this live. Stays `nil` when
    /// the base count is unknown, so the card omits it rather than undercount.
    /// Arithmetic lives in `FolderItemCountMath` so it can be unit-tested — nothing here
    /// is reachable from a test.
    private var displayedFolderItemCount: Int? {
        FolderItemCountMath.displayed(base: folderBaseItemCount, completedFiles: completedFiles)
    }

    /// Throttle for `activity.update` pushes. `updateProgress` runs on every
    /// URLSession progress callback — hundreds of times for a single large file —
    /// and ActivityKit budgets updates per app, so pushing all of them risks iOS
    /// silently throttling the activity and freezing the Lock Screen mid-upload.
    /// A whole percent is the finest change the UI can actually render, so
    /// anything smaller is spent budget for no visible gain. A change of file
    /// always pushes, so the displayed name never lags behind the bytes.
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

    /// How long a finished batch stays **active** so the Dynamic Island can show its terminal
    /// state — the green ring + checkmark for completed, red + exclamation for failed.
    ///
    /// Ended activities are dropped from the island almost immediately, so the previous code
    /// (which called `end()` the instant the last file finished) built a correct completed
    /// presentation that could never be seen: the island just vanished. The `.after(...)`
    /// dismissal policy does not help — it governs how long the *Lock Screen* banner lingers.
    private let completionHoldInterval: TimeInterval = 4

    /// A batch that has been updated to its terminal state and is waiting out
    /// `completionHoldInterval` before being ended.
    ///
    /// Deliberately separate from `currentActivity`: during the hold the manager must look
    /// idle, so a new upload starts a fresh activity rather than adding files to a finished
    /// one — but the reference has to survive so `startActivity` can end it and avoid two
    /// live activities at once.
    private var finishingActivity: Activity<UploadActivityAttributes>?

    /// How long after the last update before iOS marks the activity as stale.
    /// Matched to iOS's ~30s `beginBackgroundTask` budget: once the app gets
    /// suspended, no more updates can land, so the LA goes stale almost
    /// immediately and accurately shows "Upload Paused — tap to resume". When
    /// the app is foregrounded again, the staleDate refreshes on the next
    /// progress callback and the LA returns to its active state.
    private let staleInterval: TimeInterval = 30

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    // MARK: - Launch Reconciliation

    /// Call on app launch to either reattach to a Live Activity from a previous
    /// session or end orphans that no longer correspond to in-flight uploads.
    ///
    /// Three cases:
    /// 1. We have a persisted snapshot AND a matching running activity → reattach.
    ///    In-memory counters are restored so `fileCompleted`/`updateProgress` from
    ///    background URLSession callbacks keep the Live Activity in sync.
    /// 2. No snapshot, but `BackgroundUploadMetadata` shows in-flight uploads →
    ///    leave the activities alone. We can't update them (no counter state) but
    ///    they stay visible until uploads finish or iOS marks them stale.
    /// 3. No snapshot AND no in-flight metadata → truly orphaned, end them.
    func reconcileOnLaunch() {
        let runningActivities = Activity<UploadActivityAttributes>.activities
        let snapshot = loadSnapshot()

        // One-shot migration cleanup: any activity stuck in `.processing` is a
        // leftover from the old processing-timer code path. By the time an
        // activity reaches `.processing`, all files have already completed, so
        // flip it straight to `.completed` and let it dismiss.
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

            // If counters already say the batch is finished, push the LA to its
            // terminal state now — without this, the manager would sit waiting
            // for a fileCompleted call that never comes.
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
            // Preserves an already-terminal state: a batch suspended mid-completion-hold has
            // no snapshot and looks like a zombie, but it finished. See
            // `UploadActivityTerminalState`.
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
            // End-of-batch safety net: walk the Phase 3 in-flight set and
            // reconcile against the destination folder. Catches the case where
            // both the original registerRecord AND its inline Guard-B
            // navigateMin retry were network-blocked, leaving a file counted
            // as "failed" here even though the server actually has the
            // record. We adjust counts before ending the activity so the
            // user sees the corrected numbers.
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
            // Self-heal: counter says we're not done, but the upload pipeline
            // is fully drained. Some file was silently filtered out somewhere
            // without notifying us. End the activity rather than wait forever.
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

    /// True when there are no executing upload operations AND no files left
    /// in the persisted upload queue. Used as a safety net to recover from
    /// silent-removal bugs that would otherwise leave the LA waiting forever.
    private func isBatchActuallyEmpty() -> Bool {
        let activeOps = UploadManager.shared.uploadQueue.operations.contains { !$0.isFinished && !$0.isCancelled }
        if activeOps { return false }
        let savedFiles: [FileInfo]? = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey)
        return savedFiles?.isEmpty != false
    }

    func addFilesToBatch(count: Int) {
        totalFiles += count
        // Rescale the high-water mark against the new total. Without this,
        // an old `lastReportedProgress` from a smaller batch would lock the
        // progress bar at an inflated percentage (e.g. 37%) until the actual
        // ratio catches up.
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
            // Keep it ACTIVE and show the terminal state — this is the part the island can
            // render. The staleDate covers the case where iOS suspends us before the `end`
            // below ever runs: the banner then reads as stale instead of sitting there looking
            // like a fresh completion indefinitely.
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

        // The batch is only ever 100% once every file has actually finished
        // (completed or failed). A file whose *bytes* have all uploaded isn't
        // "done" until its server-side registration lands — so while any file is
        // still in flight we cap below 100%. Without this, the current file's
        // byte progress fills its slot to 1.0 and the bar reads "100%" next to
        // e.g. "3 of 4", which looks finished while the upload is still working.
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
