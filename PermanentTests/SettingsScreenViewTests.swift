//
//  SettingsScreenViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class SettingsScreenViewTests: XCTestCase {

    // MARK: - SettingsScreenViewModel Initial State

    func testViewModel_InitialState() {
        let vm = SettingsScreenViewModel()

        XCTAssertEqual(vm.spaceRatio, 0.0)
        XCTAssertEqual(vm.spaceTotal, 0)
        XCTAssertEqual(vm.spaceLeft, 0)
        XCTAssertEqual(vm.spaceUsed, 0)
        XCTAssertEqual(vm.spaceTotalReadable, "")
        XCTAssertEqual(vm.spaceLeftReadable, "")
        XCTAssertEqual(vm.spaceUsedReadable, "")
        XCTAssertEqual(vm.accountFullName, "")
        XCTAssertEqual(vm.accountEmail, "")
        XCTAssertNil(vm.selectedArchiveThumbnailURL)
        XCTAssertFalse(vm.loggedOut)
    }

    // MARK: - SettingsScreenViewModel Properties

    func testViewModel_BooleanFlagsCanBeSet() {
        let vm = SettingsScreenViewModel()

        vm.showError = true
        vm.isLoading = true
        vm.loggedOut = true
        vm.twoFactorAuthenticationEnabled = true
        vm.isLoading2FAStatus = true
        vm.showFinishSetUpAccount = true

        XCTAssertTrue(vm.showError)
        XCTAssertTrue(vm.isLoading)
        XCTAssertTrue(vm.loggedOut)
        XCTAssertEqual(vm.twoFactorAuthenticationEnabled, true)
        XCTAssertTrue(vm.isLoading2FAStatus)
        XCTAssertTrue(vm.showFinishSetUpAccount)
    }

    func testViewModel_AccountDetailsCanBeSet() {
        let vm = SettingsScreenViewModel()

        vm.accountFullName = "John Doe"
        vm.accountEmail = "john@example.com"
        let method = TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890")
        vm.twoFactorMethods = [method]

        XCTAssertEqual(vm.accountFullName, "John Doe")
        XCTAssertEqual(vm.accountEmail, "john@example.com")
        XCTAssertEqual(vm.twoFactorMethods.count, 1)
        XCTAssertEqual(vm.twoFactorMethods[0].methodId, "1")
    }

    func testViewModel_SpaceProperties() {
        let vm = SettingsScreenViewModel()

        vm.spaceTotal = 1000
        vm.spaceLeft = 400
        vm.spaceUsed = 600
        vm.spaceRatio = 0.6

        XCTAssertEqual(vm.spaceTotal, 1000)
        XCTAssertEqual(vm.spaceLeft, 400)
        XCTAssertEqual(vm.spaceUsed, 600)
        XCTAssertEqual(vm.spaceRatio, 0.6, accuracy: 0.001)
    }

    func testViewModel_SelectedArchiveThumbnailURL() {
        let vm = SettingsScreenViewModel()

        let url = URL(string: "https://example.com/thumb.jpg")
        vm.selectedArchiveThumbnailURL = url

        XCTAssertEqual(vm.selectedArchiveThumbnailURL, url)
    }

    // MARK: - SettingsScreenView Rendering Tests

    func testSettingsScreenView_RendersWithoutCrash() {
        let router = SettingsRouter(rootViewController: RootNavigationController(viewController: UIViewController()))
        let view = SettingsScreenView(
            viewModel: StateObject(wrappedValue: SettingsScreenViewModel()),
            router: router
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testSettingsScreenView_RendersWhileLoading() {
        let router = SettingsRouter(rootViewController: RootNavigationController(viewController: UIViewController()))
        let vm = SettingsScreenViewModel()
        vm.isLoading = true
        let view = SettingsScreenView(
            viewModel: StateObject(wrappedValue: vm),
            router: router
        )
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
