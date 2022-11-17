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
    }
    
    func waitForExistence() {
        XCTAssertTrue(signUpStaticText.waitForExistence(timeout: 30))
    }
    
    func navigateToLogin() {
        enterLoginScreenButton.tap()
        sleep(5)
        app.tap()
        
        sleep(5)
    }
}
