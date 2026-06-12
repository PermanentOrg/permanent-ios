//
//  LoginViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class LoginViewModelTests: XCTestCase {

    private func makeSUT() -> LoginViewModel {
        let container = AuthenticatorContainerViewModel()
        return LoginViewModel(containerViewModel: container)
    }

    // MARK: - Initial State

    func testInitialState_UsernameIsEmpty() {
        let sut = makeSUT()
        XCTAssertTrue(sut.username.isEmpty)
    }

    func testInitialState_PasswordIsEmpty() {
        let sut = makeSUT()
        XCTAssertTrue(sut.password.isEmpty)
    }

    func testInitialState_LoginStatusIsNil() {
        let sut = makeSUT()
        XCTAssertNil(sut.loginStatus)
    }

    // MARK: - areFieldsValid

    func testAreFieldsValid_ValidEmailAndPassword_ReturnsTrue() {
        let sut = makeSUT()
        XCTAssertTrue(sut.areFieldsValid(emailField: "user@example.com", passwordField: "password123"))
    }

    func testAreFieldsValid_NilEmail_ReturnsFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.areFieldsValid(emailField: nil, passwordField: "password123"))
    }

    func testAreFieldsValid_NilPassword_ReturnsFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.areFieldsValid(emailField: "user@example.com", passwordField: nil))
    }

    func testAreFieldsValid_EmptyEmail_ReturnsFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.areFieldsValid(emailField: "", passwordField: "password123"))
    }

    func testAreFieldsValid_InvalidEmail_ReturnsFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.areFieldsValid(emailField: "not-an-email", passwordField: "password123"))
    }

    func testAreFieldsValid_EmailWithoutDomain_ReturnsFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.areFieldsValid(emailField: "user@", passwordField: "password123"))
    }

    func testAreFieldsValid_ShortPassword_ReturnsFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.areFieldsValid(emailField: "user@example.com", passwordField: "short"))
    }

    func testAreFieldsValid_ExactlyEightCharPassword_ReturnsTrue() {
        let sut = makeSUT()
        XCTAssertTrue(sut.areFieldsValid(emailField: "user@example.com", passwordField: "12345678"))
    }

    func testAreFieldsValid_SevenCharPassword_ReturnsFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.areFieldsValid(emailField: "user@example.com", passwordField: "1234567"))
    }

    func testAreFieldsValid_BothNil_ReturnsFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.areFieldsValid(emailField: nil, passwordField: nil))
    }

    func testAreFieldsValid_BothEmpty_ReturnsFalse() {
        let sut = makeSUT()
        XCTAssertFalse(sut.areFieldsValid(emailField: "", passwordField: ""))
    }

    func testAreFieldsValid_EmailWithSubdomain_ReturnsTrue() {
        let sut = makeSUT()
        XCTAssertTrue(sut.areFieldsValid(emailField: "user@mail.example.com", passwordField: "password123"))
    }

    func testAreFieldsValid_EmailWithPlusSign_ReturnsTrue() {
        let sut = makeSUT()
        XCTAssertTrue(sut.areFieldsValid(emailField: "user+tag@example.com", passwordField: "password123"))
    }

    func testAreFieldsValid_EmailWithDots_ReturnsTrue() {
        let sut = makeSUT()
        XCTAssertTrue(sut.areFieldsValid(emailField: "first.last@example.com", passwordField: "password123"))
    }

    // MARK: - attemptLogin with Invalid Data

    func testAttemptLogin_InvalidFields_SetsErrorStatus() {
        let sut = makeSUT()
        sut.username = ""
        sut.password = ""
        sut.attemptLogin()

        if case .error = sut.loginStatus {
            // Expected error status
        } else {
            XCTFail("Expected error login status, got \(String(describing: sut.loginStatus))")
        }
    }

    func testAttemptLogin_InvalidFields_ShowsErrorOnContainer() {
        let sut = makeSUT()
        sut.username = "invalid"
        sut.password = "short"
        sut.attemptLogin()

        XCTAssertTrue(sut.containerViewModel.showErrorBanner)
    }

    // MARK: - login Method Guard

    func testLogin_NilUsername_ReturnsError() {
        let sut = makeSUT()
        let expectation = expectation(description: "Login handler called")

        sut.login(withUsername: nil, password: "password123") { status in
            if case .error = status {
                expectation.fulfill()
            } else {
                XCTFail("Expected error status")
            }
        }

        waitForExpectations(timeout: 1)
    }

    func testLogin_NilPassword_ReturnsError() {
        let sut = makeSUT()
        let expectation = expectation(description: "Login handler called")

        sut.login(withUsername: "user@example.com", password: nil) { status in
            if case .error = status {
                expectation.fulfill()
            } else {
                XCTFail("Expected error status")
            }
        }

        waitForExpectations(timeout: 1)
    }

    func testLogin_InvalidEmail_ReturnsError() {
        let sut = makeSUT()
        let expectation = expectation(description: "Login handler called")

        sut.login(withUsername: "not-valid", password: "password123") { status in
            if case .error = status {
                expectation.fulfill()
            } else {
                XCTFail("Expected error status")
            }
        }

        waitForExpectations(timeout: 1)
    }

    // MARK: - Container ViewModel Integration

    func testAttemptLogin_SetsContainerLoadingBeforeValidation() {
        let sut = makeSUT()
        sut.username = ""
        sut.password = ""
        sut.attemptLogin()
        XCTAssertFalse(sut.containerViewModel.isLoading, "Should not set loading for invalid fields")
    }
}
