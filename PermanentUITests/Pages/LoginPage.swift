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
    
    var emailField: XCUIElement { app.webViews.textFields["Email"] }
    var passwordField: XCUIElement { app.webViews.secureTextFields["Password (min. 8 chars)"] }
    var rememberSignInSwitch: XCUIElement { app.webViews.switches.firstMatch }
    var submitButton: XCUIElement { app.webViews.buttons["Submit"] }
    var cancelButton: XCUIElement { app.buttons["Cancel"] }
    
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

        XCTAssertTrue(rememberSignInSwitch.waitForExistence(timeout: 5))
        if let checkboxValue = rememberSignInSwitch.value as? String, Int(checkboxValue) == 1 {
            rememberSignInSwitch.tap()
        }
        
        XCTAssertTrue(submitButton.waitForExistence(timeout: 5))
        submitButton.tap()
        
        sleep(5)
    }
    
    func pressCancelButton() {
        XCTAssertTrue(cancelButton.waitForExistence(timeout: 5))
        cancelButton.tap()
    }
}
