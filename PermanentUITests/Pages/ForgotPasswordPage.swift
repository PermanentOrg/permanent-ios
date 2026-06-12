//
//  ForgotPasswordScreen.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 16.01.2023.
//

import Foundation
import XCTest

class ForgotPasswordPage {
    let app: XCUIApplication
    
    var emailField: XCUIElement {
        app.textFields.firstMatch
    }
    var sendRequestButton: XCUIElement {
        app.buttons["Send Request"]
    }
    var backToSignInButton: XCUIElement {
        app.buttons["Back to Sign in"]
    }
    var confirmationText: XCUIElement {
        app.staticTexts["Thank you! If your email was found in our system, you will receive an email shortly."]
    }
    var goToSignInButton: XCUIElement {
        app.buttons["Go to Sign in"]
    }
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }
    
    func navigateToLoginPage() {
        XCTAssertTrue(backToSignInButton.waitForExistence(timeout: 5))
        backToSignInButton.tap()
    }
    
    func recoverPassword(email: String) {
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(email)

        XCTAssertTrue(sendRequestButton.waitForExistence(timeout: 5))
        sendRequestButton.tap()
    }

    func confirmAndReturnToLogin() {
        XCTAssertTrue(confirmationText.waitForExistence(timeout: 10))
        XCTAssertTrue(goToSignInButton.waitForExistence(timeout: 5))
        goToSignInButton.tap()
        sleep(2)
    }
}
