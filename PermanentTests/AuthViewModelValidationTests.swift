//
//  AuthViewModelValidationTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class AuthViewModelValidationTests: XCTestCase {

    // MARK: - LoginViewModel Initial State

    func testLoginVM_InitialState() {
        let container = AuthenticatorContainerViewModel()
        let vm = LoginViewModel(containerViewModel: container)

        XCTAssertEqual(vm.username, "")
        XCTAssertEqual(vm.password, "")
        XCTAssertNil(vm.loginStatus)
        XCTAssertFalse(vm.isOfflineBannerDisplayed)
    }

    func testLoginVM_AllPropertiesCanBeSet() {
        let container = AuthenticatorContainerViewModel()
        let vm = LoginViewModel(containerViewModel: container)

        vm.username = "user@test.com"
        vm.password = "myPassword123"
        vm.isOfflineBannerDisplayed = true

        XCTAssertEqual(vm.username, "user@test.com")
        XCTAssertEqual(vm.password, "myPassword123")
        XCTAssertTrue(vm.isOfflineBannerDisplayed)
    }

    // MARK: - LoginViewModel areFieldsValid

    func testLoginVM_AreFieldsValid_ValidInputs() {
        let container = AuthenticatorContainerViewModel()
        let vm = LoginViewModel(containerViewModel: container)

        XCTAssertTrue(vm.areFieldsValid(emailField: "user@test.com", passwordField: "password123"))
    }

    func testLoginVM_AreFieldsValid_ShortPassword() {
        let container = AuthenticatorContainerViewModel()
        let vm = LoginViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "user@test.com", passwordField: "short"))
    }

    func testLoginVM_AreFieldsValid_InvalidEmail() {
        let container = AuthenticatorContainerViewModel()
        let vm = LoginViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "notanemail", passwordField: "password123"))
    }

    func testLoginVM_AreFieldsValid_EmptyEmail() {
        let container = AuthenticatorContainerViewModel()
        let vm = LoginViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "", passwordField: "password123"))
    }

    func testLoginVM_AreFieldsValid_NilEmail() {
        let container = AuthenticatorContainerViewModel()
        let vm = LoginViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: nil, passwordField: "password123"))
    }

    func testLoginVM_AreFieldsValid_NilPassword() {
        let container = AuthenticatorContainerViewModel()
        let vm = LoginViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "user@test.com", passwordField: nil))
    }

    func testLoginVM_AreFieldsValid_BothNil() {
        let container = AuthenticatorContainerViewModel()
        let vm = LoginViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: nil, passwordField: nil))
    }

    func testLoginVM_AreFieldsValid_ExactlyEightCharsPassword() {
        let container = AuthenticatorContainerViewModel()
        let vm = LoginViewModel(containerViewModel: container)

        XCTAssertTrue(vm.areFieldsValid(emailField: "user@test.com", passwordField: "12345678"))
    }

    // MARK: - RegisterViewModel Initial State

    func testRegisterVM_InitialState() {
        let container = AuthenticatorContainerViewModel()
        let vm = RegisterViewModel(containerViewModel: container)

        XCTAssertEqual(vm.fullname, "")
        XCTAssertEqual(vm.email, "")
        XCTAssertEqual(vm.password, "")
        XCTAssertNil(vm.registerStatus)
        XCTAssertFalse(vm.agreeUpdates)
        XCTAssertFalse(vm.agreeTermsAndConditions)
    }

    func testRegisterVM_AllPropertiesCanBeSet() {
        let container = AuthenticatorContainerViewModel()
        let vm = RegisterViewModel(containerViewModel: container)

        vm.fullname = "John Doe"
        vm.email = "john@example.com"
        vm.agreeUpdates = true
        vm.agreeTermsAndConditions = true

        XCTAssertEqual(vm.fullname, "John Doe")
        XCTAssertEqual(vm.email, "john@example.com")
        XCTAssertTrue(vm.agreeUpdates)
        XCTAssertTrue(vm.agreeTermsAndConditions)
    }

    // MARK: - RegisterViewModel areFieldsValid

    func testRegisterVM_AreFieldsValid_AllValid() {
        let container = AuthenticatorContainerViewModel()
        let vm = RegisterViewModel(containerViewModel: container)

        vm.fullname = "John Doe"
        vm.email = "john@example.com"
        vm.password = "password123"

        XCTAssertTrue(vm.areFieldsValid())
    }

    func testRegisterVM_AreFieldsValid_EmptyFullname() {
        let container = AuthenticatorContainerViewModel()
        let vm = RegisterViewModel(containerViewModel: container)

        vm.fullname = ""
        vm.email = "john@example.com"
        vm.password = "password123"

        XCTAssertFalse(vm.areFieldsValid())
    }

    func testRegisterVM_AreFieldsValid_InvalidEmail() {
        let container = AuthenticatorContainerViewModel()
        let vm = RegisterViewModel(containerViewModel: container)

        vm.fullname = "John Doe"
        vm.email = "notanemail"
        vm.password = "password123"

        XCTAssertFalse(vm.areFieldsValid())
    }

    func testRegisterVM_AreFieldsValid_ShortPassword() {
        let container = AuthenticatorContainerViewModel()
        let vm = RegisterViewModel(containerViewModel: container)

        vm.fullname = "John Doe"
        vm.email = "john@example.com"
        vm.password = "short"

        XCTAssertFalse(vm.areFieldsValid())
    }

    func testRegisterVM_AreFieldsValid_AllEmpty() {
        let container = AuthenticatorContainerViewModel()
        let vm = RegisterViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid())
    }

    // MARK: - ForgotPasswordViewModel Initial State

    func testForgotPasswordVM_InitialState() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertEqual(vm.email, "")
        XCTAssertNil(vm.requestStatus)
    }

    func testForgotPasswordVM_EmailCanBeSet() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        vm.email = "test@example.com"
        XCTAssertEqual(vm.email, "test@example.com")
    }

    // MARK: - ForgotPasswordViewModel areFieldsValid

    func testForgotPasswordVM_AreFieldsValid_ValidEmail() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertTrue(vm.areFieldsValid(emailField: "user@example.com"))
    }

    func testForgotPasswordVM_AreFieldsValid_InvalidEmail() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "notanemail"))
    }

    func testForgotPasswordVM_AreFieldsValid_EmptyEmail() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: ""))
    }

    func testForgotPasswordVM_AreFieldsValid_NilEmail() {
        let container = AuthenticatorContainerViewModel()
        let vm = ForgotPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: nil))
    }

    // MARK: - AuthVerifyIdentityViewModel Initial State

    func testVerifyIdentityVM_InitialState() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        XCTAssertEqual(vm.pinCode, "")
        XCTAssertFalse(vm.digitsDisabled)
    }

    func testVerifyIdentityVM_AllPropertiesCanBeSet() {
        let container = AuthenticatorContainerViewModel()
        let vm = AuthVerifyIdentityViewModel(containerViewModel: container)

        vm.pinCode = "123456"
        vm.digitsDisabled = true

        XCTAssertEqual(vm.pinCode, "123456")
        XCTAssertTrue(vm.digitsDisabled)
    }
}
