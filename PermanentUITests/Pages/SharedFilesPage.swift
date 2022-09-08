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
    var sharedByMeButton: XCUIElement {
        app.buttons["Shared By Me"]
    }
    var sharedWithMeButton: XCUIElement {
        app.buttons["Shared With Me"]
    }
    var settingsButton: XCUIElement {
        navigationBar.buttons["settings"]
    }
    var addButton: XCUIElement {
        app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1)
    }
    var firstItemFromFolderButton: XCUIElement {
        app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0)
    }
    var moreForFirstItemFromFolderButton: XCUIElement {
        app.collectionViews.children(matching: .cell).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .button).element
    }
    var uploadButton: XCUIElement {
        app.buttons["Upload"]
    }
    var newFolderButton: XCUIElement {
        app.buttons["New Folder"]
    }
    var downloadButton: XCUIElement {
        app.buttons["Download"]
    }
    var renameButton: XCUIElement {
        app.buttons["Rename"]
    }
    var deleteButton: XCUIElement {
        app.buttons["Delete"]
    }
    var backButton: XCUIElement {
        app.buttons["Back"]
    }
    var filesWithOwnerAccessFolderButton: XCUIElement {
        app.collectionViews.staticTexts["files with owner access"].firstMatch
    }
    var filesWithViewerFolderButton: XCUIElement {
        app.collectionViews.staticTexts["files with viewer access "].firstMatch
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
        app.collectionViews.staticTexts["a test folder"].firstMatch
    }
    var photoLibraryButton: XCUIElement {
        app.sheets.scrollViews.otherElements.buttons["Photo Library"]
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
    var photoLibraryElementLoading: XCUIElement {
        app.collectionViews.activityIndicators["In progress"]
    }
    var deleteButtonFromMoreList: XCUIElement {
        app.buttons["Delete"]
    }
    var deleteButtonFromConfirmation: XCUIElement {
        app.scrollViews.otherElements.staticTexts["Delete"]
    }
    var renameButtonFromMoreList: XCUIElement {
        app.buttons["Rename"]
    }
    var renameButtonFromConfirmation: XCUIElement {
        app.scrollViews.otherElements.staticTexts["Rename"]
    }
    var folderRenameTextField: XCUIElement {
        app.textFields["a test"]
    }
    var emptyFolder: XCUIElement {
        app.collectionViews.staticTexts["You haven’t shared any content with anyone. Choose an item from My Files and share it with someone!"]
    }
    var notificationCompletedDownload: XCUIElement {
        app.staticTexts["'uploaded file' download completed"]
    }
    
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
        sleep(1)
        XCTAssertTrue(filesWithOwnerAccessFolderButton.waitForExistence(timeout: 5))
        filesWithOwnerAccessFolderButton.tap()
        
        sleep(3)
    }
    
    func enterFolderWithViewerAccess() {
        XCTAssertTrue(filesWithViewerFolderButton.waitForExistence(timeout: 5))
        filesWithViewerFolderButton.tap()
        
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
    
    func testMoreFileOptionsForSharedByMe() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        XCTAssertEqual(downloadButton.exists, false)
        
        XCTAssertEqual(renameButton.exists, true)
        
        XCTAssertEqual(deleteButton.exists, true)
        
        sleep(1)
        
        app.tap()
    }
    
    func testMoreFileOptionsMenuOwnerAccess() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        XCTAssertEqual(downloadButton.exists, true)
        
        XCTAssertEqual(renameButton.exists, true)
        
        XCTAssertEqual(deleteButton.exists, true)
        
        sleep(1)
        
        app.tap()
    }
    
    func testMoreFileOptionsMenuViewerAccess() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        XCTAssertEqual(downloadButton.exists, true)
        
        XCTAssertEqual(renameButton.exists, false)
        
        XCTAssertEqual(deleteButton.exists, false)
        
        sleep(1)
        
        app.tap()
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
        
        XCTAssertTrue(app.collectionViews.staticTexts[name].firstMatch.waitForExistence(timeout: 5))
    }
    
    func enterCreatedFolder() {
        XCTAssertTrue(currentTestFolderButton.waitForExistence(timeout: 5))
        currentTestFolderButton.tap()
        
        sleep(3)
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
        
        sleep(3)
    }
    
    func renameFirstElementFromFolder(name: String) {
        let firstElementName: String = app.collectionViews.staticTexts.element(boundBy: 2).label
        let renameTextFieldName: XCUIElement = app.textFields[firstElementName]
        
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        XCTAssertTrue(renameButtonFromMoreList.waitForExistence(timeout: 10))
        renameButtonFromMoreList.tap()
        
        XCTAssertTrue(renameTextFieldName.waitForExistence(timeout: 5))
        renameTextFieldName.press(forDuration: 2)
        app.menuItems["Select All"].tap()
        renameTextFieldName.typeText(name)
        
        XCTAssertTrue(renameButtonFromConfirmation.waitForExistence(timeout: 10))
        renameButtonFromConfirmation.tap()
        
        sleep(3)
    }
    
    func downloadFirstElementFromFolder() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        XCTAssertTrue(downloadButton.waitForExistence(timeout: 10))
        downloadButton.tap()
    }
    
    func processDownload() {
        XCTAssertTrue(notificationCompletedDownload.waitForExistence(timeout: 40))
        
        XCTAssertTrue(uploadFinishedButton.waitForExistence(timeout: 40))
    }
    
    func emptyFolderTest() {
        XCTAssertTrue(emptyFolder.waitForExistence(timeout: 10))
    }
}
