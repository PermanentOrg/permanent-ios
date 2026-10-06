//
//  DropMoveProgressTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 02.10.2026.
//

import XCTest
@testable import Permanent

final class DropMoveProgressTests: XCTestCase {
    func testTheFirstDrop_OpensTheCircle_AndTheNextOnesShareIt() {
        let progress = DropMoveProgress()

        XCTAssertEqual(progress.begin(), .showSpinner)
        XCTAssertEqual(progress.begin(), .none, "a second drop keeps the circle that is already spinning")
        XCTAssertEqual(progress.running, 2)
    }

    func testTheCheck_WaitsForTheLastMove() {
        let progress = DropMoveProgress()
        _ = progress.begin()
        _ = progress.begin()

        XCTAssertEqual(progress.end(succeeded: true), .none, "one move is still running")
        XCTAssertEqual(progress.end(succeeded: true), .showCheck)
        XCTAssertFalse(progress.isRunning)
    }

    func testAFailedMove_ClosesTheCircleWithoutTheCheck() {
        let progress = DropMoveProgress()
        _ = progress.begin()

        XCTAssertEqual(progress.end(succeeded: false), .close)
    }

    func testAFailure_WhileAnotherMoveRuns_ClosesOnlyWhenThatOneEnds() {
        let progress = DropMoveProgress()
        _ = progress.begin()
        _ = progress.begin()

        XCTAssertEqual(progress.end(succeeded: false), .none, "the other move still shows the spinner")
        XCTAssertEqual(progress.end(succeeded: true), .close, "a failure in the batch means no check")
    }

    func testTheNextDrop_AfterACheckOrAClose_StartsAgain() {
        let progress = DropMoveProgress()
        _ = progress.begin()
        _ = progress.end(succeeded: false)

        XCTAssertEqual(progress.begin(), .showSpinner)
        XCTAssertEqual(progress.end(succeeded: true), .showCheck, "the earlier failure does not carry over")
    }

    func testAnEndWithoutABegin_ChangesNothing() {
        let progress = DropMoveProgress()

        XCTAssertEqual(progress.end(succeeded: true), .none)
        XCTAssertEqual(progress.running, 0)
    }
}
