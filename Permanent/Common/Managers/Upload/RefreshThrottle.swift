//
//  RefreshThrottle.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.08.2026.
//

import Foundation

/// Leading-edge throttle for `UploadManager.refreshQueue()`.
///
/// `refreshQueue` is called from a 30 s timer, from foregrounding, from `upload(files:)` and
/// from every upload-failure handler. That last caller is why this exists: a transient
/// network failure re-queues immediately, and offline those failures return in microseconds,
/// so the handler → `refreshQueue` → new operation → handler cycle spins as fast as the CPU
/// allows. Each turn re-archives the whole queue to UserDefaults and reads it back, so it is
/// a disk storm, not just CPU. See [[offline-upload-retry-spin]].
///
/// **Leading edge, not trailing:** the first request runs immediately, so starting an upload
/// or foregrounding stays as responsive as before. Only requests arriving inside
/// `minInterval` are held, and they collapse into a single catch-up run rather than queueing
/// up one per call.
///
/// Pure and clock-injected so it can be tested without timing flakiness — the manager it
/// serves is a singleton wired to a `Timer` and `NWPathMonitor`, none of which a unit test
/// can drive.
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

        // Everything else waits — including a nonsensical negative `elapsed`, which would
        // mean `lastRunAt` is somehow in the future. This guard **fails closed** on purpose:
        // the whole job of this type is to stop a spin, so when the clock makes no sense the
        // safe answer is to throttle, never to run free. An earlier version returned
        // `.runNow` there and a test proved it degraded to no throttling at all.
        // The delay is clamped so a future `lastRunAt` cannot produce an unbounded wait.
        isRunPending = true
        return .schedule(after: min(minInterval, max(0, minInterval - elapsed)))
    }

    /// Call when a scheduled catch-up run actually fires, before doing the work.
    mutating func pendingRunFired(now: TimeInterval) {
        isRunPending = false
        lastRunAt = now
    }
}
