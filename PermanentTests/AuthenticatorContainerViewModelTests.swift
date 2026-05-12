//
//  AuthenticatorContainerViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class AuthenticatorContainerViewModelTests: XCTestCase {

    // MARK: - AuthenticatorContainerViewModel Initial State

    func testViewModel_InitialState_DefaultLogin() {
        let vm = AuthenticatorContainerViewModel()

        XCTAssertEqual(vm.contentType, .login)
        XCTAssertEqual(vm.firstViewContentType, .login)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.accountWasDeleted)
        XCTAssertFalse(vm.maintenanceTopBannerWasDisplayed)
        XCTAssertFalse(vm.showErrorBanner)
        XCTAssertEqual(vm.bannerErrorMessage, .none)
        XCTAssertEqual(vm.username, "")
        XCTAssertEqual(vm.password, "")
        XCTAssertNil(vm.mfaSession)
    }

    func testViewModel_InitialState_CustomContentType() {
        let vm = AuthenticatorContainerViewModel(contentType: .register)

        XCTAssertEqual(vm.contentType, .register)
    }

    func testViewModel_InitialState_ForgotPassword() {
        let vm = AuthenticatorContainerViewModel(contentType: .forgotPassword)

        XCTAssertEqual(vm.contentType, .forgotPassword)
    }

    // MARK: - AuthenticatorContainerViewModel setContentType

    func testViewModel_SetContentType_ChangesContentType() {
        let vm = AuthenticatorContainerViewModel()

        vm.setContentType(.register)
        XCTAssertEqual(vm.contentType, .register)
    }

    func testViewModel_SetContentType_ToVerifyIdentity() {
        let vm = AuthenticatorContainerViewModel()

        vm.setContentType(.verifyIdentity)
        XCTAssertEqual(vm.contentType, .verifyIdentity)
    }

    func testViewModel_SetContentType_ToForgotPasswordConfirmation() {
        let vm = AuthenticatorContainerViewModel()

        vm.setContentType(.forgotPasswordConfirmation)
        XCTAssertEqual(vm.contentType, .forgotPasswordConfirmation)
    }

    func testViewModel_SetContentType_BackToLogin() {
        let vm = AuthenticatorContainerViewModel(contentType: .register)

        vm.setContentType(.login)
        XCTAssertEqual(vm.contentType, .login)
    }

    // MARK: - AuthenticatorContainerViewModel displayErrorBanner

    func testViewModel_DisplayErrorBanner_SetsMessage() {
        let vm = AuthenticatorContainerViewModel()

        vm.displayErrorBanner(bannerErrorMessage: .invalidCredentials)
        XCTAssertEqual(vm.bannerErrorMessage, .invalidCredentials)
    }

    func testViewModel_DisplayErrorBanner_InvalidPassword() {
        let vm = AuthenticatorContainerViewModel()

        vm.displayErrorBanner(bannerErrorMessage: .invalidPassword)
        XCTAssertEqual(vm.bannerErrorMessage, .invalidPassword)
    }

    func testViewModel_DisplayErrorBanner_InvalidEmail() {
        let vm = AuthenticatorContainerViewModel()

        vm.displayErrorBanner(bannerErrorMessage: .invalidEmail)
        XCTAssertEqual(vm.bannerErrorMessage, .invalidEmail)
    }

    // MARK: - AuthenticatorContainerViewModel Properties

    func testViewModel_AllPropertiesCanBeSet() {
        let vm = AuthenticatorContainerViewModel()

        vm.username = "user@test.com"
        vm.password = "secretPass123"
        vm.isLoading = true
        vm.accountWasDeleted = true
        vm.maintenanceTopBannerWasDisplayed = true
        vm.showErrorBanner = true

        XCTAssertEqual(vm.username, "user@test.com")
        XCTAssertEqual(vm.password, "secretPass123")
        XCTAssertTrue(vm.isLoading)
        XCTAssertTrue(vm.accountWasDeleted)
        XCTAssertTrue(vm.maintenanceTopBannerWasDisplayed)
        XCTAssertTrue(vm.showErrorBanner)
    }

    // MARK: - AuthContentType Enum

    func testAuthContentType_AllKnownCasesExist() {
        let knownCases: [AuthContentType] = [
            .login, .register, .verifyIdentity,
            .forgotPassword, .forgotPasswordConfirmation, .none
        ]
        XCTAssertEqual(knownCases.count, 6)
    }

    // MARK: - AuthLeftSideViewModel

    func testAuthLeftSideVM_InitialState() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthLeftSideViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    func testAuthLeftSideVM_HoldsContainerReference() {
        let container = AuthenticatorContainerViewModel(contentType: .register)
        let vm = AuthLeftSideViewModel(containerViewModel: container)

        XCTAssertEqual(vm.containerViewModel.contentType, .register)
    }

    // MARK: - AuthenticatorContainerView Rendering

    func testAuthenticatorContainerView_RendersWithLogin() {
        let vm = AuthenticatorContainerViewModel(contentType: .login)
        let view = AuthenticatorContainerView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testAuthenticatorContainerView_RendersWithRegister() {
        let vm = AuthenticatorContainerViewModel(contentType: .register)
        let view = AuthenticatorContainerView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testAuthLeftSideView_Renders() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthLeftSideViewModel(containerViewModel: container)
        let view = AuthLeftSideView(viewModel: vm, startExploringAction: {})
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
