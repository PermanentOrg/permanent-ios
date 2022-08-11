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
    var addButton: XCUIElement {
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 2)
    }
    var addNewFolder: XCUIElement {
        app.buttons["New Folder"]
    }
    var uploadButton: XCUIElement {
        app.buttons["Upload"]
    }
    
    var createNewFolderStaticText: XCUIElement {
        app.staticTexts["Create New Folder"]
    }
    
    var folderNameTextField: XCUIElement {
        app.textFields["Folder Name"]
    }
    
    var createNewFolderButton: XCUIElement {
        app.buttons["Create"]
    }
    
    var cancelCreateNewFolderButton: XCUIElement {
        app.buttons["Cancel"]
    }
    
    var currentTestFolderButton: XCUIElement {
        app.collectionViews.staticTexts["current test"].firstMatch
    }
    
    var photoLibraryButton: XCUIElement {
        app.sheets.scrollViews.otherElements.buttons["Photo Library"]
    }
    
    var photoLibraryElementLoading: XCUIElement {
        app.collectionViews.activityIndicators["In progress"]
    }
    
    var uploadInProgress: XCUIElement {
        app.collectionViews.buttons["Uploads"]
    }
    
    var uploadFinishedButton: XCUIElement {
        app.collectionViews.buttons["Name (A-Z)"]
    }
    
    var firstElementFromFolder: XCUIElement {
        app.collectionViews.cells.children(matching: .other).element.children(matching: .other).element
    }
    
    var firstElementMoreButton: XCUIElement {
        app.collectionViews.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
    }
    
    var deleteButtonFromMoreList: XCUIElement {
        app.buttons["Delete"]
    }
    
    var deleteButtonFromConfirmation: XCUIElement {
        app.scrollViews.otherElements.staticTexts["Delete"]
    }
    
    var backButton: XCUIElement {
        app.buttons["chevron"]
    }
    
    var emptyFolder: XCUIElement {
        app.collectionViews.staticTexts["This folder is empty"]
    }
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }
    
    func waitForExistence() {
        XCTAssertTrue(navigationBar.waitForExistence(timeout: 5))
        XCTAssertTrue(addButton.waitForExistence(timeout: 5))
    }
    
    func toggleRightSideMenu() {
        settingsButton.tap()
    }
    
    func createNewFolder(name: String) {
        addButton.tap()
        XCTAssertTrue(addNewFolder.waitForExistence(timeout: 5))
        addNewFolder.tap()
        
        XCTAssertTrue(createNewFolderStaticText.waitForExistence(timeout: 5))
        XCTAssertTrue(folderNameTextField.waitForExistence(timeout: 5))
        folderNameTextField.typeText(name)
        
        XCTAssertTrue(createNewFolderButton.waitForExistence(timeout: 5))
        createNewFolderButton.tap()
        
        sleep(3)
        
        XCTAssertTrue(currentTestFolderButton.waitForExistence(timeout: 5))
        currentTestFolderButton.tap()
    }
    
    func enterPhotoLibrary() {
        sleep(2)
        addButton.tap()
        sleep(2)
        
        XCTAssertTrue(uploadButton.waitForExistence(timeout: 10))
        uploadButton.tap()
        
        XCTAssertTrue(photoLibraryButton.waitForExistence(timeout: 5))
        photoLibraryButton.tap()
    }
    
    func processUpload() {
        XCTAssertTrue(uploadInProgress.waitForExistence(timeout: 10))
        
        XCTAssertTrue(uploadFinishedButton.waitForExistence(timeout: 40))
        
        XCTAssertTrue(photoLibraryElementLoading.waitForExistence(timeout: 20))
        
        XCTAssertTrue(firstElementFromFolder.waitForExistence(timeout: 20))
        
        XCTAssertFalse(firstElementFromFolder.staticTexts.element(boundBy: 0).label.isEmpty)
    }
    
    func deleteFirstElementFromFolder() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        XCTAssertTrue(deleteButtonFromMoreList.waitForExistence(timeout: 10))
        deleteButtonFromMoreList.tap()
        
        XCTAssertTrue(deleteButtonFromConfirmation.waitForExistence(timeout: 10))
        deleteButtonFromConfirmation.tap()
    }
    
    func goBack() {
        XCTAssertTrue(backButton.waitForExistence(timeout: 10))
        backButton.tap()
    }
    
    func emptyFolderTest() {
        XCTAssertTrue(emptyFolder.waitForExistence(timeout: 10))
    }
}
