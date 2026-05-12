//
//  RightSideMenu.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 27.07.2022.
//

import Foundation
import XCTest

class RightSideMenuPage {
    let app: XCUIApplication
    let accountEmail: String

    var accountMenuItem: XCUIElement {
        app.staticTexts["Account"]
    }
    var signOutButton: XCUIElement {
        app.staticTexts["Sign out"]
    }
    var confirmSignOutButton: XCUIElement {
        app.buttons.matching(NSPredicate(format: "label == 'Sign out'")).element(boundBy: 1)
    }

    init(app: XCUIApplication, testCase: XCTestCase, accountEmail: String) {
        self.app = app
        self.accountEmail = accountEmail
    }

    func waitForExistence() {
        XCTAssertTrue(accountMenuItem.waitForExistence(timeout: 10))
    }

    func logOut() {
        XCTAssertTrue(signOutButton.waitForExistence(timeout: 5))
        signOutButton.tap()
        sleep(1)
        XCTAssertTrue(confirmSignOutButton.waitForExistence(timeout: 5))
        confirmSignOutButton.tap()
        sleep(3)
    }
}
