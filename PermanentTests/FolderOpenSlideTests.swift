//
//  FolderOpenSlideTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class FolderOpenSlideTests: XCTestCase {
    /// A test window is never drawn, and a view that was never drawn has no snapshot of its own.
    private final class SnapshotList: UICollectionView {
        override func snapshotView(afterScreenUpdates: Bool) -> UIView? { UIView() }
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

    private func waitUntil(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 2) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }
    }

    private func slides(_ list: UICollectionView) -> Bool {
        list.layer.animationKeys()?.contains { $0.hasPrefix("transform") } ?? false
    }

    func testOpeningAFolder_SlidesTheListInOverTheRowsItLeaves_ThenTidiesUp() {
        let (list, container) = hostedList()
        var opened = 0

        FolderOpenSlide.play(on: list, reduceMotion: false) { opened += 1 }

        XCTAssertEqual(opened, 1)
        XCTAssertEqual(container.subviews.count, 3, "the old rows and the list's shadow sit under the list")
        XCTAssertEqual(container.subviews.last, list)
        XCTAssertTrue(slides(list))
        waitUntil(container.subviews.count == 1)
        XCTAssertEqual(container.subviews, [list])
        XCTAssertEqual(list.transform, .identity)
    }

    func testTheListsCrossFadeToTheLoadingRows_DoesNotRideAlong() {
        let (list, _) = hostedList()

        FolderOpenSlide.play(on: list, reduceMotion: false) {
            list.layer.add(CATransition(), forKey: kCATransition)
        }

        XCTAssertNil(list.layer.animation(forKey: kCATransition))
    }

    func testUnderReduceMotion_TheFolderOpensWithoutASlide() {
        let (list, container) = hostedList()
        var opened = 0

        FolderOpenSlide.play(on: list, reduceMotion: true) { opened += 1 }

        XCTAssertEqual(opened, 1)
        XCTAssertEqual(container.subviews, [list])
        XCTAssertFalse(slides(list))
    }

    func testOffScreen_TheFolderOpensWithoutASlide() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let list = UICollectionView(frame: container.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        container.addSubview(list)
        var opened = 0

        FolderOpenSlide.play(on: list, reduceMotion: false) { opened += 1 }

        XCTAssertEqual(opened, 1)
        XCTAssertEqual(container.subviews, [list])
    }

    // MARK: - The sort row

    /// A folder list with its sort row, which a never-drawn window cannot snapshot either.
    private final class SnapshotFolderList: StickyHeaderTestList {
        override func snapshotView(afterScreenUpdates: Bool) -> UIView? { UIView() }
        override func resizableSnapshotView(from rect: CGRect, afterScreenUpdates: Bool, withCapInsets capInsets: UIEdgeInsets) -> UIView? { UIView() }
    }

    private func hostedFolderList(_ configure: (StickyHeaderTestList) -> Void = { _ in }) -> (list: StickyHeaderTestList, container: UIView) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let container = UIView(frame: window.bounds)
        window.addSubview(container)
        let list = SnapshotFolderList(layout: StickyHeaderFlowLayout.fileList())
        configure(list)
        list.reloadData()
        container.addSubview(list)
        window.isHidden = false
        list.scroll(to: 0)
        addTeardownBlock { window.isHidden = true }
        return (list, container)
    }

    func testTheSortRow_StaysStillOverTheSlidingList_ThenHandsOver() throws {
        let (list, container) = hostedFolderList { $0.uploadRows = 0 }

        FolderOpenSlide.play(on: list, reduceMotion: false) {}

        let still = try XCTUnwrap(container.subviews.last)
        XCTAssertFalse(still === list, "a copy of the row sits above the list")
        XCTAssertEqual(still.frame, CGRect(x: 0, y: 0, width: 390, height: StickyHeaderTestList.headerHeight))
        XCTAssertTrue(slides(list))
        XCTAssertNil(still.layer.animationKeys(), "the copy does not slide")
        waitUntil(container.subviews.count == 1)
        XCTAssertEqual(container.subviews, [list], "the copy fades into the list's own row, then goes")
    }

    func testAHiddenSortRow_SlidesInWithTheRows() {
        let (list, container) = hostedFolderList()
        list.scroll(to: 600)
        (list.collectionViewLayout as? StickyHeaderFlowLayout)?.hidesStickyHeader = true
        list.layoutIfNeeded()

        FolderOpenSlide.play(on: list, reduceMotion: false) {}

        XCTAssertEqual(container.subviews.count, 3, "no copy of a row that is not on screen")
        XCTAssertEqual(container.subviews.last, list)
    }

    func testASortRowThatMoves_IsNotHeldStill() {
        let (list, container) = hostedFolderList { $0.uploadRows = 0 }

        FolderOpenSlide.play(on: list, reduceMotion: false) {
            // The next folder lists uploads above its sort row.
            list.uploadRows = 2
            list.reloadData()
        }

        XCTAssertEqual(container.subviews.count, 3)
        XCTAssertEqual(container.subviews.last, list)
    }
}
