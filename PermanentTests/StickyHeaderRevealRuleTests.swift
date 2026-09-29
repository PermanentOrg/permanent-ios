//
//  StickyHeaderRevealRuleTests.swift
//  PermanentTests
//

import XCTest
@testable import Permanent

final class StickyHeaderRevealRuleTests: XCTestCase {
    /// The synced header's slot ends 228pt down (Uploads header, 2 rows, the 40pt row); the list scrolls to 1954pt.
    private static let slotBottom: CGFloat = 228
    private static let maxTop: CGFloat = 1954

    private var rule = StickyHeaderRevealRule()

    /// Steps through `tops` and returns whether the row is hidden after the last one.
    @discardableResult
    private func scroll(
        _ tops: CGFloat...,
        byUser: Bool = true,
        keepsShown: Bool = false,
        canHide: Bool = true,
        slotBottom: CGFloat = StickyHeaderRevealRuleTests.slotBottom,
        maxTop: CGFloat = StickyHeaderRevealRuleTests.maxTop
    ) -> Bool {
        var hidden = rule.isHidden
        for top in tops {
            hidden = rule.step(top: top, maxTop: maxTop, slotBottom: slotBottom, byUser: byUser, keepsShown: keepsShown, canHide: canHide)
        }
        return hidden
    }

    private func hideFrom300() {
        scroll(300, 330)
        XCTAssertTrue(rule.isHidden, "precondition: 30pt down past the slot hides the row")
    }

    // MARK: - Thresholds

    func testTwentyThreePointsDown_KeepsTheRow_TwentyFourHideIt() {
        XCTAssertFalse(scroll(300, 323))
        XCTAssertTrue(scroll(324))
        XCTAssertEqual(StickyHeaderRevealRule.hideAfter, 24)
    }

    func testAfterHiding_ElevenUpKeepItHidden_TwelveShowIt() {
        hideFrom300()

        XCTAssertTrue(scroll(319))
        XCTAssertFalse(scroll(318))
        XCTAssertEqual(StickyHeaderRevealRule.showAfter, 12)
    }

    func testTheFirstStep_AddsNoTravel() {
        XCTAssertFalse(scroll(900))
        XCTAssertFalse(scroll(923))
        XCTAssertTrue(scroll(924))
    }

    func testAReversal_RestartsTravel() {
        XCTAssertFalse(scroll(300, 320, 315, 335), "down 20, up 5, down 20")
    }

    func testAReversalWhileHidden_RestartsTheWayBackUp() {
        hideFrom300()

        XCTAssertTrue(scroll(319, 324, 313), "up 11, down 5, up 11")
    }

    func testScrollingOnDownWhileHidden_KeepsItHidden() {
        hideFrom300()

        XCTAssertTrue(scroll(400, 900, 1500))
    }

    // MARK: - The slot

    func testInsideTheSlot_TheRowShows() {
        hideFrom300()

        XCTAssertFalse(scroll(200))
    }

    func testLeavingTheSlot_CountsOnlyTheTravelPastIt() {
        XCTAssertFalse(scroll(100, Self.slotBottom + 23))
        XCTAssertTrue(scroll(Self.slotBottom + 24))
    }

    func testPullToRefresh_NegativeOffsetsClampToTheTopAndShowTheRow() {
        let slotBottom: CGFloat = 40
        scroll(100, 130, slotBottom: slotBottom)
        XCTAssertTrue(rule.isHidden)

        XCTAssertFalse(scroll(-80, slotBottom: slotBottom))
        XCTAssertFalse(scroll(-20, 0, 63, slotBottom: slotBottom), "travel restarted at the slot")
        XCTAssertTrue(scroll(64, slotBottom: slotBottom))
    }

    // MARK: - Not by the finger

    func testStepsNotByTheFinger_NeverHideTheRow() {
        XCTAssertFalse(scroll(300, 400, 900, 1500, byUser: false))
    }

    func testStepsNotByTheFinger_NeverShowAHiddenRow() {
        hideFrom300()

        XCTAssertTrue(scroll(250, 100, byUser: false))
    }

    func testANonFingerStepToTheTopWhileHidden_KeepsItHidden_AndAFingerStepInTheSlotShows() {
        hideFrom300()

        XCTAssertTrue(scroll(0, byUser: false), "a back preview scrolls to the top in code")
        XCTAssertFalse(scroll(10))
    }

    func testAfterAJumpInCode_TheNextFingerStepMeasuresFromThere() {
        scroll(300)
        scroll(900, byUser: false)

        XCTAssertFalse(scroll(923))
        XCTAssertTrue(scroll(924))
    }

    // MARK: - Kept shown

    func testKeepsShown_NeverHides() {
        XCTAssertFalse(scroll(300, 400, 900, keepsShown: true))
    }

    func testKeepsShown_ShowsAHiddenRowEvenWithoutAFinger() {
        hideFrom300()

        XCTAssertFalse(scroll(340, byUser: false, keepsShown: true))
    }

    func testKeepsShown_ResetsTravel() {
        scroll(300, 320)
        scroll(330, keepsShown: true)

        XCTAssertFalse(scroll(353), "the 20pt before select mode ended no longer counts")
        XCTAssertTrue(scroll(354))
    }

    // MARK: - The ends of the list

    func testOffsetsPastTheBottom_Clamp_SoTheBounceBackDoesNotShowTheRow() {
        scroll(1900, 1954)
        XCTAssertTrue(rule.isHidden)

        XCTAssertTrue(scroll(1990, 2010, 1970, 1954), "the rubber band past the end adds no travel")
    }

    func testAListThatEndsBeforeTheHideDistance_NeverHides() {
        let maxTop = Self.slotBottom + 23

        XCTAssertFalse(scroll(Self.slotBottom, maxTop, maxTop + 100, maxTop: maxTop))
    }

    func testAFolderThatFitsOnScreen_NeverHidesTheRow() {
        // 6 rows of 74pt under a 40pt row in a 690pt list with a 350pt bottom inset can still scroll 144pt.
        XCTAssertFalse(scroll(0, 50, 100, 144, canHide: false, slotBottom: 40, maxTop: 144))
    }

    func testAListThatStopsRunningPastTheScreen_ShowsTheRowAtTheNextFingerStep() {
        hideFrom300()

        XCTAssertFalse(scroll(340, canHide: false))
    }

    // MARK: - Reset

    func testReset_ShowsTheRowAndMeasuresAfresh() {
        hideFrom300()

        rule.reset()

        XCTAssertFalse(rule.isHidden)
        XCTAssertFalse(scroll(600, 623))
        XCTAssertTrue(scroll(624))
    }
}
