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
        XCTAssertEqual(container.subviews.count, 4, "the old rows, their dimming and the list's shadow sit under the list")
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
}
