//
//  BackgroundUploadDrainTask.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.05.2026.
//
//  Wraps `BGTaskScheduler` so iOS can wake the app and let `UploadManager`
//  keep draining the queue after the foreground `beginBackgroundTask` budget
//  has expired. This is a safety net, not a substitute for background
//  URLSession — wakes are opportunistic and per-wake budgets are short.
//

import BackgroundTasks
import os.log

enum BackgroundUploadDrainTask {
    static let identifier = "org.permanent.iOS.upload.drain"

    private static let logger = Logger(subsystem: "com.permanent.ios", category: "BGDrain")

    /// Call once from `AppDelegate.application(_:didFinishLaunchingWithOptions:)`.
    /// iOS requires registration during launch or it won't deliver wakes.
    static func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: identifier, using: nil) { task in
            guard let processingTask = task as? BGProcessingTask else {
                task.setTaskCompleted(success: false)
                return
            }
            handle(task: processingTask)
        }
        logger.info("🔼 [BG-DRAIN] registered identifier=\(identifier, privacy: .public)")
    }

    /// Submits a wake request, on backgrounding and after any upload that leaves work pending, so iOS
    /// always has one queued while there is something to drain.
    static func schedule() {
        guard UploadManager.shared.hasPendingWork else {
            logger.info("🔼 [BG-DRAIN] queue empty — not scheduling")
            return
        }

        let request = BGProcessingTaskRequest(identifier: identifier)
        request.requiresNetworkConnectivity = true
        request.requiresExternalPower = false
        request.earliestBeginDate = nil

        do {
            try BGTaskScheduler.shared.submit(request)
            logger.info("🔼 [BG-DRAIN] submitted request")
        } catch {
            logger.warning("🔼 [BG-DRAIN] submit failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Pull any pending requests when the queue empties so iOS doesn't wake
    /// us for no-op work later.
    static func cancel() {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier)
        logger.info("🔼 [BG-DRAIN] cancelled pending requests")
    }

    private static func handle(task: BGProcessingTask) {
        logger.info("🔼 [BG-DRAIN] OS handed us a drain task")

        // Atomic flag so the expirationHandler and the polling loop don't both
        // race to call setTaskCompleted.
        let completed = DispatchSemaphore(value: 1)
        var isCompleted = false
        let complete: (Bool) -> Void = { success in
            completed.wait()
            defer { completed.signal() }
            guard !isCompleted else { return }
            isCompleted = true
            schedule()
            task.setTaskCompleted(success: success)
        }

        // Hard backstop: if iOS reclaims our budget, re-submit + bail.
        task.expirationHandler = {
            logger.warning("🔼 [BG-DRAIN] expirationHandler fired — OS reclaiming budget")
            complete(false)
        }

        // Kick the queue. UploadOperation wraps each file in its own
        // `beginBackgroundTask`, so per-file work composes within the wake.
        UploadManager.shared.refreshQueue()

        // Poll until the queue is idle, capped well below the budget so the next wake resumes rather than
        // the process suspending mid-call, which would orphan the task and risk a duplicate record.
        DispatchQueue.global(qos: .background).async {
            let deadline = Date().addingTimeInterval(25)
            while Date() < deadline {
                let hasInFlight = UploadManager.shared.uploadQueue.operations.contains { !$0.isFinished }
                if !hasInFlight {
                    logger.info("🔼 [BG-DRAIN] queue idle — completing")
                    complete(true)
                    return
                }
                Thread.sleep(forTimeInterval: 1.0)
            }
            logger.info("🔼 [BG-DRAIN] soft window elapsed with in-flight ops — re-scheduling and completing")
            complete(true)
        }
    }
}
