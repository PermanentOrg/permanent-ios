//
//  FABViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class FABViewModelTests: XCTestCase {

    // MARK: - CreateNewFolderViewModel

    func testCreateNewFolder_InitialState() {
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: {})

        XCTAssertEqual(vm.folderName, "")
        XCTAssertFalse(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 0)
    }

    func testCreateNewFolder_IsCreateButtonEnabled_EmptyName() {
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: {})

        XCTAssertFalse(vm.isCreateButtonEnabled)
    }

    func testCreateNewFolder_IsCreateButtonEnabled_WhitespaceOnly() {
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: {})

        vm.folderName = "   "
        XCTAssertFalse(vm.isCreateButtonEnabled)
    }

    func testCreateNewFolder_IsCreateButtonEnabled_ValidName() {
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: {})

        vm.folderName = "My Folder"
        XCTAssertTrue(vm.isCreateButtonEnabled)
    }

    func testCreateNewFolder_CreateFolderCallsCallback() {
        var createdName: String?
        var dismissed = false
        let vm = CreateNewFolderViewModel(
            onCreateFolder: { name in createdName = name },
            onDismiss: { dismissed = true }
        )

        vm.createFolder(name: "Photos")
        XCTAssertEqual(createdName, "Photos")
        XCTAssertTrue(dismissed)
    }

    func testCreateNewFolder_CallOnDismiss() {
        var dismissed = false
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: { dismissed = true })

        vm.callOnDismiss()
        XCTAssertTrue(dismissed)
    }

    // MARK: - RenameViewModel

    func testRename_InitialState() {
        let vm = RenameViewModel(currentName: "Old Name", isFolder: true, onRename: { _ in }, onDismiss: {})

        XCTAssertEqual(vm.itemName, "Old Name")
        XCTAssertEqual(vm.originalName, "Old Name")
        XCTAssertTrue(vm.isFolder)
        XCTAssertFalse(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 0)
    }

    func testRename_TitleForFolder() {
        let vm = RenameViewModel(currentName: "Test", isFolder: true, onRename: { _ in }, onDismiss: {})
        XCTAssertEqual(vm.title, "Rename folder")
    }

    func testRename_TitleForFile() {
        let vm = RenameViewModel(currentName: "Test", isFolder: false, onRename: { _ in }, onDismiss: {})
        XCTAssertEqual(vm.title, "Rename file")
    }

    func testRename_IsRenameButtonEnabled_EmptyName() {
        let vm = RenameViewModel(currentName: "Test", isFolder: false, onRename: { _ in }, onDismiss: {})
        vm.itemName = ""
        XCTAssertFalse(vm.isRenameButtonEnabled)
    }

    func testRename_IsRenameButtonEnabled_ValidName() {
        let vm = RenameViewModel(currentName: "Test", isFolder: false, onRename: { _ in }, onDismiss: {})
        vm.itemName = "New Name"
        XCTAssertTrue(vm.isRenameButtonEnabled)
    }

    func testRename_HasNameChanged_SameName() {
        let vm = RenameViewModel(currentName: "Test", isFolder: false, onRename: { _ in }, onDismiss: {})
        XCTAssertFalse(vm.hasNameChanged)
    }

    func testRename_HasNameChanged_DifferentName() {
        let vm = RenameViewModel(currentName: "Test", isFolder: false, onRename: { _ in }, onDismiss: {})
        vm.itemName = "Updated Name"
        XCTAssertTrue(vm.hasNameChanged)
    }

    func testRename_HasNameChanged_WhitespaceOnly() {
        let vm = RenameViewModel(currentName: "Test", isFolder: false, onRename: { _ in }, onDismiss: {})
        vm.itemName = "   "
        XCTAssertFalse(vm.hasNameChanged)
    }

    func testRename_RenameCallsCallback() {
        var renamedTo: String?
        let vm = RenameViewModel(currentName: "Test", isFolder: false, onRename: { name in renamedTo = name }, onDismiss: {})

        vm.rename(newName: "New Name")
        XCTAssertEqual(renamedTo, "New Name")
    }

    func testRename_ThumbnailURL() {
        let vm = RenameViewModel(currentName: "Test", isFolder: false, thumbnailURL: "https://example.com/thumb.jpg", onRename: { _ in }, onDismiss: {})
        XCTAssertEqual(vm.thumbnailURL, "https://example.com/thumb.jpg")
    }

    // MARK: - PublishViewModel

    func testPublish_InitialState() {
        let vm = PublishViewModel(fileName: "doc.pdf", isFolder: false, onPublish: {}, onDismiss: {})

        XCTAssertEqual(vm.fileName, "doc.pdf")
        XCTAssertFalse(vm.isFolder)
        XCTAssertFalse(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 0)
        XCTAssertFalse(vm.isHighResThumbnailLoaded)
    }

    func testPublish_TitleForFolder() {
        let vm = PublishViewModel(fileName: "Photos", isFolder: true, onPublish: {}, onDismiss: {})
        XCTAssertEqual(vm.title, "Publish folder")
    }

    func testPublish_TitleForFile() {
        let vm = PublishViewModel(fileName: "doc.pdf", isFolder: false, onPublish: {}, onDismiss: {})
        XCTAssertEqual(vm.title, "Publish file")
    }

    func testPublish_PublishCallsCallback() {
        var published = false
        let vm = PublishViewModel(fileName: "doc.pdf", isFolder: false, onPublish: { published = true }, onDismiss: {})

        vm.publish()
        XCTAssertTrue(published)
    }

    func testPublish_ThumbnailURLs() {
        let vm = PublishViewModel(
            fileName: "doc.pdf",
            isFolder: false,
            thumbnailURL: "https://example.com/thumb.jpg",
            thumbnailURL2000: "https://example.com/thumb2000.jpg",
            onPublish: {},
            onDismiss: {}
        )
        XCTAssertEqual(vm.thumbnailURL, "https://example.com/thumb.jpg")
        XCTAssertEqual(vm.thumbnailURL2000, "https://example.com/thumb2000.jpg")
    }

    // MARK: - FABMenuViewModel

    func testFABMenu_InitialState() {
        let vm = FABMenuViewModel(onDismiss: {})

        XCTAssertFalse(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 0)
    }

    func testFABMenu_CallOnDismiss() {
        var dismissed = false
        let vm = FABMenuViewModel(onDismiss: { dismissed = true })

        vm.callOnDismiss()
        XCTAssertTrue(dismissed)
    }
}
