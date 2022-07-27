//
//  PrivateFilesPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 27.07.2022.
//

import Foundation
import XCTest

class PrivateFilesPage {
    let app: XCUIApplication
    var navigationBar: XCUIElement {
        app.navigationBars["Private Files"]
    }
    var settingsButton: XCUIElement {
        navigationBar.buttons["settings"]
    }
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }
    
    func waitForExistence() {
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
    }
    
    func toggleRightSideMenu() {
        settingsButton.tap()
    }
}
