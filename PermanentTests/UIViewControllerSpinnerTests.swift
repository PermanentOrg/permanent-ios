//
//  UIViewControllerSpinnerTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 03.09.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class UIViewControllerSpinnerTests: XCTestCase {

    private func makeController() -> UIViewController {
        let controller = UIViewController()
        controller.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        return controller
    }

    // showSpinner adds exactly one overlay subview to the screen's own view; nothing else here adds subviews.
    private func overlayCount(_ controller: UIViewController) -> Int {
        controller.view.subviews.count
    }

    func testShowSpinner_AddsOneOverlay_AndIgnoresRepeats() {
        let controller = makeController()

        controller.showSpinner()
        controller.showSpinner()

        XCTAssertEqual(overlayCount(controller), 1)
    }

    func testShowSpinner_OnTwoScreens_GivesEachItsOwnOverlay() {
        let first = makeController()
        let second = makeController()

        first.showSpinner()
        second.showSpinner()

        XCTAssertEqual(overlayCount(first), 1)
        XCTAssertEqual(overlayCount(second), 1, "The second screen must not be blocked by the first screen's spinner")
    }

    func testHideSpinner_OnOneScreen_LeavesTheOtherScreenAlone() {
        let first = makeController()
        let second = makeController()
        first.showSpinner()
        second.showSpinner()

        first.hideSpinner()

        // The hide fades out, so the overlay is detached only after the animation; the slot is freed at once.
        first.showSpinner()
        XCTAssertGreaterThanOrEqual(overlayCount(first), 1)
        XCTAssertEqual(overlayCount(second), 1, "Hiding one screen's spinner must not remove another screen's overlay")
    }

    func testHideSpinner_WithoutShow_DoesNothing() {
        let controller = makeController()

        controller.hideSpinner()

        XCTAssertEqual(overlayCount(controller), 0)
    }
}
