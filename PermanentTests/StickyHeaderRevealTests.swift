//
//  StickyHeaderRevealTests.swift
//  PermanentTests
//

import XCTest
@testable import Permanent

final class StickyHeaderRevealTests: XCTestCase {
    private func makeList(_ configure: (StickyHeaderTestList) -> Void = { _ in }) -> (StickyHeaderTestList, StickyHeaderFlowLayout) {
        let layout = StickyHeaderFlowLayout.fileList()
        let list = StickyHeaderTestList(layout: layout)
        configure(list)
        list.reloadData()
        list.scroll(to: 0)
        return (list, layout)
    }

    /// Scrolls the list through `offsets`, telling the reveal after each one as the screens' delegates do.
    private func scroll(_ list: StickyHeaderTestList, _ reveal: StickyHeaderReveal, through offsets: CGFloat...) {
        for offset in offsets {
            list.scroll(to: offset)
            reveal.listDidScroll()
        }
    }

    // MARK: - The finger

    func testAFingerDragDown_HidesTheRow_AndTwelvePointsBackUpShowIt() {
        let (list, layout) = makeList()
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { false })
        list.isDragging = true

        scroll(list, reveal, through: 300, 330)
        XCTAssertTrue(layout.hidesStickyHeader)

        scroll(list, reveal, through: 318)
        XCTAssertFalse(layout.hidesStickyHeader)
    }

    func testDecelerating_CountsAsTheFinger() {
        let (list, layout) = makeList()
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { false })
        list.isDecelerating = true

        scroll(list, reveal, through: 300, 330)

        XCTAssertTrue(layout.hidesStickyHeader)
    }

    func testTheSameOffsetsInCode_ChangeNothing() {
        let (list, layout) = makeList()
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { false })

        scroll(list, reveal, through: 300, 330, 900)
        XCTAssertFalse(layout.hidesStickyHeader)

        list.isDragging = true
        scroll(list, reveal, through: 930)
        list.isDragging = false
        scroll(list, reveal, through: 0)
        XCTAssertTrue(layout.hidesStickyHeader, "a scroll to the top in code keeps the row's state")
    }

    func testKeepsShown_NeverHidesTheRow() {
        let (list, layout) = makeList()
        var selecting = true
        let reveal = StickyHeaderReveal(list: list, keepsShown: { selecting }, reducesMotion: { false })
        list.isDragging = true

        scroll(list, reveal, through: 300, 400, 900)
        XCTAssertFalse(layout.hidesStickyHeader)

        selecting = false
        scroll(list, reveal, through: 930)
        XCTAssertTrue(layout.hidesStickyHeader)
    }

    // MARK: - Showing and motion

    func testShowWithoutAnimation_ClearsTheStateAtOnce() {
        let (list, layout) = makeList()
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { false })
        list.isDragging = true
        scroll(list, reveal, through: 300, 330)

        reveal.show(animated: false)

        XCTAssertFalse(layout.hidesStickyHeader)
        XCTAssertEqual(list.syncedHeader?.alpha, 1)
        scroll(list, reveal, through: 353)
        XCTAssertFalse(layout.hidesStickyHeader, "travel starts again after a reset")
    }

    func testReduceMotion_HidesTheRowWithoutSliding() {
        let (list, layout) = makeList()
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { true })
        list.isDragging = true

        scroll(list, reveal, through: 300, 330)

        XCTAssertTrue(layout.hidesStickyHeader)
        XCTAssertFalse(layout.slidesStickyHeader)
        XCTAssertEqual(list.syncedHeader?.transform, .identity)
    }

    func testWithoutReduceMotion_TheRowSlides() {
        let (list, layout) = makeList()
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { false })
        list.isDragging = true

        scroll(list, reveal, through: 300, 330)

        XCTAssertTrue(layout.slidesStickyHeader)
        XCTAssertEqual(list.syncedHeader?.transform, CGAffineTransform(translationX: 0, y: -39))
    }

    func testAnAssistiveTechnologyChange_ShowsTheRow() {
        let (list, layout) = makeList()
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { false })
        list.isDragging = true
        scroll(list, reveal, through: 300, 330)
        XCTAssertTrue(layout.hidesStickyHeader)

        NotificationCenter.default.post(name: UIAccessibility.voiceOverStatusDidChangeNotification, object: nil)
        XCTAssertFalse(layout.hidesStickyHeader)

        scroll(list, reveal, through: 400, 430)
        XCTAssertTrue(layout.hidesStickyHeader)
        NotificationCenter.default.post(name: UIAccessibility.switchControlStatusDidChangeNotification, object: nil)
        XCTAssertFalse(layout.hidesStickyHeader)
    }

    func testAnAnimatedHide_KeepsTheRowsViewInTheList() throws {
        let (list, _) = makeList()
        let window = UIWindow(frame: list.frame)
        window.addSubview(list)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { false })
        list.isDragging = true

        scroll(list, reveal, through: 300, 330)

        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))
        list.layoutIfNeeded()

        let path = IndexPath(item: 0, section: 2)
        let view = try XCTUnwrap(list.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: path), "still there after the animation")
        XCTAssertEqual(view.alpha, 0)
        XCTAssertEqual(view.transform, CGAffineTransform(translationX: 0, y: -39))
    }

    /// Hosted, with the list's delegate as the screens do it: told of the new offset before the layout pass.
    private func flipMidScroll(reducesMotion: Bool) throws -> UICollectionReusableView {
        let (list, layout) = makeList()
        let window = UIWindow(frame: list.frame)
        window.addSubview(list)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { reducesMotion })
        list.isDragging = true
        scroll(list, reveal, through: 300)

        list.contentOffset = CGPoint(x: -list.contentInset.left, y: 330)
        reveal.listDidScroll()

        XCTAssertTrue(layout.hidesStickyHeader, "precondition: 30pt of finger travel hides the row")
        let path = IndexPath(item: 0, section: 2)
        return try XCTUnwrap(list.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: path))
    }

    func testAFlipMidScroll_AnimatesTheFadeAndSlide_ButNotTheRowFollowingTheScroll() throws {
        let row = try flipMidScroll(reducesMotion: false)
        let animated = row.layer.animationKeys() ?? []

        XCTAssertTrue(animated.contains("opacity"))
        XCTAssertTrue(animated.contains("transform"))
        XCTAssertFalse(animated.contains("position"), "the row is already pinned at the new offset")
        XCTAssertEqual(row.center.y, 330 + StickyHeaderTestList.headerHeight / 2)
    }

    func testAFlipMidScroll_WithReduceMotion_OnlyFades() throws {
        let row = try flipMidScroll(reducesMotion: true)
        let animated = row.layer.animationKeys() ?? []

        XCTAssertTrue(animated.contains("opacity"))
        XCTAssertFalse(animated.contains("transform"))
        XCTAssertFalse(animated.contains("position"))
    }

    // MARK: - Lists it leaves alone

    func testAFolderThatFitsOnScreen_NeverHidesTheRow() {
        // 8 rows end at 820pt, above the 844pt list's bottom, yet the 350pt inset lets it scroll 326pt.
        let (list, layout) = makeList { $0.syncedRows = 8 }
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { false })
        list.isDragging = true

        scroll(list, reveal, through: 240, 280, 326)

        XCTAssertFalse(layout.hidesStickyHeader)
    }

    func testAListWithoutTheRow_IsLeftAlone() {
        let (list, layout) = makeList { $0.syncedHeaderHeight = 0 }
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { false })
        list.isDragging = true

        scroll(list, reveal, through: 300, 330, 600)

        XCTAssertFalse(layout.hidesStickyHeader)
    }

    /// Only guards against a crash: the reveal has nothing to act on without a `StickyHeaderFlowLayout`.
    func testAPlainFlowLayoutList_ScrollsAndShowsWithoutACrash() {
        let list = StickyHeaderTestList(layout: UICollectionViewFlowLayout())
        list.reloadData()
        let reveal = StickyHeaderReveal(list: list, keepsShown: { false }, reducesMotion: { false })
        list.isDragging = true

        scroll(list, reveal, through: 0, 300, 330)
        reveal.show(animated: true)
    }

    func testTheRevealDoesNotKeepItsListAlive() {
        weak var released: StickyHeaderTestList?
        var reveal: StickyHeaderReveal?
        autoreleasepool {
            let list = StickyHeaderTestList()
            released = list
            reveal = StickyHeaderReveal(list: list, keepsShown: { false })
        }

        XCTAssertNil(released)
        reveal?.listDidScroll()
        reveal?.show(animated: false)
    }
}
