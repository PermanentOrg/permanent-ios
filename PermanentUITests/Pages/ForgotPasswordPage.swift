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
        app.textFields["Email"]
    }
    var recoverPasswordButton: XCUIElement {
        app.buttons["Recover password"]
    }
    var backToSignInButton: XCUIElement {
        app.buttons["Back to Sign in"]
    }
    var passedStaticTitleText: XCUIElement {
        app.staticTexts["Success!"]
    }
    var passedStaticText: XCUIElement {
        app.staticTexts["If the email you entered is correct, you will receive instructions to reset your password."]
    }
    var okButton: XCUIElement {
        app.buttons["Ok"]
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
        
        XCTAssertTrue(recoverPasswordButton.waitForExistence(timeout: 5))
        recoverPasswordButton.tap()
    }
    
    func pressOkButton() {
        XCTAssertTrue(passedStaticTitleText.waitForExistence(timeout: 5))
        XCTAssertTrue(passedStaticText.waitForExistence(timeout: 5))
        
        XCTAssertTrue(okButton.waitForExistence(timeout: 5))
        okButton.tap()
    }
}
