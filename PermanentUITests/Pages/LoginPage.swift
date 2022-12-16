//
//  LoginPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 27.07.2022.
//

import Foundation
import XCTest

class LoginPage {
    let app: XCUIApplication
    
    var emailField: XCUIElement {
        app.textFields["Email"]
    }
    var passwordField: XCUIElement {
        app.secureTextFields["Password"]
    }
    var logInButton: XCUIElement {
        app.buttons["Sign in"]
    }
    var signUpButton: XCUIElement {
        app.buttons["Sign Up"]
    }
    var forgotPasswordButton: XCUIElement {
        app.buttons["Forgot Password?"]
    }
    
    var errorStaticText: XCUIElement {
        app.staticTexts["Something went wrong. Please try again later."]
    }
    
    var okButton: XCUIElement {
        app.buttons["Ok"]
    }
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }
    
    func login(username: String, password: String) {
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(username)
        
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText(password)
        
        XCTAssertTrue(logInButton.waitForExistence(timeout: 5))
        logInButton.tap()
        
        sleep(5)
    }
    
    func pressCancelButton() {
        XCTAssertTrue(errorStaticText.waitForExistence(timeout: 5))
        
        XCTAssertTrue(okButton.waitForExistence(timeout: 5))
        okButton.tap()
        
        XCTAssertTrue(signUpButton.waitForExistence(timeout: 5))
        signUpButton.tap()
    }
}
