//
//  LeftSideMenu.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 10.08.2022.
//

import Foundation

import Foundation
import XCTest

class LeftSideMenuPage {
    let app: XCUIApplication
    
    var menuButton: XCUIElement {
        app.buttons["hamburger"]
    }
    var privateFilesButton: XCUIElement {
        app.tables.staticTexts["Private Files"]
    }
    var sharedFilesButton: XCUIElement {
        app.tables.staticTexts["Shared Files"]
    }
    var publicFilesButton: XCUIElement {
        app.tables.staticTexts["Public Files"]
    }
    var publicProfileButton: XCUIElement {
        app.tables.staticTexts["View Profile"]
    }
    var privateFilesTitle: XCUIElement {
        app.navigationBars.staticTexts["Private Files"]
    }
    var sharedFilesTitle: XCUIElement {
        app.navigationBars.staticTexts["Shares"]
    }
    var publicFilesTitle: XCUIElement {
        app.navigationBars.staticTexts["Public Files"]
    }
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }
    
    func waitForExistence() {
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5))
    }
    
    func goToSharedFiles() {
        menuButton.tap()
        
        XCTAssertTrue(sharedFilesButton.waitForExistence(timeout: 5))
        sharedFilesButton.tap()
        
        XCTAssertTrue(sharedFilesTitle.waitForExistence(timeout: 5))
    }
    
    func goToPrivateFiles() {
        menuButton.tap()
        
        XCTAssertTrue(privateFilesButton.waitForExistence(timeout: 5))
        privateFilesButton.tap()

        XCTAssertTrue(privateFilesTitle.waitForExistence(timeout: 5))
    }
    
    func goToPublicFiles() {
        menuButton.tap()
        
        XCTAssertTrue(publicFilesButton.waitForExistence(timeout: 5))
        publicFilesButton.tap()
        
        XCTAssertTrue(publicFilesTitle.waitForExistence(timeout: 5))
    }
    
    func goToPublicProfile() {
        menuButton.tap()
        
        XCTAssertTrue(publicProfileButton.waitForExistence(timeout: 5))
        publicProfileButton.tap()
    }
}
