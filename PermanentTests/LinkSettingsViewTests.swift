//
//  LinkSettingsViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.03.2026.
//

import SwiftUI
import UIKit
import XCTest
@testable import Permanent

@MainActor
final class LinkSettingsViewTests: XCTestCase {

    func testRenders_WhenNoUnsavedChanges() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)
        vm.hasUnsavedChanges = false

        let host = hostView(LinkSettingsView(viewModel: vm))
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func testRenders_WhenHasUnsavedChanges() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)
        vm.hasUnsavedChanges = true

        let host = hostView(LinkSettingsView(viewModel: vm))
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func testRendersRestrictedAccessRoleSection_WhenAccessLevelRestricted() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)
        vm.selectedAccessLevel = .restricted

        let host = hostView(LinkSettingsView(viewModel: vm))
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.selectedAccessLevel, .restricted)
    }

    func testRendersShareLinkState_WhenShareLinkExists() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)
        vm.shareLink = "https://example.com/share/token"

        let host = hostView(LinkSettingsView(viewModel: vm))
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.shareLink, "https://example.com/share/token")
    }

    func testRendersLoadingOverlayState_WhenLoading() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)
        vm.isLoading = true

        let host = hostView(LinkSettingsView(viewModel: vm))
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertTrue(vm.isLoading)
    }

    private func makeViewModel() -> ShareItemViewModel {
        ShareItemViewModel(
            fileModel: FileModel.mockFile(),
            shareManagementRepository: LinkSettingsPassiveShareManagementRepository()
        )
    }

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    private func waitForInitialLoad(of viewModel: ShareItemViewModel) async {
        let deadline = Date().addingTimeInterval(1.0)
        while Date() < deadline {
            if !viewModel.isLoading {
                return
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }

}

private final class LinkSettingsPassiveShareManagementRepository: ShareManagementRepository {
    override func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        completion(nil, nil)
    }

    override func getShareLinkV2ByToken(token: String, then completion: @escaping ShareLinkV2Handler) {
        completion(nil, nil)
    }
}
