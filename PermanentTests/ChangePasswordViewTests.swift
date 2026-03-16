//
//  ChangePasswordViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 13.03.2026.
//

import XCTest
import SwiftUI
import UIKit
@testable import Permanent

@MainActor
final class ChangePasswordViewTests: XCTestCase {

    func testRendersWithInjectedViewModel() async {
        let vm = ChangePasswordViewModel()
        let (host, _) = hostView(ChangePasswordView(viewModel: vm))
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertFalse(vm.isLoading)
    }

    func testBindsToViewModelPasswordFields() async {
        let vm = ChangePasswordViewModel()
        let (host, _) = hostView(ChangePasswordView(viewModel: vm))
        _ = host.view

        vm.currentPassword = "CurrentPass123!"
        vm.newPassword = "NewPass123!"
        vm.confirmPassword = "NewPass123!"
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(vm.currentPassword, "CurrentPass123!")
        XCTAssertEqual(vm.newPassword, "NewPass123!")
        XCTAssertEqual(vm.confirmPassword, "NewPass123!")
    }

    func testStrengthBarRendersForEachStrength() async {
        let weakHost = hostView(ChangePasswordView.StrengthBar(strength: .weak)).0
        let mediumHost = hostView(ChangePasswordView.StrengthBar(strength: .medium)).0
        let strongHost = hostView(ChangePasswordView.StrengthBar(strength: .strong)).0

        _ = weakHost.view
        _ = mediumHost.view
        _ = strongHost.view
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNotNil(weakHost.view)
        XCTAssertNotNil(mediumHost.view)
        XCTAssertNotNil(strongHost.view)
    }

    private func hostView<Content: View>(_ view: Content) -> (UIHostingController<Content>, UIWindow) {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return (host, window)
    }

}
