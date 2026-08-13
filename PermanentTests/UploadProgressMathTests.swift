//
//  UploadProgressMathTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.08.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The ceiling holds the bar below 100% while a file is still registering. These pin when it
/// applies, and when the remaining gap means work rather than a stall.
struct UploadProgressMathTests {

    private func approx(_ a: Double, _ b: Double, _ location: SourceLocation = #_sourceLocation) {
        #expect(abs(a - b) < 0.0001, "\(a) != \(b)", sourceLocation: location)
    }

    // MARK: - displayed

    @Test("Mid-batch progress is byte-weighted across the whole batch")
    func displayedIsByteWeighted() {
        approx(UploadProgressMath.displayed(
            completedFiles: 2, failedFiles: 0, currentFileProgress: 0.5, totalFiles: 6
        ), 2.5 / 6)
    }

    @Test("The last file's bytes landing holds the bar at the ceiling, not 100%")
    func displayedHoldsAtCeiling() {
        // 5 registered, the 6th fully uploaded but not yet registered.
        approx(UploadProgressMath.displayed(
            completedFiles: 5, failedFiles: 0, currentFileProgress: 1.0, totalFiles: 6
        ), UploadProgressMath.inFlightCeiling)
    }

    @Test("100% only once every file is accounted for")
    func displayedReachesOneWhenAllProcessed() {
        approx(UploadProgressMath.displayed(
            completedFiles: 6, failedFiles: 0, currentFileProgress: 0, totalFiles: 6
        ), 1.0)
        approx(UploadProgressMath.displayed(
            completedFiles: 4, failedFiles: 2, currentFileProgress: 0, totalFiles: 6
        ), 1.0)
    }

    @Test("An empty batch is 0, not a division by zero")
    func displayedHandlesEmptyBatch() {
        approx(UploadProgressMath.displayed(
            completedFiles: 0, failedFiles: 0, currentFileProgress: 0, totalFiles: 0
        ), 0)
    }

    // MARK: - isAwaitingRegistration

    @Test("Awaiting registration exactly when the bytes are all up but a file is unaccounted for")
    func awaitingWhenBytesDoneButNotRegistered() {
        #expect(UploadProgressMath.isAwaitingRegistration(
            completedFiles: 5, failedFiles: 0, currentFileProgress: 1.0, totalFiles: 6
        ), "this is the window that shows 99% — it must read as Processing, not Uploading")
    }

    @Test("Not awaiting while the current file still has bytes to send")
    func notAwaitingMidFile() {
        #expect(!UploadProgressMath.isAwaitingRegistration(
            completedFiles: 5, failedFiles: 0, currentFileProgress: 0.4, totalFiles: 6
        ))
    }

    @Test("Not awaiting once every file is accounted for — that batch is over, not processing")
    func notAwaitingWhenComplete() {
        #expect(!UploadProgressMath.isAwaitingRegistration(
            completedFiles: 6, failedFiles: 0, currentFileProgress: 0, totalFiles: 6
        ))
    }

    /// A finished file is already in `completedFiles`, so a leftover fraction counts it twice. Only
    /// the caller can clear it: at one file from the end the two inputs are indistinguishable here.
    @Test("A cleared fraction reads as mid-batch; a leaked one is indistinguishable at n-1")
    func clearedFractionIsWhatDistinguishesMidBatch() {
        // 5 registered of 6, fraction cleared: the 6th has sent nothing yet.
        #expect(!UploadProgressMath.isAwaitingRegistration(
            completedFiles: 5, failedFiles: 0, currentFileProgress: 0, totalFiles: 6
        ))

        // A leak two files from the end is harmless — 4 processed + 1.0 of 6 is short of the ceiling.
        #expect(!UploadProgressMath.isAwaitingRegistration(
            completedFiles: 4, failedFiles: 0, currentFileProgress: 1.0, totalFiles: 6
        ), "a leaked fraction only matters at the very last file")

        // And a failure is counted as processed, so it does not drag the batch a file behind.
        approx(UploadProgressMath.displayed(
            completedFiles: 0, failedFiles: 1, currentFileProgress: 0.5, totalFiles: 6
        ), 1.5 / 6)
    }

    @Test("A failed file counts toward the batch, so a mixed batch still resolves")
    func failuresCountTowardTheBatch() {
        #expect(UploadProgressMath.isAwaitingRegistration(
            completedFiles: 4, failedFiles: 1, currentFileProgress: 1.0, totalFiles: 6
        ), "4 done, 1 failed, the 6th fully uploaded and registering")
    }

    @Test("An empty batch is never awaiting registration")
    func emptyBatchNotAwaiting() {
        #expect(!UploadProgressMath.isAwaitingRegistration(
            completedFiles: 0, failedFiles: 0, currentFileProgress: 0, totalFiles: 0
        ))
    }

    // MARK: - The two together

    @Test("Whenever the ceiling is what is shown, the state is Processing", arguments: [1, 2, 6, 40])
    func ceilingAndProcessingAgree(total: Int) {
        let completed = total - 1
        let shown = UploadProgressMath.displayed(
            completedFiles: completed, failedFiles: 0, currentFileProgress: 1.0, totalFiles: total
        )
        let awaiting = UploadProgressMath.isAwaitingRegistration(
            completedFiles: completed, failedFiles: 0, currentFileProgress: 1.0, totalFiles: total
        )
        approx(shown, UploadProgressMath.inFlightCeiling)
        #expect(awaiting, "the bar is capped, so something must explain the wait")
    }
}
