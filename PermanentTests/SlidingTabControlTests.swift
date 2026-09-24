//
//  SlidingTabControlTests.swift
//  PermanentTests
//

import XCTest
@testable import Permanent

final class SlidingTabControlTests: XCTestCase {
    private func makeControl() -> SlidingTabControl {
        let control = SlidingTabControl(frame: CGRect(x: 0, y: 0, width: 360, height: 32))
        control.titles = ["Shared By Me", "Shared With Me"]
        control.layoutIfNeeded()
        return control
    }

    private func tab(_ title: String, in control: SlidingTabControl) throws -> UIButton {
        try XCTUnwrap(control.subviews.compactMap { $0 as? UIButton }.first { $0.title(for: .normal) == title })
    }

    private func countValueChanges(of control: SlidingTabControl) -> () -> Int {
        var count = 0
        control.addAction(UIAction { _ in count += 1 }, for: .valueChanged)
        return { count }
    }

    func testTappingAnotherTab_SelectsItAndSaysSo() throws {
        let control = makeControl()
        let changes = countValueChanges(of: control)

        try tab("Shared With Me", in: control).sendActions(for: .touchUpInside)

        XCTAssertEqual(control.selectedSegmentIndex, 1)
        XCTAssertEqual(changes(), 1)
    }

    func testTappingTheSelectedTab_ChangesNothing() throws {
        let control = makeControl()
        let changes = countValueChanges(of: control)

        try tab("Shared By Me", in: control).sendActions(for: .touchUpInside)

        XCTAssertEqual(control.selectedSegmentIndex, 0)
        XCTAssertEqual(changes(), 0)
    }

    func testSelectingInCode_SendsNoValueChange() {
        let control = makeControl()
        let changes = countValueChanges(of: control)

        control.selectedSegmentIndex = 1

        XCTAssertEqual(changes(), 0, "as in UISegmentedControl, only a tap reports a change")
    }

    func testVoiceOver_HearsEachTabAsAButtonAndWhichOneIsSelected() throws {
        let control = makeControl()
        control.selectedSegmentIndex = 1

        XCTAssertFalse(try tab("Shared By Me", in: control).accessibilityTraits.contains(.selected))
        XCTAssertTrue(try tab("Shared With Me", in: control).accessibilityTraits.contains(.selected))
        XCTAssertTrue(try tab("Shared With Me", in: control).accessibilityTraits.contains(.button))
    }

    func testVoiceOver_HearsEachTabsPosition() throws {
        let control = makeControl()

        XCTAssertEqual(try tab("Shared By Me", in: control).accessibilityValue, "1 of 2")
        XCTAssertEqual(try tab("Shared With Me", in: control).accessibilityValue, "2 of 2")
    }

    func testNoTabBarTrait_SoUITestsFindEachTabOnce() {
        // Under a tab-bar trait the button's own label also reads as a button.
        XCTAssertFalse(makeControl().accessibilityTraits.contains(.tabBar))
    }

    func testThePill_SitsUnderTheSelectedTab() throws {
        let control = makeControl()
        control.selectedSegmentIndex = 1
        control.layoutIfNeeded()

        let pill = try XCTUnwrap(control.subviews.first { $0.backgroundColor == .primary })
        XCTAssertTrue(try tab("Shared With Me", in: control).frame.contains(pill.center))
    }

    func testVoiceOver_SkipsTheWhiteCopiesOfTheTitles() {
        let control = makeControl()

        let hidden = control.subviews.filter { $0.accessibilityElementsHidden }
        XCTAssertEqual(hidden.count, 1)
        XCTAssertEqual(hidden.first?.subviews.compactMap { ($0 as? UILabel)?.text }, control.titles)
    }

    func testACustomLook_ReachesThePillAndBothTitleCopies() throws {
        let control = makeControl()
        control.pillColor = .systemTeal
        control.titleColor = .systemPink
        control.titleFont = TextFontStyle.style9.font
        control.selectedTitleFont = TextFontStyle.style9.font

        XCTAssertNotNil(control.subviews.first { $0.backgroundColor == .systemTeal })
        let tab = try tab("Shared With Me", in: control)
        XCTAssertEqual(tab.titleColor(for: .normal), .systemPink)
        XCTAssertEqual(tab.titleLabel?.font, TextFontStyle.style9.font)
        let copies = control.subviews.first { $0.accessibilityElementsHidden }?.subviews.compactMap { $0 as? UILabel } ?? []
        XCTAssertEqual(copies.map(\.font), [TextFontStyle.style9.font, TextFontStyle.style9.font])
    }

    func testRightToLeft_PutsTheFirstTabOnTheRight() throws {
        let control = makeControl()
        control.semanticContentAttribute = .forceRightToLeft
        control.setNeedsLayout()
        control.layoutIfNeeded()

        XCTAssertGreaterThan(try tab("Shared By Me", in: control).frame.minX, try tab("Shared With Me", in: control).frame.minX)
    }
}
