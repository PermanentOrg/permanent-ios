//
//  RefreshThrottle.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.08.2026.
//

import Foundation

/// Leading-edge throttle for `UploadManager.refreshQueue()`, whose failure-handler caller
/// re-queues immediately and spins with no route. Clock-injected so it is testable.
struct RefreshThrottle {
    /// What the caller should do with this request.
    enum Decision: Equatable {
        /// Run the work now.
        case runNow
        /// Nothing is scheduled yet; run the work again after this delay.
        case schedule(after: TimeInterval)
        /// A catch-up run is already pending — drop this request entirely.
        case alreadyScheduled
    }

    let minInterval: TimeInterval

    private var lastRunAt: TimeInterval?
    private var isRunPending = false

    init(minInterval: TimeInterval = 1.0) {
        self.minInterval = minInterval
    }

    /// Ask what to do with a refresh request arriving at `now` (a monotonic clock reading,
    /// e.g. `ProcessInfo.processInfo.systemUptime`).
    mutating func request(now: TimeInterval) -> Decision {
        // A pending catch-up already covers this request; more calls add nothing.
        if isRunPending { return .alreadyScheduled }

        guard let lastRunAt else {
            lastRunAt = now
            return .runNow
        }

        let elapsed = now - lastRunAt
        if elapsed >= minInterval {
            self.lastRunAt = now
            return .runNow
        }

        // Fails closed on a negative `elapsed`: this type exists to stop a spin, so a clock
        // that makes no sense must throttle, never run free. Delay clamped for the same reason.
        isRunPending = true
        return .schedule(after: min(minInterval, max(0, minInterval - elapsed)))
    }

    /// Call when a scheduled catch-up run actually fires, before doing the work.
    mutating func pendingRunFired(now: TimeInterval) {
        isRunPending = false
        lastRunAt = now
    }
}
