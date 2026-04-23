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
    private var currentActivity: Activity<UploadActivityAttributes>?

    // Tracking state
    private var totalFiles: Int = 0
    private var completedFiles: Int = 0
    private var failedFiles: Int = 0
    private var currentFileName: String = ""
    private var currentFileProgress: Double = 0.0
    private var lastReportedProgress: Double = 0.0
    private var isPaused: Bool = false

    /// Timer that monitors background time remaining to pause the activity before suspension.
    private var backgroundTimer: Timer?

    /// Whether a Live Activity is currently active.
    var isActive: Bool { currentActivity != nil }

    /// How long after the last update before iOS marks the activity as stale.
    /// If the app is force-quit, after this interval the widget shows "Upload interrupted".
    private let staleInterval: TimeInterval = 60

    private init() {
        NotificationCenter.default.addObserver(
            self, selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification, object: nil
        )
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
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            logger.warning("Live Activities are not enabled by the user")
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
            logger.info("Started upload Live Activity for \(totalFiles) files")
        } catch {
            logger.error("Failed to start Live Activity: \(error.localizedDescription)")
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
            logger.debug("File completed successfully (\(self.completedFiles)/\(self.totalFiles))")
        } else {
            failedFiles += 1
            logger.debug("File failed (\(self.failedFiles) failures)")
        }

        // Check if all files have been processed
        if completedFiles + failedFiles >= totalFiles {
            endActivity()
        } else {
            // Update the activity with new counts
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
        guard let activity = currentActivity else { return }

        let finalStatus: UploadActivityAttributes.UploadStatus = failedFiles > 0 ? .failed : .completed

        let finalState = UploadActivityAttributes.ContentState(
            currentFileIndex: totalFiles,
            totalFiles: totalFiles,
            currentFileName: "",
            overallProgress: 1.0,
            status: finalStatus,
            completedCount: completedFiles,
            failedCount: failedFiles
        )

        logger.info("Ending Live Activity — completed: \(self.completedFiles), failed: \(self.failedFiles)")

        Task {
            await activity.end(
                .init(state: finalState, staleDate: nil),
                dismissalPolicy: .after(.now + 30)
            )
        }

        currentActivity = nil
        resetState()
    }

    func cancelActivity() {
        guard let activity = currentActivity else { return }

        logger.info("Cancelling upload Live Activity")

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

    // MARK: - Background / Foreground

    @objc private func appDidEnterBackground() {
        guard currentActivity != nil, !isPaused else { return }

        logger.info("App entered background — starting background time monitor")
        backgroundTimer?.invalidate()
        backgroundTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkBackgroundTimeRemaining()
        }
    }

    @objc private func appWillEnterForeground() {
        backgroundTimer?.invalidate()
        backgroundTimer = nil

        guard isPaused, currentActivity != nil else { return }
        logger.info("App entering foreground — resuming Live Activity")
        resumeActivity()
    }

    private func checkBackgroundTimeRemaining() {
        // Access UIApplication.shared indirectly to avoid compile errors in extension targets
        let selector = NSSelectorFromString("sharedApplication")
        guard UIApplication.responds(to: selector),
              let app = UIApplication.perform(selector)?.takeUnretainedValue() as? UIApplication else { return }

        let remaining = app.backgroundTimeRemaining
        logger.debug("Background time remaining: \(remaining, privacy: .public)s")

        if remaining < 5 {
            backgroundTimer?.invalidate()
            backgroundTimer = nil
            pauseActivity()
        }
    }

    private func pauseActivity() {
        guard let currentActivity, !isPaused else { return }
        isPaused = true

        let displayProgress = lastReportedProgress
        let state = UploadActivityAttributes.ContentState(
            currentFileIndex: completedFiles + failedFiles + 1,
            totalFiles: totalFiles,
            currentFileName: currentFileName,
            overallProgress: displayProgress,
            status: .paused,
            completedCount: completedFiles,
            failedCount: failedFiles
        )

        logger.info("Pausing Live Activity — background time almost expired")
        Task {
            await currentActivity.update(.init(state: state, staleDate: Date() + staleInterval))
        }
    }

    private func resumeActivity() {
        guard currentActivity != nil, isPaused else { return }
        isPaused = false

        let displayProgress = lastReportedProgress
        let state = UploadActivityAttributes.ContentState(
            currentFileIndex: completedFiles + failedFiles + 1,
            totalFiles: totalFiles,
            currentFileName: currentFileName,
            overallProgress: displayProgress,
            status: .uploading,
            completedCount: completedFiles,
            failedCount: failedFiles
        )

        logger.info("Resuming Live Activity")
        Task {
            await currentActivity?.update(.init(state: state, staleDate: Date() + staleInterval))
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
        isPaused = false
        backgroundTimer?.invalidate()
        backgroundTimer = nil
    }
}
