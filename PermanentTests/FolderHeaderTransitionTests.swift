//
//  FolderHeaderTransitionTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 01.10.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class FolderHeaderTransitionTests: XCTestCase {
    /// A test window is never drawn, and a view that was never drawn has no snapshot of its own.
    private final class SnapshotLabel: UILabel {
        override func snapshotView(afterScreenUpdates: Bool) -> UIView? { UIView() }
    }

    /// The header row as the folder screens build it: the back arrow, hidden at the root, then the folder name.
    private func hostedHeader() -> (header: FolderHeaderTransition, row: UIStackView, label: UILabel) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let back = UIButton(type: .system)
        back.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        back.isHidden = true
        let label = SnapshotLabel()
        label.text = "Private Files"
        let row = UIStackView(arrangedSubviews: [back, label])
        row.frame = CGRect(x: 0, y: 100, width: 390, height: 44)
        let container = UIView(frame: window.bounds)
        container.addSubview(row)
        window.addSubview(container)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        let header = FolderHeaderTransition(backButton: back, titleLabel: label)
        container.layoutIfNeeded()
        return (header, row, label)
    }

    private func waitUntil(_ condition: @autoclosure () -> Bool, timeout: TimeInterval = 2) {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            RunLoop.main.run(until: Date().addingTimeInterval(0.02))
        }
    }

    func testANewName_FadesInOnlyOnceTheOldOneHasFadedOut() throws {
        let (header, row, label) = hostedHeader()
        let before = row.subviews.count

        header.show(title: "aaaa", showsBack: false)

        XCTAssertEqual(label.text, "aaaa", "the label holds only the new name")
        XCTAssertEqual(row.subviews.count, before + 1, "a copy of the old name fades out over it")
        let copy = try XCTUnwrap(row.subviews.last)
        let fadeOut = try XCTUnwrap(copy.layer.animation(forKey: "opacity"))
        let fadeIn = try XCTUnwrap(label.layer.animation(forKey: "opacity"))
        XCTAssertGreaterThan(fadeIn.beginTime - fadeOut.beginTime, 0.1, "the new name starts once the old one has gone")
        waitUntil(row.subviews.count == before)
        XCTAssertEqual(row.subviews.count, before)
        XCTAssertEqual(label.alpha, 1)
    }

    func testTheOldName_MovesWithTheLabel_AsTheArrowComesIn() throws {
        let (header, row, label) = hostedHeader()
        let startX = label.frame.minX

        header.show(title: "aaaa", showsBack: true)

        row.layoutIfNeeded()
        let copy = try XCTUnwrap(row.subviews.last { !row.arrangedSubviews.contains($0) })
        XCTAssertGreaterThan(label.frame.minX, startX, "the arrow takes the leading room")
        XCTAssertEqual(copy.frame.minX, label.frame.minX, "the old name goes along, not under the arrow")
    }

    func testTheOldName_StaysPut_AsTheArrowGoes() throws {
        let (header, row, label) = hostedHeader()
        header.show(title: "aaaa", showsBack: true, animated: false)
        row.layoutIfNeeded()
        let besideTheArrow = label.frame.minX

        header.show(title: "Private Files", showsBack: false)

        row.layoutIfNeeded()
        let copy = try XCTUnwrap(row.subviews.last { !row.arrangedSubviews.contains($0) })
        XCTAssertEqual(copy.frame.minX, besideTheArrow, accuracy: 0.5, "it fades where it was, clear of the fading arrow")
    }
}
