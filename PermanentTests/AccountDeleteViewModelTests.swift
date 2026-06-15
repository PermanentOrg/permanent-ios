//
//  AccountDeleteViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.

import XCTest
@testable import Permanent

final class AccountDeleteViewModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testViewModel_CanBeInstantiated() {
        let viewModel = AccountDeleteViewModel()

        XCTAssertNotNil(viewModel, "AccountDeleteViewModel should be instantiable")
    }

    // MARK: - Protocol Conformance Tests

    func testViewModel_ConformsToViewModelInterface() {
        let viewModel = AccountDeleteViewModel()

        XCTAssertTrue(viewModel is ViewModelInterface, "AccountDeleteViewModel should conform to ViewModelInterface")
    }

    // MARK: - Notification Name Tests

    func testNotificationName_HasExpectedValue() {
        let expectedName = Notification.Name("AccountDeleteViewModel.accountDeleteSuccessNotification")

        XCTAssertEqual(
            AccountDeleteViewModel.accountDeleteSuccessNotification,
            expectedName,
            "Notification name should match the expected string value"
        )
    }

    func testNotificationName_IsAccessibleAsStaticProperty() {
        let name = AccountDeleteViewModel.accountDeleteSuccessNotification

        XCTAssertFalse(name.rawValue.isEmpty, "Notification name should not be empty")
    }

    // MARK: - Delete Account Tests
    //
    // DO NOT call viewModel.deleteAccount() from a unit test. It is NOT mockable:
    // it reads AuthenticationManager.shared.session and hits the real
    // /account/delete endpoint via APIRequestDispatcher(). These tests assumed no
    // active session (so deleteAccount would early-return false), but the session
    // persists in the shared keychain across runs — if any account is logged in on
    // the test host, running them DELETES that real account on the backend.
    //
    // Safe coverage requires making AccountDeleteViewModel injectable (a session
    // provider + dispatcher seam, like FilePreviewViewModel's ReachabilityProviding)
    // and asserting against a mock. Until then, the delete path is left untested
    // here rather than risk destroying a live account.

    // MARK: - ViewModelInterface Default Methods Tests

    func testViewModelInterface_DefaultMethodsDoNotCrash() {
        let viewModel = AccountDeleteViewModel()

        // These default protocol methods should execute without crashing
        viewModel.viewDidLoad()
        viewModel.viewWillAppear()
        viewModel.viewWillDisappear()

        XCTAssertTrue(true, "Default ViewModelInterface methods should not crash")
    }
}
