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

    /// Timer for the server processing phase after uploads complete.
    private var processingTimer: Timer?

    /// Whether a Live Activity is currently active.
    var isActive: Bool { currentActivity != nil }

    /// Whether any upload Live Activity is visible on the Lock Screen (active or recently ended).
    /// Ended activities remain visible for up to 30 seconds before iOS removes them.
    var hasVisibleActivity: Bool {
        return !Activity<UploadActivityAttributes>.activities.isEmpty
    }

    /// How long after the last update before iOS marks the activity as stale.
    /// With background URLSession, S3 uploads continue even when the app is
    /// suspended, so we use a generous interval. The activity will be updated
    /// each time a background upload task completes and wakes the app.
    private let staleInterval: TimeInterval = 600

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification, object: nil
        )
    }

    // MARK: - Stale Activity Cleanup

    /// Call on app launch to end any Live Activities orphaned by a previous force-quit.
    /// When the app is killed, in-memory state is lost but the Live Activity persists
    /// on the Lock Screen. This method finds and ends those stale activities.
    func cleanupStaleActivities() {
        let runningActivities = Activity<UploadActivityAttributes>.activities
        guard !runningActivities.isEmpty else { return }

        logger.info("Found \(runningActivities.count) stale Live Activities from previous session — ending them")

        for activity in runningActivities {
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

        // Reset any leftover in-memory state
        currentActivity = nil
        resetState()
    }

    // MARK: - Lifecycle

    func startActivity(totalFiles: Int, firstFileName: String, archiveNo: String = "", folderLinkId: Int = 0) {
        let authInfo = ActivityAuthorizationInfo()
        flowLogger.info("[LIVE ACTIVITY] startActivity called — areActivitiesEnabled=\(authInfo.areActivitiesEnabled, privacy: .public) totalFiles=\(totalFiles, privacy: .public) currentActivity=\(self.currentActivity != nil, privacy: .public)")

        guard authInfo.areActivitiesEnabled else {
            flowLogger.warning("[LIVE ACTIVITY] Live Activities are not enabled by the user")
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
            flowLogger.info("[LIVE ACTIVITY] Started for \(totalFiles, privacy: .public) files, id=\(self.currentActivity?.id ?? "nil", privacy: .public)")
        } catch {
            flowLogger.error("[LIVE ACTIVITY] Failed to start: \(error.localizedDescription, privacy: .public)")
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
            flowLogger.info("[LIVE ACTIVITY] fileCompleted success (\(self.completedFiles)/\(self.totalFiles)) isActive=\(self.isActive, privacy: .public)")
        } else {
            failedFiles += 1
            flowLogger.info("[LIVE ACTIVITY] fileCompleted failed (\(self.failedFiles) failures) isActive=\(self.isActive, privacy: .public)")
        }

        // Check if all files have been processed
        if completedFiles + failedFiles >= totalFiles {
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

    func addFilesToBatch(count: Int) {
        processingTimer?.invalidate()
        processingTimer = nil
        totalFiles += count
        logger.info("Added \(count) files to batch, new total: \(self.totalFiles)")

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

        logger.info("Uploads finished — completed: \(self.completedFiles), failed: \(self.failedFiles)")

        if failedFiles > 0 {
            endWithFinalStatus(.failed)
        } else {
            showProcessingState()
        }
    }

    private var processingStartTime: Date?
    private var processingDuration: TimeInterval = 0

    private func showProcessingState() {
        processingDuration = completedFiles > 10 ? 30 : TimeInterval(max(completedFiles, 1) * 3)
        processingStartTime = Date()
        logger.info("Showing processing state for \(self.processingDuration, privacy: .public) seconds (\(self.completedFiles) files)")

        let state = UploadActivityAttributes.ContentState(
            currentFileIndex: totalFiles,
            totalFiles: totalFiles,
            currentFileName: "",
            overallProgress: 0.0,
            status: .processing,
            completedCount: completedFiles,
            failedCount: failedFiles
        )

        Task {
            await currentActivity?.update(.init(state: state, staleDate: Date() + staleInterval))
        }

        processingTimer?.invalidate()
        processingTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.tickProcessingProgress()
        }
    }

    private func tickProcessingProgress() {
        guard let start = processingStartTime, currentActivity != nil else { return }

        let elapsed = Date().timeIntervalSince(start)
        let progress = min(elapsed / processingDuration, 1.0)

        if progress >= 1.0 {
            processingTimer?.invalidate()
            processingTimer = nil
            endWithFinalStatus(.completed)
            return
        }

        let state = UploadActivityAttributes.ContentState(
            currentFileIndex: totalFiles,
            totalFiles: totalFiles,
            currentFileName: "",
            overallProgress: progress,
            status: .processing,
            completedCount: completedFiles,
            failedCount: failedFiles
        )

        Task {
            await currentActivity?.update(.init(state: state, staleDate: Date() + staleInterval))
        }
    }

    private func endWithFinalStatus(_ status: UploadActivityAttributes.UploadStatus) {
        guard let activity = currentActivity else { return }

        processingTimer?.invalidate()
        processingTimer = nil

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

        logger.info("Cancelling upload Live Activity")
        processingTimer?.invalidate()
        processingTimer = nil

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

        // Check if all remaining files have been processed
        if completedFiles + failedFiles >= totalFiles {
            endActivity()
        }
    }

    // MARK: - Foreground Resume

    @objc private func appWillEnterForeground() {
        dismissEndedActivities()

        if processingTimer != nil, let start = processingStartTime {
            let elapsed = Date().timeIntervalSince(start)
            if elapsed >= processingDuration {
                logger.info("Processing timer expired while suspended — ending activity")
                processingTimer?.invalidate()
                processingTimer = nil
                endWithFinalStatus(.completed)
                return
            } else {
                tickProcessingProgress()
            }
        }

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

        logger.info("App entering foreground — refreshing Live Activity state")
        Task {
            await currentActivity?.update(.init(state: state, staleDate: Date() + staleInterval))
        }
    }

    private func dismissEndedActivities() {
        let activities = Activity<UploadActivityAttributes>.activities
        for activity in activities where activity.activityState == .ended {
            logger.info("Dismissing ended Live Activity on foreground")
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
        processingStartTime = nil
        processingDuration = 0
        processingTimer?.invalidate()
        processingTimer = nil
    }
}
