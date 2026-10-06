//
//  ContextMenuDeferralTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class ContextMenuDeferralTests: XCTestCase {
    private final class Animator: NSObject, UIContextMenuInteractionAnimating {
        var previewViewController: UIViewController? { nil }
        private var completions: [() -> Void] = []
        func addAnimations(_ animations: @escaping () -> Void) {}
        func addCompletion(_ completion: @escaping () -> Void) { completions.append(completion) }
        func finish() { completions.forEach { $0() } }
    }

    func testAPick_WaitsUntilTheMenuHasFinishedClosing() {
        let deferral = ContextMenuDeferral(), animator = Animator()
        var ran = false
        deferral.menuWillShow()
        deferral.run { ran = true }
        deferral.menuWillEnd(animator: animator)
        XCTAssertFalse(ran)
        animator.finish()
        XCTAssertTrue(ran)
    }

    func testAPickWhileTheMenuCloses_StillWaitsForTheEnd() {
        let deferral = ContextMenuDeferral(), animator = Animator()
        var ran = false
        deferral.menuWillShow()
        deferral.menuWillEnd(animator: animator)
        deferral.run { ran = true }
        XCTAssertFalse(ran)
        animator.finish()
        XCTAssertTrue(ran)
    }

    func testAPickAfterTheMenuClosed_RunsOnTheNextTurn() {
        let deferral = ContextMenuDeferral()
        let ran = expectation(description: "the pick runs")
        deferral.menuWillShow()
        deferral.menuWillEnd(animator: nil)
        deferral.run { ran.fulfill() }
        wait(for: [ran], timeout: 1)
    }

    func testReloads_WaitWhileTheMenuIsShown_ThenRunInOrderBeforeThePick() {
        let deferral = ContextMenuDeferral()
        var events: [String] = []
        XCTAssertFalse(deferral.holdsReload { events.append("early") }, "with no menu the reload goes ahead")
        deferral.menuWillShow()
        XCTAssertTrue(deferral.holdsReload { events.append("first") })
        XCTAssertTrue(deferral.holdsReload { events.append("reload") })
        deferral.run { events.append("pick") }
        deferral.menuWillEnd(animator: nil)
        XCTAssertEqual(events, ["first", "reload", "pick"], "every held reload runs, so none loses its completion")
        XCTAssertFalse(deferral.isMenuShown)
    }

    func testAMenuWhoseCloseNeverReportsBack_EndsAfterTheFallback() {
        let deferral = ContextMenuDeferral(fallbackDelay: 0.05), silent = Animator()
        let reloaded = expectation(description: "the held reload runs")
        deferral.menuWillShow()
        XCTAssertTrue(deferral.holdsReload { reloaded.fulfill() })
        deferral.menuWillEnd(animator: silent)
        wait(for: [reloaded], timeout: 1)
        XCTAssertFalse(deferral.isMenuShown)
    }

    func testTheOldMenusLateEnd_DoesNotReleaseWorkUnderTheNewMenu() {
        let deferral = ContextMenuDeferral(), old = Animator()
        var reloads = 0
        deferral.menuWillShow()
        deferral.menuWillEnd(animator: old)
        deferral.menuWillShow()
        XCTAssertTrue(deferral.holdsReload { reloads += 1 })
        old.finish()
        XCTAssertTrue(deferral.isMenuShown)
        XCTAssertEqual(reloads, 0)
        deferral.menuWillEnd(animator: nil)
        XCTAssertEqual(reloads, 1)
    }

    func testAScreenThatGoesAway_ReleasesWhatTheMenuHeld() {
        let deferral = ContextMenuDeferral()
        var reloads = 0
        deferral.menuWillShow()
        XCTAssertTrue(deferral.holdsReload { reloads += 1 })
        deferral.menuIsGone()
        XCTAssertEqual(reloads, 1)
        XCTAssertFalse(deferral.holdsReload { reloads += 1 }, "no menu is left to wait for")
    }
}
