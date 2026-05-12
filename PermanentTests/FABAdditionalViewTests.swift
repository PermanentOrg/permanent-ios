//
//  FABAdditionalViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class FABAdditionalViewTests: XCTestCase {

    // MARK: - CreateNewFolderViewModel Initial State

    func testCreateNewFolderViewModel_InitialState() {
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: {})

        XCTAssertEqual(vm.folderName, "")
        XCTAssertFalse(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 0)
    }

    // MARK: - CreateNewFolderViewModel isCreateButtonEnabled

    func testCreateNewFolderViewModel_IsCreateButtonEnabled_EmptyName_False() {
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: {})

        XCTAssertFalse(vm.isCreateButtonEnabled)
    }

    func testCreateNewFolderViewModel_IsCreateButtonEnabled_WhitespaceName_False() {
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: {})

        vm.folderName = "   "
        XCTAssertFalse(vm.isCreateButtonEnabled)
    }

    func testCreateNewFolderViewModel_IsCreateButtonEnabled_ValidName_True() {
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: {})

        vm.folderName = "My Folder"
        XCTAssertTrue(vm.isCreateButtonEnabled)
    }

    func testCreateNewFolderViewModel_IsCreateButtonEnabled_SingleChar_True() {
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: {})

        vm.folderName = "A"
        XCTAssertTrue(vm.isCreateButtonEnabled)
    }

    // MARK: - CreateNewFolderViewModel Presentation Animation

    func testCreateNewFolderViewModel_StartPresentationAnimation() {
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: {})

        vm.startPresentationAnimation()

        XCTAssertTrue(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 1.0)
    }

    // MARK: - CreateNewFolderViewModel Create Folder

    func testCreateNewFolderViewModel_CreateFolder_CallsCallback() {
        var createdFolderName: String?
        var dismissCalled = false
        let vm = CreateNewFolderViewModel(
            onCreateFolder: { name in createdFolderName = name },
            onDismiss: { dismissCalled = true }
        )

        vm.createFolder(name: "New Folder")

        XCTAssertEqual(createdFolderName, "New Folder")
        XCTAssertTrue(dismissCalled)
    }

    // MARK: - CreateNewFolderViewModel CallOnDismiss

    func testCreateNewFolderViewModel_CallOnDismiss() {
        var dismissed = false
        let vm = CreateNewFolderViewModel(onCreateFolder: { _ in }, onDismiss: { dismissed = true })

        vm.callOnDismiss()

        XCTAssertTrue(dismissed)
    }

    // MARK: - PublishViewModel Initial State

    func testPublishViewModel_InitialState_File() {
        let vm = PublishViewModel(
            fileName: "photo.jpg",
            isFolder: false,
            onPublish: {},
            onDismiss: {}
        )

        XCTAssertEqual(vm.fileName, "photo.jpg")
        XCTAssertFalse(vm.isFolder)
        XCTAssertNil(vm.thumbnailURL)
        XCTAssertNil(vm.thumbnailURL2000)
        XCTAssertFalse(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 0)
        XCTAssertFalse(vm.isHighResThumbnailLoaded)
    }

    func testPublishViewModel_InitialState_Folder() {
        let vm = PublishViewModel(
            fileName: "My Folder",
            isFolder: true,
            onPublish: {},
            onDismiss: {}
        )

        XCTAssertEqual(vm.fileName, "My Folder")
        XCTAssertTrue(vm.isFolder)
    }

    func testPublishViewModel_InitialState_WithThumbnails() {
        let vm = PublishViewModel(
            fileName: "photo.jpg",
            isFolder: false,
            thumbnailURL: "https://example.com/thumb500.jpg",
            thumbnailURL2000: "https://example.com/thumb2000.jpg",
            onPublish: {},
            onDismiss: {}
        )

        XCTAssertEqual(vm.thumbnailURL, "https://example.com/thumb500.jpg")
        XCTAssertEqual(vm.thumbnailURL2000, "https://example.com/thumb2000.jpg")
    }

    // MARK: - PublishViewModel Title

    func testPublishViewModel_Title_File() {
        let vm = PublishViewModel(fileName: "doc.pdf", isFolder: false, onPublish: {}, onDismiss: {})

        XCTAssertEqual(vm.title, "Publish file")
    }

    func testPublishViewModel_Title_Folder() {
        let vm = PublishViewModel(fileName: "Photos", isFolder: true, onPublish: {}, onDismiss: {})

        XCTAssertEqual(vm.title, "Publish folder")
    }

    // MARK: - PublishViewModel Presentation Animation

    func testPublishViewModel_StartPresentationAnimation() {
        let vm = PublishViewModel(fileName: "test", isFolder: false, onPublish: {}, onDismiss: {})

        vm.startPresentationAnimation()

        XCTAssertTrue(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 1.0)
    }

    // MARK: - PublishViewModel Publish

    func testPublishViewModel_Publish_CallsCallback() {
        var published = false
        let vm = PublishViewModel(fileName: "test", isFolder: false, onPublish: { published = true }, onDismiss: {})

        vm.publish()

        XCTAssertTrue(published)
    }

    // MARK: - PublishViewModel CallOnDismiss

    func testPublishViewModel_CallOnDismiss() {
        var dismissed = false
        let vm = PublishViewModel(fileName: "test", isFolder: false, onPublish: {}, onDismiss: { dismissed = true })

        vm.callOnDismiss()

        XCTAssertTrue(dismissed)
    }

    // MARK: - PublishViewModel Lifecycle

    func testPublishViewModel_PresentThenDismiss() {
        var dismissed = false
        let vm = PublishViewModel(fileName: "test", isFolder: false, onPublish: {}, onDismiss: { dismissed = true })

        vm.startPresentationAnimation()
        XCTAssertTrue(vm.isAnimating)

        vm.callOnDismiss()
        XCTAssertTrue(dismissed)
    }

    // MARK: - CreateNewFolderView Rendering Tests

    func testCreateNewFolderView_RendersWithoutCrash() {
        let view = CreateNewFolderView(onCreateFolder: { _ in })
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testCreateNewFolderView_RendersWithOnDismiss() {
        let view = CreateNewFolderView(onCreateFolder: { _ in }, onDismiss: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - PublishView Rendering Tests

    func testPublishView_RendersFile() {
        let view = PublishView(fileName: "photo.jpg", isFolder: false, onPublish: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testPublishView_RendersFolder() {
        let view = PublishView(fileName: "My Folder", isFolder: true, onPublish: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testPublishView_RendersWithThumbnail() {
        let view = PublishView(
            fileName: "photo.jpg",
            isFolder: false,
            thumbnailURL: "https://example.com/thumb.jpg",
            onPublish: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testPublishView_RendersWithOnDismiss() {
        let view = PublishView(fileName: "test", isFolder: false, onPublish: {}, onDismiss: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - Helpers

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }
}
