//
//  AuthenticationViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class AuthenticationViewRenderingTests: XCTestCase {

    // MARK: - AuthVerifyIdentityViewModel Tests

    func testAuthVerifyIdentityViewModel_InitialState() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        XCTAssertEqual(vm.pinCode, "")
        XCTAssertFalse(vm.digitsDisabled)
    }

    func testAuthVerifyIdentityViewModel_PinCodeCanBeSet() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        vm.pinCode = "1234"
        XCTAssertEqual(vm.pinCode, "1234")
    }

    func testAuthVerifyIdentityViewModel_DigitsDisabledCanBeSet() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        vm.digitsDisabled = true
        XCTAssertTrue(vm.digitsDisabled)
    }

    func testAuthVerifyIdentityViewModel_HoldsContainerReference() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    func testAuthVerifyIdentityViewModel_Verify2FA_ShortPinReturnsEmptyPinCode() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        vm.pinCode = "12"
        let expectation = XCTestExpectation(description: "Verify 2FA with short pin")
        vm.verify2FA { result in
            XCTAssertEqual(result, .emptyPinCode)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(vm.digitsDisabled)
    }

    func testAuthVerifyIdentityViewModel_Verify2FA_EmptyPinReturnsEmptyPinCode() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        vm.pinCode = ""
        let expectation = XCTestExpectation(description: "Verify 2FA with empty pin")
        vm.verify2FA { result in
            XCTAssertEqual(result, .emptyPinCode)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1)
    }

    func testAuthVerifyIdentityViewModel_Verify2FA_ShortPinDisplaysErrorBanner() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        vm.pinCode = "1"
        vm.verify2FA { _ in }

        XCTAssertEqual(container.bannerErrorMessage, .emptyPinCode)
    }

    // MARK: - ForgotPasswordViewModel Tests

    func testForgotPasswordViewModel_InitialState() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertEqual(vm.email, "")
        XCTAssertNil(vm.requestStatus)
    }

    func testForgotPasswordViewModel_EmailCanBeSet() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        vm.email = "test@example.com"
        XCTAssertEqual(vm.email, "test@example.com")
    }

    func testForgotPasswordViewModel_AreFieldsValid_ValidEmail_ReturnsTrue() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertTrue(vm.areFieldsValid(emailField: "user@example.com"))
    }

    func testForgotPasswordViewModel_AreFieldsValid_InvalidEmail_ReturnsFalse() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "not-an-email"))
    }

    func testForgotPasswordViewModel_AreFieldsValid_EmptyString_ReturnsFalse() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: ""))
    }

    func testForgotPasswordViewModel_AreFieldsValid_Nil_ReturnsFalse() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: nil))
    }

    func testForgotPasswordViewModel_MakeForgotPasswordRequest_InvalidEmail_ShowsErrorBanner() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        vm.email = "invalid"
        vm.makeForgotPasswordRequest()

        XCTAssertEqual(container.bannerErrorMessage, .invalidData)
    }

    func testForgotPasswordViewModel_HoldsContainerReference() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    // MARK: - AuthVerifyIdentityView Rendering Tests

    func testAuthVerifyIdentityView_RendersWithoutCrash() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        let host = hostView(AuthVerifyIdentityView(viewModel: vm) {})
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testAuthVerifyIdentityView_RendersWithPinCode() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)
        vm.pinCode = "1234"

        let host = hostView(AuthVerifyIdentityView(viewModel: vm) {})
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testAuthVerifyIdentityView_RendersWithDisabledDigits() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)
        vm.digitsDisabled = true

        let host = hostView(AuthVerifyIdentityView(viewModel: vm) {})
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testAuthVerifyIdentityView_RendersWhileLoading() {
        let container = AuthenticatorContainerViewModel()
        container.isLoading = true
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        let host = hostView(AuthVerifyIdentityView(viewModel: vm) {})
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - ForgotPasswordView Rendering Tests

    func testForgotPasswordView_RendersWithoutCrash() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        let host = hostView(ForgotPasswordView(viewModel: vm) {})
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testForgotPasswordView_RendersWithEmail() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)
        vm.email = "user@example.com"

        let host = hostView(ForgotPasswordView(viewModel: vm) {})
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testForgotPasswordView_RendersWhileLoading() {
        let container = AuthenticatorContainerViewModel()
        container.isLoading = true
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        let host = hostView(ForgotPasswordView(viewModel: vm) {})
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testForgotPasswordView_RendersWithErrorBanner() {
        let container = AuthenticatorContainerViewModel()
        container.displayErrorBanner(bannerErrorMessage: .invalidData)
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        let host = hostView(ForgotPasswordView(viewModel: vm) {})
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
