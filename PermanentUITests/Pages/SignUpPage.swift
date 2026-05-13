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

    var signUpStaticText: XCUIElement {
        app.staticTexts["Create your new account"]
    }

    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }

    func waitForExistence() {
        XCTAssertTrue(signUpStaticText.waitForExistence(timeout: 30))
    }
}
