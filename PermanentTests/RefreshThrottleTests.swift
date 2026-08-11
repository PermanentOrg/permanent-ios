//
//  RefreshThrottleTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.08.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The throttle that stops `UploadManager.refreshQueue()` spinning. The bug it exists for:
/// offline, upload API calls fail in microseconds, transient failures are exempt from the
/// retry cap, and the failure handler re-queued immediately — a tight loop that re-archived
/// the whole queue to UserDefaults every turn and warmed the device.
///
/// Clock is injected, so none of this is timing-dependent.
struct RefreshThrottleTests {

    /// `Decision` carries a `TimeInterval`, so exact equality is the wrong tool —
    /// `minInterval - elapsed` lands on values like 0.9000000000000057.
    private func expectSchedule(
        _ decision: RefreshThrottle.Decision,
        after expected: TimeInterval,
        _ comment: Comment? = nil,
        sourceLocation: SourceLocation = #_sourceLocation
    ) {
        guard case .schedule(let actual) = decision else {
            Issue.record("expected .schedule(after: \(expected)), got \(decision)", sourceLocation: sourceLocation)
            return
        }
        #expect(abs(actual - expected) < 0.0001, comment, sourceLocation: sourceLocation)
    }

    // MARK: - Leading edge

    @Test("The very first request runs immediately")
    func firstRequestRunsNow() {
        var t = RefreshThrottle(minInterval: 1.0)
        #expect(t.request(now: 100) == .runNow)
    }

    @Test("A request after the interval has passed runs immediately")
    func requestAfterIntervalRunsNow() {
        var t = RefreshThrottle(minInterval: 1.0)
        _ = t.request(now: 100)
        #expect(t.request(now: 101) == .runNow, "exactly at the boundary still runs")
        #expect(t.request(now: 105) == .runNow)
    }

    // MARK: - Collapsing a storm

    @Test("A request inside the interval is scheduled for the remainder")
    func requestInsideIntervalIsScheduled() {
        var t = RefreshThrottle(minInterval: 1.0)
        _ = t.request(now: 100)
        expectSchedule(t.request(now: 100.25), after: 0.75)
    }

    @Test("A burst collapses into exactly one scheduled run")
    func burstCollapsesToOneRun() {
        var t = RefreshThrottle(minInterval: 1.0)
        #expect(t.request(now: 100) == .runNow)

        // This is the spin: the failure handler calling back as fast as the CPU allows.
        var scheduled = 0
        var dropped = 0
        for i in 1...10_000 {
            switch t.request(now: 100 + Double(i) * 0.00001) {
            case .schedule: scheduled += 1
            case .alreadyScheduled: dropped += 1
            case .runNow: Issue.record("nothing in a 0.1s burst may run immediately")
            }
        }
        #expect(scheduled == 1, "10,000 calls must produce exactly one catch-up run")
        #expect(dropped == 9_999)
    }

    @Test("After the pending run fires, the throttle re-arms")
    func rearmsAfterPendingRunFires() {
        var t = RefreshThrottle(minInterval: 1.0)
        _ = t.request(now: 100)
        expectSchedule(t.request(now: 100.5), after: 0.5)
        #expect(t.request(now: 100.6) == .alreadyScheduled)

        t.pendingRunFired(now: 101)

        // A fresh burst is throttled again rather than running free.
        expectSchedule(t.request(now: 101.1), after: 0.9)
    }

    @Test("Work still happens eventually — a sustained storm yields steady runs, not silence")
    func sustainedStormStillMakesProgress() {
        var t = RefreshThrottle(minInterval: 1.0)
        var runs = 0
        var now = 100.0
        var pendingFireAt: TimeInterval?

        // 10 seconds of continuous requests at 0.01s intervals. The pending run fires when
        // the simulated clock actually reaches it — advancing `lastRunAt` into the future
        // instead (an earlier version of this test) is not what production does.
        while now < 110 {
            if let fireAt = pendingFireAt, now >= fireAt {
                t.pendingRunFired(now: now)
                pendingFireAt = nil
                runs += 1
            }
            switch t.request(now: now) {
            case .runNow:
                runs += 1
            case .schedule(let delay):
                pendingFireAt = now + delay
            case .alreadyScheduled:
                break
            }
            now += 0.01
        }
        // ~1 run per second, not ~1000. The upper bound is what matters.
        #expect(runs <= 12, "a 10s storm must not exceed roughly one run per second, got \(runs)")
        #expect(runs >= 8, "and must not stall out either, got \(runs)")
    }

    // MARK: - Clock robustness

    @Test("A clock that appears to move backwards throttles rather than running free")
    func backwardsClockFailsClosed() {
        var t = RefreshThrottle(minInterval: 1.0)
        _ = t.request(now: 500)
        // Fail CLOSED: throttling on a nonsensical clock is safe, running is not — this type
        // exists to stop a spin. The delay is clamped to minInterval, never negative or huge.
        expectSchedule(t.request(now: 100), after: 1.0, "must not degrade to no throttling")
    }

    @Test("A zero interval never throttles")
    func zeroIntervalNeverThrottles() {
        var t = RefreshThrottle(minInterval: 0)
        #expect(t.request(now: 100) == .runNow)
        #expect(t.request(now: 100) == .runNow)
    }
}
