//
//  SharedFilesPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 10.08.2022.
//

import Foundation
import XCTest

class SharedFilesPage {
    let app: XCUIApplication
    var navigationBar: XCUIElement {
        app.navigationBars["Shares"]
    }
    
    var sharedByMeButton: XCUIElement { app.buttons["Shared By Me"] }
    var sharedWithMeButton: XCUIElement { app.buttons["Shared With Me"] }
    var settingsButton: XCUIElement { navigationBar.buttons["settings"] }
    var addButton: XCUIElement {
        app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1)
    }
    var firstItemFromFolderButton: XCUIElement {         app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0) }
    
    var moreForFirstItemFromFolderButton: XCUIElement { app.collectionViews.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .button).element }
    
    var uploadButton: XCUIElement {
        app.buttons["Upload"] }
    var newFolderButton: XCUIElement {
        app.buttons["New Folder"]
    }
    var downloadButton: XCUIElement {
        app.buttons["Download"] }
    var renameButton: XCUIElement {
        app.buttons["Rename"] }
    var deleteButton: XCUIElement {
        app.buttons["Delete"] }
    var backButton: XCUIElement {
        app.buttons["Back"] }
    var filesWithOwnerAccessFolderButton: XCUIElement {
        app.collectionViews.staticTexts["files with owner access"].firstMatch }
    var filesWithViewerFolderButton: XCUIElement {
        app.collectionViews.staticTexts["files with viewer access"].firstMatch }
    var createNewFolderStaticText: XCUIElement {
        app.staticTexts["Create New Folder"] }
    var folderNameTextField: XCUIElement {
        app.textFields["Folder Name"] }
    var createNewFolderButton: XCUIElement {
        app.buttons["Create"] }
    var cancelCreateNewFolderButton: XCUIElement {
        app.buttons["Cancel"] }
    var currentTestFolderButton: XCUIElement {
        app.collectionViews.staticTexts["a test folder"].firstMatch }
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }
    
    func waitForExistence() {
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
    }
    
    func goToSharedWithMeTab() {
        XCTAssertTrue(sharedWithMeButton.waitForExistence(timeout: 5))
        sharedWithMeButton.tap()
    }
    
    func enterFolderWithOwnerAccess() {
        XCTAssertTrue(filesWithOwnerAccessFolderButton.waitForExistence(timeout: 5))
        filesWithOwnerAccessFolderButton.tap()
        
        sleep(3)
    }
    
    func goBack() {
        XCTAssertTrue(backButton.waitForExistence(timeout: 10))
        backButton.tap()
    }
    
    func toggleRightSideMenu() {
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 5))
        settingsButton.tap()
    }
    
    func testAddButtonIsPresent() {
        XCTAssertEqual(addButton.exists, true)
        XCTAssertEqual(addButton.isHittable, true)
    }
    
    func testAddButtonIsNotPresent() {
        XCTAssertEqual(addButton.exists, false)
        XCTAssertEqual(addButton.isHittable, false)
    }
    
    func createNewFolder(name: String) {
        addButton.tap()
        XCTAssertTrue(newFolderButton.waitForExistence(timeout: 5))
        newFolderButton.tap()
        
        XCTAssertTrue(createNewFolderStaticText.waitForExistence(timeout: 5))
        XCTAssertTrue(folderNameTextField.waitForExistence(timeout: 5))
        folderNameTextField.typeText(name)
        
        XCTAssertTrue(createNewFolderButton.waitForExistence(timeout: 5))
        createNewFolderButton.tap()
        
        sleep(3)
        
        XCTAssertTrue(currentTestFolderButton.waitForExistence(timeout: 5))
        currentTestFolderButton.tap()
    }
}
