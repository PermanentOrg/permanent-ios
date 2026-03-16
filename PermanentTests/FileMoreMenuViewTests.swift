//
//  FileMoreMenuViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 13.03.2026.
//

import XCTest
import SwiftUI
import UIKit
@testable import Permanent

@MainActor
final class FileMoreMenuViewTests: XCTestCase {

    func testOnAppearTriggersViewModelPreparationCalls() async {
        let vm = makeSpyViewModel()
        let (host, _) = hostView(FileMoreMenuView(viewModel: vm))

        _ = host.view

        let appeared = await waitUntil(timeout: 1.0) {
            vm.prepareThumbnailCalled && vm.fetchAccessRoleCalled && vm.startAnimationCalled
        }

        XCTAssertTrue(appeared)
    }

    func testRendersWhenDeleteConfirmationStateIsEnabled() async {
        let vm = makeSpyViewModel()
        vm.showDeleteConfirmation = true

        let (host, _) = hostView(FileMoreMenuView(viewModel: vm))

        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertTrue(vm.showDeleteConfirmation)
    }

    private func makeSpyViewModel() -> SpyFileMenuViewModel {
        SpyFileMenuViewModel(
            fileViewModel: FileModel.mockFile(),
            menuItems: [],
            selectedItemCount: nil,
            selectedFiles: nil,
            showArchiveInfo: false,
            onDismiss: {}
        )
    }

    private func hostView<Content: View>(_ view: Content) -> (UIHostingController<Content>, UIWindow) {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return (host, window)
    }

    private func waitUntil(timeout: TimeInterval, condition: @escaping () -> Bool) async -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if condition() {
                return true
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
        return condition()
    }
}

@MainActor
private final class SpyFileMenuViewModel: FileMenuViewModel {
    var prepareThumbnailCalled = false
    var fetchAccessRoleCalled = false
    var startAnimationCalled = false

    override func prepareThumbnailForLoading() {
        prepareThumbnailCalled = true
    }

    override func fetchUpdatedAccessRole() {
        fetchAccessRoleCalled = true
    }

    override func startPresentationAnimation() {
        startAnimationCalled = true
    }

}
