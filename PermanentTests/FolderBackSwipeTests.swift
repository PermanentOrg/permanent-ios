//
//  FolderBackSwipeTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 24.09.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class FolderBackSwipeTests: XCTestCase {
    func testLettingGoPastAThird_GoesBack() {
        XCTAssertTrue(FolderBackSwipe.goesBack(travel: 140, speed: 0, width: 400))
        XCTAssertFalse(FolderBackSwipe.goesBack(travel: 120, speed: 0, width: 400))
    }

    func testAFlick_GoesBackFromAShortDrag() {
        XCTAssertTrue(FolderBackSwipe.goesBack(travel: 30, speed: 800, width: 400))
    }

    func testAFlickTheOtherWay_SpringsBackEvenFarAcross() {
        XCTAssertFalse(FolderBackSwipe.goesBack(travel: 300, speed: -800, width: 400))
    }

    func testTheEdgeShadow_StaysOffTheTopAndBottom_SoNoneFallsOnTheSortRow() {
        let page = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 700))

        FolderBackSwipe.castEdgeShadow(from: page)

        let path = page.layer.shadowPath?.boundingBox
        XCTAssertEqual(page.layer.shadowOffset, .zero)
        XCTAssertEqual(path?.minY, 2 * page.layer.shadowRadius, "a blur reaches about twice its radius")
        XCTAssertEqual(path?.maxY, 700 - 2 * page.layer.shadowRadius)
        XCTAssertEqual(path?.width, 390, "the sides cast it")
    }

    // MARK: - The back arrow

    /// A test window is never drawn, and a view that was never drawn has no snapshot of its own.
    private final class SnapshotList: UICollectionView {
        var hasDrag = false
        override func snapshotView(afterScreenUpdates: Bool) -> UIView? { UIView() }
        override var hasActiveDrag: Bool { hasDrag }
    }

    private func hostedList() -> (list: UICollectionView, container: UIView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let container = UIView(frame: window.bounds)
        window.addSubview(container)
        let list = SnapshotList(frame: container.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        list.backgroundColor = .systemBackground
        container.addSubview(list)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        return (list, container)
    }

    private func swipe(on list: UICollectionView, in container: UIView, canGoBack: Bool = true, reduceMotion: Bool = false,
                       events: @escaping (String) -> Void) -> FolderBackSwipe {
        FolderBackSwipe(list: list, in: container, handlers: .init(
            canGoBack: { canGoBack },
            showParentPreview: { events("preview") },
            previewStillApplies: { true },
            endParentPreview: { events("end"); return false },
            goBack: { events("back") }
        ), reduceMotion: { reduceMotion })
    }

    private func waitUntil(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 2) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }
    }

    func testTheArrow_PlaysTheSwipeThrough_ThenTidiesUp() {
        let (list, container) = hostedList()
        var events: [String] = []
        let swipe = swipe(on: list, in: container) { events.append($0) }

        XCTAssertTrue(swipe.slideBack())

        XCTAssertEqual(events, ["preview", "back", "end"], "the parent's loading rows are up before its load starts")
        XCTAssertEqual(container.subviews.count, 2, "the folder's rows slide off over the parent")
        XCTAssertFalse(swipe.slideBack(), "one slide at a time")
        waitUntil(container.subviews.count == 1)
        XCTAssertEqual(container.subviews, [list])
        XCTAssertEqual(list.transform, .identity)
        XCTAssertEqual(events.filter { $0 == "back" }.count, 1)
    }

    func testTheArrow_DropsTheLoadsCrossFade_WhichWouldStartFromTheFoldersOwnRows() {
        let (list, container) = hostedList()
        let swipe = FolderBackSwipe(list: list, in: container, handlers: .init(
            canGoBack: { true },
            showParentPreview: {},
            previewStillApplies: { true },
            endParentPreview: { false },
            goBack: { list.layer.add(CATransition(), forKey: kCATransition) }
        ), reduceMotion: { false })

        XCTAssertTrue(swipe.slideBack())

        XCTAssertNil(list.layer.animation(forKey: kCATransition))
    }

    func testTheEdgeSwipe_WaitsWhileAFileIsDragged() throws {
        let (list, container) = hostedList()
        let swipe = swipe(on: list, in: container) { _ in }
        let edge = try XCTUnwrap(container.gestureRecognizers?.first { $0 is UIScreenEdgePanGestureRecognizer })
        XCTAssertTrue(swipe.gestureRecognizerShouldBegin(edge))

        try XCTUnwrap(list as? SnapshotList).hasDrag = true

        XCTAssertFalse(swipe.gestureRecognizerShouldBegin(edge), "a second finger at the edge must not swipe the folder away under the files")
    }

    func testTheArrow_LeavesTheWayBackToTheCaller_WhenItCannotSlide() {
        let (list, container) = hostedList()
        let offScreenContainer = UIView(frame: container.frame)
        let offScreen = UICollectionView(frame: container.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        offScreenContainer.addSubview(offScreen)
        var events: [String] = []

        XCTAssertFalse(swipe(on: list, in: container, canGoBack: false) { events.append($0) }.slideBack(), "no way back")
        XCTAssertFalse(swipe(on: list, in: container, reduceMotion: true) { events.append($0) }.slideBack(), "Reduce Motion")
        XCTAssertFalse(swipe(on: offScreen, in: offScreenContainer) { events.append($0) }.slideBack(), "off screen")

        XCTAssertEqual(events, [])
        XCTAssertEqual(container.subviews, [list])
    }

    // MARK: - The sort row

    /// A folder list with its sort row, which a never-drawn window cannot snapshot either.
    private final class SnapshotFolderList: StickyHeaderTestList {
        override func snapshotView(afterScreenUpdates: Bool) -> UIView? { UIView() }
        override func resizableSnapshotView(from rect: CGRect, afterScreenUpdates: Bool, withCapInsets capInsets: UIEdgeInsets) -> UIView? { UIView() }
    }

    func testTheArrow_HoldsTheSortRowStill_AboveTheRowsItSlidesOff() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let container = UIView(frame: window.bounds)
        window.addSubview(container)
        let list = SnapshotFolderList(layout: StickyHeaderFlowLayout.fileList())
        list.uploadRows = 0
        list.reloadData()
        container.addSubview(list)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        list.scroll(to: 0)
        let swipe = swipe(on: list, in: container) { _ in }

        XCTAssertTrue(swipe.slideBack())

        XCTAssertEqual(container.subviews.count, 3, "the parent, the sliding rows and, on top, the row's copy")
        let still = try XCTUnwrap(container.subviews.last)
        XCTAssertEqual(still.frame, CGRect(x: 0, y: 0, width: 390, height: StickyHeaderTestList.headerHeight))
        XCTAssertNil(still.layer.animationKeys(), "the copy does not slide")
        waitUntil(container.subviews.count == 1)
        XCTAssertEqual(container.subviews, [list])
    }
}
