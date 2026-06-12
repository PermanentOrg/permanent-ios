//
//  FABMenuViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class FABMenuViewTests: XCTestCase {

    // MARK: - FABMenuViewModel Initial State

    func testViewModel_InitialState() {
        let vm = FABMenuViewModel(onDismiss: {})

        XCTAssertFalse(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 0)
    }

    // MARK: - FABMenuViewModel Presentation Animation

    func testViewModel_StartPresentationAnimation_SetsIsAnimating() {
        let vm = FABMenuViewModel(onDismiss: {})

        vm.startPresentationAnimation()

        XCTAssertTrue(vm.isAnimating)
    }

    func testViewModel_StartPresentationAnimation_SetsBackgroundOpacity() {
        let vm = FABMenuViewModel(onDismiss: {})

        vm.startPresentationAnimation()

        XCTAssertEqual(vm.backgroundOpacity, 1.0)
    }

    // MARK: - FABMenuViewModel Dismiss Animation

    func testViewModel_DismissWithAnimation_ClearsIsAnimating() {
        let vm = FABMenuViewModel(onDismiss: {})
        vm.startPresentationAnimation()

        vm.dismissWithAnimation()

        XCTAssertFalse(vm.isAnimating)
    }

    func testViewModel_DismissWithAnimation_ClearsBackgroundOpacity() {
        let vm = FABMenuViewModel(onDismiss: {})
        vm.startPresentationAnimation()

        vm.dismissWithAnimation()

        XCTAssertEqual(vm.backgroundOpacity, 0)
    }

    func testViewModel_DismissWithAnimation_CallsOnDismiss() {
        var dismissed = false
        let vm = FABMenuViewModel(onDismiss: { dismissed = true })

        vm.dismissWithAnimation()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.3))

        XCTAssertTrue(dismissed)
    }

    // MARK: - FABMenuViewModel CallOnDismiss

    func testViewModel_CallOnDismiss_InvokesCallback() {
        var dismissed = false
        let vm = FABMenuViewModel(onDismiss: { dismissed = true })

        vm.callOnDismiss()

        XCTAssertTrue(dismissed)
    }

    // MARK: - FABMenuViewModel Property Toggle

    func testViewModel_AllPropertiesCanBeSetDirectly() {
        let vm = FABMenuViewModel(onDismiss: {})

        vm.isAnimating = true
        vm.backgroundOpacity = 0.5

        XCTAssertTrue(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 0.5)
    }

    // MARK: - FABMenuViewModel Lifecycle

    func testViewModel_PresentThenDismiss() {
        let vm = FABMenuViewModel(onDismiss: {})

        vm.startPresentationAnimation()
        XCTAssertTrue(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 1.0)

        vm.dismissWithAnimation()
        XCTAssertFalse(vm.isAnimating)
        XCTAssertEqual(vm.backgroundOpacity, 0)
    }

    // MARK: - FABMenuView Rendering Tests

    func testFABMenuView_RendersWithoutCrash() {
        let view = FABMenuView(
            onCreateFolder: {},
            onTakePhoto: {},
            onUploadPhotos: {},
            onBrowseFiles: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testFABMenuView_RendersWithOnDismiss() {
        let view = FABMenuView(
            onCreateFolder: {},
            onTakePhoto: {},
            onUploadPhotos: {},
            onBrowseFiles: {},
            onDismiss: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testFABMenuView_CallbacksAreStored() {
        var createFolderCalled = false
        var takePhotoCalled = false
        var uploadPhotosCalled = false
        var browseFilesCalled = false

        let view = FABMenuView(
            onCreateFolder: { createFolderCalled = true },
            onTakePhoto: { takePhotoCalled = true },
            onUploadPhotos: { uploadPhotosCalled = true },
            onBrowseFiles: { browseFilesCalled = true }
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
        XCTAssertFalse(createFolderCalled)
        XCTAssertFalse(takePhotoCalled)
        XCTAssertFalse(uploadPhotosCalled)
        XCTAssertFalse(browseFilesCalled)
    }

    // MARK: - FABMenuItemView Rendering Tests

    func testFABMenuItemView_RendersWithSystemIcon() {
        let view = FABMenuItemView(systemIcon: "folder.fill", title: "Create Folder", action: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testFABMenuItemView_RendersWithAssetImage() {
        let view = FABMenuItemView(assetImage: Image(systemName: "photo"), title: "Upload Photo", action: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testFABMenuItemView_RendersWithBold() {
        let view = FABMenuItemView(title: "Browse Files", isBold: true, action: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testFABMenuItemView_RendersWithoutIcons() {
        let view = FABMenuItemView(title: "Plain Item", action: {})
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
