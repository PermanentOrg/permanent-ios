//
//  ForgotPasswordViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ForgotPasswordViewModelTests: XCTestCase {

    private func makeVM() -> ForgotPasswordViewModel {
        let container = AuthenticatorContainerViewModel()
        return ForgotPasswordViewModel(containerViewModel: container)
    }

    // MARK: - Initial State

    func testInit_EmailIsEmpty() {
        let vm = makeVM()
        XCTAssertEqual(vm.email, "")
    }

    func testInit_RequestStatusIsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.requestStatus)
    }

    func testInit_ContainerViewModelIsSet() {
        let vm = makeVM()
        XCTAssertNotNil(vm.containerViewModel)
    }

    // MARK: - areFieldsValid

    func testAreFieldsValid_ValidEmail_ReturnsTrue() {
        let vm = makeVM()
        XCTAssertTrue(vm.areFieldsValid(emailField: "user@example.com"))
    }

    func testAreFieldsValid_EmptyEmail_ReturnsFalse() {
        let vm = makeVM()
        XCTAssertFalse(vm.areFieldsValid(emailField: ""))
    }

    func testAreFieldsValid_NilEmail_ReturnsFalse() {
        let vm = makeVM()
        XCTAssertFalse(vm.areFieldsValid(emailField: nil))
    }

    func testAreFieldsValid_InvalidFormat_ReturnsFalse() {
        let vm = makeVM()
        XCTAssertFalse(vm.areFieldsValid(emailField: "notanemail"))
    }

    func testAreFieldsValid_MissingAtSign_ReturnsFalse() {
        let vm = makeVM()
        XCTAssertFalse(vm.areFieldsValid(emailField: "user.example.com"))
    }

    func testAreFieldsValid_MissingDomain_ReturnsFalse() {
        let vm = makeVM()
        XCTAssertFalse(vm.areFieldsValid(emailField: "user@"))
    }

    func testAreFieldsValid_WhitespaceOnly_ReturnsFalse() {
        let vm = makeVM()
        XCTAssertFalse(vm.areFieldsValid(emailField: "   "))
    }

    func testAreFieldsValid_ValidEmailWithPlus_ReturnsTrue() {
        let vm = makeVM()
        XCTAssertTrue(vm.areFieldsValid(emailField: "user+tag@example.com"))
    }

    // MARK: - Email property

    func testEmail_CanBeSet() {
        let vm = makeVM()
        vm.email = "test@test.com"
        XCTAssertEqual(vm.email, "test@test.com")
    }
}
