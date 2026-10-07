//
//  FileContextMenuTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class FileContextMenuTests: XCTestCase {
    private typealias ItemType = FileMenuItems.ItemType
    private let ownerFile: [ItemType] = [.shareToPermanent, .shareToAnotherApp, .publish, .fileInformation, .rename, .move, .copy, .download, .delete]
    private let ownerFolder: [ItemType] = [.shareToPermanent, .publish, .rename, .move, .copy, .delete]

    private func groups(_ types: [ItemType], perform: @escaping (ItemType) -> Void = { _ in }) -> [UIMenu] {
        let children = FileContextMenu.make(for: types, perform: perform).children
        let menus = children.compactMap { $0 as? UIMenu }
        XCTAssertEqual(menus.count, children.count, "every top-level element is a group")
        return menus
    }

    private func actions(in menu: UIMenu) -> [UIAction] {
        menu.children.compactMap { $0 as? UIAction }
    }

    /// UIKit keeps an action's handler under the "handler" key; there is no public way to fire one.
    private func perform(_ action: UIAction) throws {
        guard action.responds(to: NSSelectorFromString("handler")) else {
            throw XCTSkip("UIAction no longer exposes its handler")
        }
        typealias Handler = @convention(block) (UIAction) -> Void
        let handler = try XCTUnwrap(action.value(forKey: "handler"))
        unsafeBitCast(handler as AnyObject, to: Handler.self)(action)
    }

    func testOwnerMenu_IsTheFilesLayout_ATopRowThenTwoGroups() {
        let groups = groups(ownerFile)
        XCTAssertEqual(groups.map { actions(in: $0).map(\.title) }, [
            ["Copy", "Move", "Share"],
            ["Share and manage access", "Publish on the web", "File information", "Rename"],
            ["Delete"]
        ])
        XCTAssertTrue(groups.allSatisfy { $0.options.contains(.displayInline) })
        XCTAssertEqual(groups[0].preferredElementSize, .medium, "Copy, Move and Share sit side by side")
    }

    func testAFolder_HasOnlyCopyAndMoveOnTop_SinceItCannotBeSentToAnotherApp() {
        XCTAssertEqual(groups(ownerFolder).map { actions(in: $0).map(\.title) }, [
            ["Copy", "Move"],
            ["Share and manage access", "Publish on the web", "Rename"],
            ["Delete"]
        ])
    }

    func testTheTopShare_OpensTheShareSheet_AndSaveStaysInTheSheet() throws {
        var picked: [ItemType] = []
        let all = groups(ownerFile) { picked.append($0) }.flatMap { actions(in: $0) }
        try perform(try XCTUnwrap(all.first { $0.title == "Share" }))

        XCTAssertEqual(picked, [.shareToAnotherApp])
        XCTAssertFalse(all.contains { $0.title == "Save" || $0.title == "Save or send a copy" }, "one way to share, as in Files")
    }

    func testViewerMenu_IsOnlyFileInformation_WithNoEmptyGroups() {
        XCTAssertEqual(groups([.fileInformation, .download]).map { actions(in: $0).map(\.title) }, [["File information"]])
    }

    func testAMenuWithOnlySave_HasNothingToShow() {
        XCTAssertFalse(FileContextMenu.hasActions(for: [.download]))
        XCTAssertFalse(FileContextMenu.hasActions(for: []))
        XCTAssertTrue(FileContextMenu.hasActions(for: [.download, .unshare]))
    }

    func testDeleteAndLeaveShare_AreRed_AndNothingElseIs() {
        for types in [ownerFile, [.download, .unshare]] {
            let all = groups(types).flatMap { actions(in: $0) }
            XCTAssertEqual(all.filter { $0.attributes.contains(.destructive) }.map(\.title), [types.contains(.unshare) ? "Leave share" : "Delete"])
        }
    }

    func testEveryItem_HasAnIconAndAnIdentifierForUITests() {
        let all = groups(ownerFile + [.unshare]).flatMap { actions(in: $0) }
        XCTAssertEqual(all.count, 9)
        XCTAssertTrue(all.allSatisfy { $0.image != nil })
        XCTAssertEqual(all.first?.accessibilityIdentifier, "fileContextMenu.copy")
    }

    func testPickingAnItem_ReportsItsType() throws {
        var picked: [ItemType] = []
        let rename = try XCTUnwrap(groups(ownerFile) { picked.append($0) }.flatMap { actions(in: $0) }.first { $0.title == "Rename" })
        try perform(rename)
        XCTAssertEqual(picked, [.rename])
    }

    func testIdentifier_NamesTheItemNotItsRow() {
        let one = FileModel(name: "a.jpg", recordId: 1, folderLinkId: 10, archiveNbr: "0001", type: "type.record.image", permissions: [.read])
        let other = FileModel(name: "a.jpg", recordId: 1, folderLinkId: 11, archiveNbr: "0001", type: "type.record.image", permissions: [.read])
        XCTAssertEqual(FileContextMenu.identifier(for: one), FileContextMenu.identifier(for: one))
        XCTAssertNotEqual(FileContextMenu.identifier(for: one), FileContextMenu.identifier(for: other))
    }

    /// The file lists inset their content 6 pt and make each row as wide as the screen, so a row runs off the right edge.
    func testLiftedRow_IsRounded_And8PointsInFromBothSidesOfTheScreen() throws {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let list = UICollectionView(frame: window.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        window.addSubview(list)
        list.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        list.contentOffset = CGPoint(x: -6, y: 0)
        let cell = UICollectionViewCell(frame: CGRect(x: 0, y: 200, width: 390, height: 74))
        list.addSubview(cell)

        let path = try XCTUnwrap(FileContextMenu.preview(for: cell, in: list).parameters.visiblePath)
        XCTAssertEqual(path.bounds, CGRect(x: 2, y: 0, width: 374, height: 74), "8 to 382 pt on the 390 pt screen")
    }
}
