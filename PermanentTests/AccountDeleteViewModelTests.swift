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
    // DO NOT call `deleteAccount()` from a test: it reads the shared session and hits the real
    // endpoint, so with an account logged in on the test host it DELETES that real account.

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
