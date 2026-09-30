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

    // MARK: - The back arrow

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
        XCTAssertEqual(container.subviews.count, 3, "the folder's rows slide off over the dimmed parent")
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
}
