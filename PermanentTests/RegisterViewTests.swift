//
//  RegisterViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.03.2026.
//

import SwiftUI
import UIKit
import XCTest
@testable import Permanent

@MainActor
final class RegisterViewTests: XCTestCase {

    func testRendersRegisterViewWithInitialState() async {
        let viewModel = RegisterViewModel(containerViewModel: AuthenticatorContainerViewModel())
        let view = RegisterView(viewModel: viewModel, loginSuccess: {})

        let host = hostView(view)
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertFalse(viewModel.areFieldsValid())
    }

    func testRendersRegisterViewWithValidFieldsAndTermsAccepted() async {
        let viewModel = RegisterViewModel(containerViewModel: AuthenticatorContainerViewModel())
        viewModel.fullname = "John Doe"
        viewModel.email = "john@example.com"
        viewModel.password = "password123"
        viewModel.agreeTermsAndConditions = true

        let view = RegisterView(viewModel: viewModel, loginSuccess: {})
        let host = hostView(view)
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertTrue(viewModel.areFieldsValid())
        XCTAssertTrue(viewModel.agreeTermsAndConditions)
    }

    func testRendersRegisterViewWhenSwitchingToKeyboardSpacingState() async {
        let viewModel = RegisterViewModel(containerViewModel: AuthenticatorContainerViewModel())
        let view = RegisterView(viewModel: viewModel, loginSuccess: {})

        let host = hostView(view)
        _ = host.view

        NotificationCenter.default.post(
            name: UIResponder.keyboardDidShowNotification,
            object: nil,
            userInfo: [UIResponder.keyboardFrameEndUserInfoKey: CGRect(x: 0, y: 0, width: 320, height: 300)]
        )

        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNotNil(host.view)
    }

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }
}
