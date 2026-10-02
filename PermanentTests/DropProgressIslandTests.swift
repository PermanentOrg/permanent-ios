//
//  DropProgressIslandTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 02.10.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class DropProgressIslandTests: XCTestCase {
    /// Counts the check marks whose wait has ended, so a test can wait for that instead of the clock.
    private final class CountingIsland: FloatingActionIslandViewController {
        var finishedChecks = 0

        override func showDoneCheckmark(_ completion: (() -> Void)? = nil) {
            super.showDoneCheckmark { [weak self] in
                completion?()
                self?.finishedChecks += 1
            }
        }
    }

    /// A screen stand-in: it hosts the islands the helper opens, and records what the helper asked for.
    @MainActor
    private final class Screen {
        let host = UIViewController()
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        var island: FloatingActionIslandViewController?
        var opened = 0, plusHidden = 0, restored = 0
        var holdsClose = false
        var heldClose: (() -> Void)?
        var said: [String] = []

        init() {
            window.rootViewController = host
            window.isHidden = false
        }

        func handlers() -> DropProgressIsland.Handlers {
            .init(
                open: { [unowned self] in
                    opened += 1
                    let island = CountingIsland()
                    island.opensAsCircle = true
                    host.addChild(island)
                    host.view.addSubview(island.view)
                    island.didMove(toParent: host)
                    island.view.frame = CGRect(x: 32, y: 780, width: 338, height: 64)
                    self.island = island
                    return island
                },
                current: { [unowned self] in island },
                close: { [unowned self] done in
                    let finish = { [unowned self] in
                        removeIsland()
                        done()
                    }
                    if holdsClose { heldClose = finish } else { finish() }
                },
                hidePlusButton: { [unowned self] in plusHidden += 1 },
                restore: { [unowned self] in restored += 1 }
            )
        }

        func removeIsland() {
            island?.view.removeFromSuperview()
            island?.removeFromParent()
            island = nil
        }
    }

    private func makeProgress() -> (progress: DropProgressIsland, screen: Screen) {
        let screen = Screen()
        addTeardownBlock { screen.window.isHidden = true }
        let progress = DropProgressIsland(handlers: screen.handlers(), announce: { [unowned screen] in screen.said.append($0) })
        return (progress, screen)
    }

    private func waitUntil(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 3) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }
    }

    func testTwoDrops_OpenOneCircle_AndHideThePlusButtonOnce() {
        let (progress, screen) = makeProgress()

        progress.moveStarted()
        progress.moveStarted()

        XCTAssertEqual(screen.opened, 1)
        XCTAssertEqual(screen.plusHidden, 1)
        XCTAssertTrue(progress.isShowing)
        XCTAssertEqual(screen.said, ["Moving"], "VoiceOver hears the start once")
    }

    func testTheLastSuccess_ShowsTheCheck_ThenCloses_AndRestoresTheScreen() {
        let (progress, screen) = makeProgress()
        progress.moveStarted()

        progress.moveEnded(succeeded: true)

        XCTAssertEqual(screen.said, ["Moving", "Moved"])
        XCTAssertNotNil(screen.island, "the check mark shows first")
        waitUntil(screen.restored == 1)
        XCTAssertNil(screen.island)
        XCTAssertFalse(progress.isShowing)
        XCTAssertEqual(screen.restored, 1)
    }

    func testAFailedMove_ClosesAtOnce_WithoutTheCheck() {
        let (progress, screen) = makeProgress()
        progress.moveStarted()

        progress.moveEnded(succeeded: false)

        XCTAssertNil(screen.island)
        XCTAssertEqual(screen.restored, 1)
        XCTAssertEqual(screen.said, ["Moving"], "the error alert speaks for itself")
    }

    func testADropDuringTheCheck_TakesOverTheCircle_AndTheCheckWaits() {
        let (progress, screen) = makeProgress()
        progress.moveStarted()
        progress.moveEnded(succeeded: true)
        let circle = screen.island as? CountingIsland

        progress.moveStarted()
        waitUntil(circle?.finishedChecks == 1)

        XCTAssertEqual(circle?.finishedChecks, 1)
        XCTAssertEqual(screen.opened, 1)
        XCTAssertNotNil(screen.island, "the first check leaves the circle up while a drop runs")
        XCTAssertEqual(screen.said, ["Moving", "Moved", "Moving"])

        progress.moveEnded(succeeded: true)
        waitUntil(screen.restored == 1)
        XCTAssertNil(screen.island)
        XCTAssertEqual(screen.restored, 1)
    }

    func testADropDuringTheClose_GetsACircleOfItsOwn() {
        let (progress, screen) = makeProgress()
        screen.holdsClose = true
        progress.moveStarted()
        progress.moveEnded(succeeded: false)
        XCTAssertNotNil(screen.heldClose, "the island is closing")

        progress.moveStarted()
        screen.heldClose?()

        XCTAssertEqual(screen.opened, 2, "the closed island is replaced by a new circle")
        XCTAssertTrue(progress.isShowing)
        XCTAssertEqual(screen.restored, 0, "the screen is restored only after the last drop")
        XCTAssertEqual(screen.said, ["Moving", "Moving"])
    }

    func testAMoveBarOnScreen_KeepsItsPlace() {
        let (progress, screen) = makeProgress()
        screen.island = FloatingActionIslandViewController()

        progress.moveStarted()
        progress.moveEnded(succeeded: true)

        XCTAssertEqual(screen.opened, 0)
        XCTAssertEqual(screen.plusHidden, 0)
        XCTAssertFalse(progress.isShowing)
        XCTAssertEqual(screen.restored, 0)
        XCTAssertEqual(screen.said, [], "no circle shows, so VoiceOver hears nothing")
    }

    func testWhenTheScreenClosesTheCircle_TheHelperLetsGo_AndLeavesTheNextBarAlone() {
        let (progress, screen) = makeProgress()
        progress.moveStarted()

        // A delete closes the island, then a Move bar opens.
        screen.removeIsland()
        XCTAssertFalse(progress.isShowing, "the plus button gate is not held shut")
        let moveBar = FloatingActionIslandViewController()
        screen.island = moveBar

        progress.moveEnded(succeeded: true)

        XCTAssertTrue(screen.island === moveBar)
        XCTAssertFalse(progress.isShowing)
        XCTAssertEqual(screen.restored, 0)
        XCTAssertEqual(screen.said, ["Moving"])
    }
}
