//
//  SignUpPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 27.07.2022.
//

import Foundation
import XCTest

class SignUpPage {
    let app: XCUIApplication
    var enterLoginScreenButton: XCUIElement {
        app.staticTexts["Already have an account?"]
    }
    var signUpStaticText: XCUIElement {
        app.staticTexts["Sign Up"]
    }
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
        
        testCase.addUIInterruptionMonitor(withDescription: "login screen") { (alert) -> Bool in
            if alert.staticTexts["“Permanent” Wants to Use “permanent.org” to Sign In"].exists {
                alert.buttons["Continue"].tap()
                return true
            } else {
                return false
            }
        }
    }
    
    func waitForExistence() {
        XCTAssertTrue(signUpStaticText.waitForExistence(timeout: 10))
    }
    
    func navigateToLogin() {
        XCTAssertTrue(enterLoginScreenButton.waitForExistence(timeout: 10))
        enterLoginScreenButton.tap()
        sleep(5)
        app.tap()
        
        sleep(5)
    }
}
