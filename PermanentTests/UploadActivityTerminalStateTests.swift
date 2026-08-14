//
//  UploadActivityTerminalStateTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.08.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The silent-failure path in the completion hold: suspended mid-hold, a finished batch looks
/// exactly like a zombie on the next launch, and ending it `.failed` would lie to the user.
struct UploadActivityTerminalStateTests {

    private func state(
        _ status: UploadActivityAttributes.UploadStatus,
        completed: Int = 5,
        failed: Int = 0,
        total: Int = 5
    ) -> UploadActivityAttributes.ContentState {
        UploadActivityAttributes.ContentState(
            currentFileIndex: total,
            totalFiles: total,
            currentFileName: "IMG_1.heic",
            overallProgress: 1.0,
            status: status,
            completedCount: completed,
            failedCount: failed,
            folderItemCount: 32
        )
    }

    // MARK: - isTerminal

    @Test("Only completed and failed are terminal")
    func terminalStatuses() {
        #expect(UploadActivityTerminalState.isTerminal(.completed))
        #expect(UploadActivityTerminalState.isTerminal(.failed))
        #expect(!UploadActivityTerminalState.isTerminal(.uploading))
        #expect(!UploadActivityTerminalState.isTerminal(.paused))
        #expect(!UploadActivityTerminalState.isTerminal(.processing))
    }

    // MARK: - The bug this exists to prevent

    @Test("A completed batch orphaned mid-hold keeps its state, and must not become failed")
    func completedOrphanIsPreservedExactly() {
        let finished = state(.completed, completed: 5, failed: 0)
        let result = UploadActivityTerminalState.orphanFinalState(existing: finished)

        #expect(result.status == .completed, "a finished upload must never be relabelled failed")
        #expect(result.completedCount == 5, "and must keep its counts, not be zeroed")
        #expect(result.totalFiles == 5)
        #expect(result.folderItemCount == 32)
    }

    @Test("A failed batch is likewise preserved with its real counts")
    func failedOrphanKeepsItsCounts() {
        let result = UploadActivityTerminalState.orphanFinalState(
            existing: state(.failed, completed: 3, failed: 2)
        )
        #expect(result.status == .failed)
        #expect(result.completedCount == 3, "3 files really did upload; don't zero that")
        #expect(result.failedCount == 2)
    }

    // MARK: - Genuine zombies

    @Test("A non-terminal orphan is ended as failed with counts zeroed", arguments: [
        UploadActivityAttributes.UploadStatus.uploading,
        .paused,
        .processing
    ])
    func nonTerminalOrphanIsFailed(status: UploadActivityAttributes.UploadStatus) {
        let result = UploadActivityTerminalState.orphanFinalState(
            existing: state(status, completed: 2, failed: 0, total: 7)
        )
        #expect(result.status == .failed, "a genuine zombie from a previous session")
        #expect(result.completedCount == 0)
        #expect(result.failedCount == 0)
        #expect(result.totalFiles == 0)
    }

    @Test("An unknown folder item count survives the zombie path as nil, not 0")
    func zombiePreservesUnknownFolderCount() {
        var s = state(.uploading)
        s.folderItemCount = nil
        let result = UploadActivityTerminalState.orphanFinalState(existing: s)
        #expect(result.folderItemCount == nil, "the folder card must still omit an unknown count")
    }
}
