//
//  AuthContainerAndContentTypeTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class AuthContainerAndContentTypeTests: XCTestCase {

    // MARK: - AuthBannerMessage

    func testAuthBannerMessage_AllNonNoneCasesHaveText() {
        let messages: [AuthBannerMessage] = [
            .invalidData, .invalidCredentials, .invalidPassword, .incorrectEmail,
            .invalidPhoneNumber, .emptyPinCode, .invalidPinCode, .invalidEmail,
            .resentCodeError, .codeExpiredError, .successResendCode, .successCodeSend,
            .successPasswordConfirmed, .successEmailAdded, .successSmsAdded,
            .successEmailDeleted, .successSmsDeleted, .error, .generalError
        ]

        for message in messages {
            XCTAssertFalse(message.text.isEmpty, "\(message) should have non-empty text")
        }
    }

    func testAuthBannerMessage_NoneHasEmptyText() {
        XCTAssertEqual(AuthBannerMessage.none.text, "")
    }

    // MARK: - AuthenticatorContainerViewModel

    func testContainerVM_DefaultState() {
        let vm = AuthenticatorContainerViewModel()

        XCTAssertFalse(vm.accountWasDeleted)
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showErrorBanner)
        XCTAssertFalse(vm.maintenanceTopBannerWasDisplayed)
        XCTAssertEqual(vm.username, "")
        XCTAssertEqual(vm.password, "")
        XCTAssertNil(vm.mfaSession)
        XCTAssertEqual(vm.contentType, .login)
        XCTAssertEqual(vm.firstViewContentType, .login)
        XCTAssertEqual(vm.bannerErrorMessage, .none)
    }

    func testContainerVM_InitWithContentType() {
        let vm = AuthenticatorContainerViewModel(contentType: .register)
        XCTAssertEqual(vm.contentType, .register)
    }

    // MARK: - setContentType

    func testContainerVM_SetContentType_UpdatesCorrectly() {
        let vm = AuthenticatorContainerViewModel()
        let types: [AuthContentType] = [.register, .verifyIdentity, .forgotPassword, .forgotPasswordConfirmation, .none]

        for type in types {
            vm.setContentType(type)
            XCTAssertEqual(vm.contentType, type)
        }
    }

    // MARK: - displayErrorBanner

    func testContainerVM_DisplayErrorBanner_SetsMessageAndShowsBanner() {
        let vm = AuthenticatorContainerViewModel()
        vm.displayErrorBanner(bannerErrorMessage: .invalidCredentials)

        XCTAssertEqual(vm.bannerErrorMessage, .invalidCredentials)
        XCTAssertTrue(vm.showErrorBanner)
    }
}
