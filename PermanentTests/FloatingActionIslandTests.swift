//
//  FloatingActionIslandTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 01.10.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class FloatingActionIslandTests: XCTestCase {
    /// The island widths on 375, 390, 393, 402 and 440 pt wide phones.
    private let phoneWidths: [CGFloat] = [311, 326, 329, 338, 376]

    /// The select-mode bar as the file screens build it: the count, then Copy, Move and More.
    private func makeIsland(width: CGFloat, more: @escaping () -> Void = {}) -> FloatingActionIslandViewController {
        let blank = UIColor.clear.imageWithColor(width: 0, height: 0)
        let island = FloatingActionIslandViewController()
        island.leftItems = [FloatingActionTextItem(text: "7 Items", action: nil)]
        island.rightItems = [
            FloatingActionImageItem(image: UIImage(named: "floatingCopy")!, action: { _, _ in }),
            FloatingActionImageItem(image: blank, action: nil),
            FloatingActionImageItem(image: UIImage(named: "floatingMove")!, action: { _, _ in }),
            FloatingActionImageItem(image: blank, action: nil),
            FloatingActionImageItem(image: UIImage(named: "floatingMore")!.templated!, action: { _, _ in more() }),
        ]
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: width + 64, height: 300))
        let host = UIViewController()
        window.rootViewController = host
        window.isHidden = false
        host.addChild(island)
        host.view.addSubview(island.view)
        island.didMove(toParent: host)
        island.view.frame = CGRect(x: 32, y: 100, width: width, height: 64)
        island.view.layoutIfNeeded()
        // The items show once the pill has opened; the test skips that animation.
        island.view.subviews.filter(\.isHidden).forEach { $0.isHidden = false }
        island.view.layoutIfNeeded()
        addTeardownBlock { window.isHidden = true }
        return island
    }

    private func buttons(in island: FloatingActionIslandViewController) -> [UIButton] {
        func all(_ view: UIView) -> [UIView] { view.subviews + view.subviews.flatMap(all) }
        return all(island.view).compactMap { $0 as? UIButton }.filter { $0.window != nil && !$0.isHidden }
    }

    func testEveryItem_StaysInsideThePill_OnEveryPhoneWidth() {
        for width in phoneWidths {
            let island = makeIsland(width: width)
            let shown = buttons(in: island)

            XCTAssertEqual(shown.count, 4, "the count, Copy, Move and More at \(width) pt; none of them moves into an overflow button")
            for button in shown {
                let frame = button.convert(button.bounds, to: island.view)
                XCTAssertTrue(island.view.bounds.insetBy(dx: 16, dy: 0).contains(frame), "\(frame) sits inside the pill at \(width) pt")
            }
        }
    }

    func testTheIcons_KeepATapTargetOf44Points() {
        let island = makeIsland(width: phoneWidths[0])
        let icons = buttons(in: island).filter { $0.bounds.width < 60 }

        XCTAssertEqual(icons.count, 3)
        icons.forEach { XCTAssertGreaterThanOrEqual($0.bounds.width, 44) }
    }

    func testTheMoreButton_RunsItsAction() {
        var opened = 0
        let island = makeIsland(width: phoneWidths[1], more: { opened += 1 })
        let more = buttons(in: island).max { $0.convert($0.bounds, to: island.view).minX < $1.convert($1.bounds, to: island.view).minX }

        more?.sendActions(for: .touchUpInside)

        XCTAssertEqual(opened, 1, "the last button opens the selection's sheet")
    }
}
