//
//  FolderItemCountMathTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 10.08.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The folder card's item count. The point is the `nil` handling: an unknown count must stay
/// unknown rather than collapse to `0` and count only this batch.
struct FolderItemCountMathTests {

    // MARK: - displayed(base:completedFiles:)

    @Test("The displayed count is the folder's own count plus what has landed")
    func displayedAddsCompletedToBase() {
        #expect(FolderItemCountMath.displayed(base: 32, completedFiles: 3) == 35)
    }

    @Test("An unknown base stays unknown rather than counting only this batch")
    func displayedStaysNilWhenBaseUnknown() {
        // The Share Extension never lists the destination, so it cannot supply a base.
        // Returning 3 here would tell the user a 40-item folder holds 3.
        #expect(FolderItemCountMath.displayed(base: nil, completedFiles: 3) == nil)
    }

    @Test("A genuinely empty folder counts up from zero")
    func displayedHandlesEmptyFolder() {
        #expect(FolderItemCountMath.displayed(base: 0, completedFiles: 0) == 0)
        #expect(FolderItemCountMath.displayed(base: 0, completedFiles: 1) == 1)
    }

    // MARK: - recoveredBase(snapshotBase:activityDisplayedCount:completedFiles:)

    @Test("The persisted snapshot wins when it has a base")
    func recoveredBasePrefersSnapshot() {
        let base = FolderItemCountMath.recoveredBase(
            snapshotBase: 32,
            activityDisplayedCount: 99,
            completedFiles: 3
        )
        #expect(base == 32, "A snapshot that carries the base is authoritative")
    }

    @Test("Without a snapshot base, it is backed out of the activity's displayed count")
    func recoveredBaseInvertsDisplayedCount() {
        // A snapshot written before `folderBaseItemCount` existed decodes it as nil, so
        // the base has to come back out of what the activity is currently showing.
        let base = FolderItemCountMath.recoveredBase(
            snapshotBase: nil,
            activityDisplayedCount: 35,
            completedFiles: 3
        )
        #expect(base == 32, "35 shown minus 3 completed is the 32 the folder started with")
    }

    @Test("recoveredBase is the exact inverse of displayed")
    func recoveredBaseRoundTripsWithDisplayed() throws {
        for base in [0, 1, 7, 32, 4096] {
            for completed in [0, 1, 5, 900] {
                let shown = try #require(
                    FolderItemCountMath.displayed(base: base, completedFiles: completed)
                )
                let recovered = FolderItemCountMath.recoveredBase(
                    snapshotBase: nil,
                    activityDisplayedCount: shown,
                    completedFiles: completed
                )
                #expect(recovered == base, "base \(base) + \(completed) must invert cleanly")
            }
        }
    }

    @Test("Nothing to recover from stays unknown")
    func recoveredBaseStaysNilWhenNothingKnown() {
        let base = FolderItemCountMath.recoveredBase(
            snapshotBase: nil,
            activityDisplayedCount: nil,
            completedFiles: 3
        )
        #expect(base == nil)
    }

    @Test("A displayed count below the completed count clamps to zero, never negative")
    func recoveredBaseClampsAtZero() {
        // The two numbers come from separate writes and can disagree; a negative base
        // would then be added back on and shown.
        let base = FolderItemCountMath.recoveredBase(
            snapshotBase: nil,
            activityDisplayedCount: 2,
            completedFiles: 5
        )
        #expect(base == 0)
    }
}
