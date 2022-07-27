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
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }
    
    func login(username: String, password: String) {
        let emailField = app.webViews.textFields["Email"]
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(username)
        
        let passwordField = app.webViews.secureTextFields["Password (min. 8 chars)"]
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText(password)

        let rememberSignInSwitch = app.webViews.switches["0"]
        XCTAssertTrue(rememberSignInSwitch.waitForExistence(timeout: 5))
        if !rememberSignInSwitch.isEnabled {
            rememberSignInSwitch.tap()
        }
        
        let submitButton = app.webViews.buttons["Submit"]
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
        submitButton.tap()
        
        sleep(5)
    }
    
    func pressCancelButton() {
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()
    }
}
