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

    /// Whether a Live Activity is currently active.
    var isActive: Bool { currentActivity != nil }

    /// Whether any upload Live Activity is visible on the Lock Screen (active or recently ended).
    /// Ended activities remain visible for up to 30 seconds before iOS removes them.
    var hasVisibleActivity: Bool {
        return !Activity<UploadActivityAttributes>.activities.isEmpty
    }

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
                failedCount: activity.content.state.failedCount
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
            let finalState = UploadActivityAttributes.ContentState(
                currentFileIndex: 0,
                totalFiles: 0,
                currentFileName: "",
                overallProgress: 0.0,
                status: .failed,
                completedCount: 0,
                failedCount: 0
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
            folderLinkId: folderLinkId ?? existing?.folderLinkId ?? activity.attributes.folderLinkId
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

    func startActivity(totalFiles: Int, firstFileName: String, archiveNo: String = "", folderLinkId: Int = 0) {
        let authInfo = ActivityAuthorizationInfo()
        flowLogger.info("🔼 [LIVE ACTIVITY] startActivity called — areActivitiesEnabled=\(authInfo.areActivitiesEnabled, privacy: .public) totalFiles=\(totalFiles, privacy: .public) currentActivity=\(self.currentActivity != nil, privacy: .public)")

        guard authInfo.areActivitiesEnabled else {
            flowLogger.warning("🔼 [LIVE ACTIVITY] Live Activities are not enabled by the user")
            return
        }

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

        let attributes = UploadActivityAttributes(sessionStartTime: Date(), archiveNo: archiveNo, folderLinkId: folderLinkId)
        let initialState = UploadActivityAttributes.ContentState(
            currentFileIndex: 1,
            totalFiles: totalFiles,
            currentFileName: firstFileName,
            overallProgress: 0.0,
            status: .uploading,
            completedCount: 0,
            failedCount: 0
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

        let state = UploadActivityAttributes.ContentState(
            currentFileIndex: min(fileIndex, totalFiles),
            totalFiles: totalFiles,
            currentFileName: fileName,
            overallProgress: displayProgress,
            status: .uploading,
            completedCount: completedFiles,
            failedCount: failedFiles
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
                failedCount: failedFiles
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
            failedCount: failedFiles
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
            failedCount: failedFiles
        )

        let dismissDelay: TimeInterval = status == .completed ? 120 : 30
        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .after(Date().addingTimeInterval(dismissDelay))
            )
        }

        currentActivity = nil
        resetState()
    }

    func cancelActivity() {
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
            failedCount: failedFiles
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
        return min((Double(completedFiles) + currentFileProgress) / Double(totalFiles), 1.0)
    }

    private func resetState() {
        totalFiles = 0
        completedFiles = 0
        failedFiles = 0
        currentFileName = ""
        currentFileProgress = 0.0
        lastReportedProgress = 0.0
        clearSnapshot()
    }
}
