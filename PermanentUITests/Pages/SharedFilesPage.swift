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
        app.otherElements["plusButton"]
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
    var backButton: XCUIElement {
        app.buttons["Back"]
    }
    var filesWithOwnerAccessFolderButton: XCUIElement {
        app.collectionViews.staticTexts["files with owner access"].firstMatch
    }
    var filesWithViewerFolderButton: XCUIElement {
        app.collectionViews.staticTexts["files with viewer access"].firstMatch
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
    var emptyFolder: XCUIElement {
        app.collectionViews.staticTexts["You haven’t shared any content with anyone. Choose an item from My Files and share it with someone!"]
    }
    var notificationCompletedDownload: XCUIElement {
        let predicate = NSPredicate(format: "label CONTAINS[cd] \"download completed\"")
        return app.staticTexts.matching(predicate).firstMatch
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
        
        let fileMenu = FileMenuPage(app: app)
        XCTAssertEqual(fileMenu.downloadButton.exists, true)
        XCTAssertEqual(fileMenu.renameButton.exists, true)
        XCTAssertEqual(fileMenu.deleteButton.exists, true)
        
        sleep(1)
        
        fileMenu.doneButton.tap()
    }
    
    func testMoreFileOptionsMenuOwnerAccess() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        let fileMenu = FileMenuPage(app: app)
        XCTAssertEqual(fileMenu.downloadButton.exists, false)
        XCTAssertEqual(fileMenu.renameButton.exists, true)
        XCTAssertEqual(fileMenu.unshareButton.exists, true)
        
        sleep(1)
        
        fileMenu.doneButton.tap()
    }
    
    func testMoreFileOptionsMenuViewerAccess() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        let fileMenu = FileMenuPage(app: app)
        XCTAssertEqual(fileMenu.downloadButton.exists, true)
        XCTAssertEqual(fileMenu.renameButton.exists, false)
        XCTAssertEqual(fileMenu.deleteButton.exists, false)
        
        sleep(1)
        
        fileMenu.doneButton.tap()
    }
    
    func createNewFolder(name: String) {
        addButton.tap()
        XCTAssertTrue(newFolderButton.waitForExistence(timeout: 5))
        newFolderButton.tap()
        
        let createFolderAlert = CreateFolderAlertPage(app: app)
        XCTAssertTrue(createFolderAlert.textField.waitForExistence(timeout: 5))
        createFolderAlert.textField.typeText(name)
        
        XCTAssertTrue(createFolderAlert.createButton.waitForExistence(timeout: 5))
        createFolderAlert.createButton.tap()
        
        sleep(3)
        
        XCTAssertTrue(app.collectionViews.staticTexts[name].firstMatch.waitForExistence(timeout: 5))
    }
    
    func enterFolder(withName name: String) {
        app.collectionViews.cells.containing(.staticText, identifier: name).firstMatch.tap()
        
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
        var numberOfSleeps = 0
        while photoLibraryElementLoading.exists && numberOfSleeps < 60 {
            sleep(1)
            numberOfSleeps += 1
        }
        XCTAssertTrue(firstElementFromFolder.waitForExistence(timeout: 20))
        
        XCTAssertFalse(firstElementFromFolder.staticTexts.element(boundBy: 0).label.isEmpty)
    }
    
    func deleteFirstElementFromFolder() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        let fileMenu = FileMenuPage(app: app)
        XCTAssertEqual(fileMenu.renameButton.exists, true)
        XCTAssertEqual(fileMenu.moveButton.exists, true)
        XCTAssertEqual(fileMenu.deleteButton.exists, true)
        
        XCTAssertTrue(fileMenu.deleteButton.waitForExistence(timeout: 10))
        fileMenu.deleteButton.tap()
        
        let deleteAlert = DeleteAlertPage(app: app)
        
        XCTAssertTrue(deleteAlert.deleteButton.waitForExistence(timeout: 10))
        deleteAlert.deleteButton.tap()
        
        sleep(3)
    }
    
    func renameFirstElementFromFolder(name: String) {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        let fileMenu = FileMenuPage(app: app)
        XCTAssertTrue(fileMenu.renameButton.waitForExistence(timeout: 10))
        fileMenu.renameButton.tap()
        
        let renameAlert = RenameAlertPage(app: app)
        renameAlert.textField.selectAndDeleteText(inApp: app)
        renameAlert.textField.typeText(name)
        
        renameAlert.renameButton.tap()
    }
    
    func downloadFirstElementFromFolder() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 10))
        firstElementMoreButton.tap()
        
        let fileMenu = FileMenuPage(app: app)
        XCTAssertTrue(fileMenu.downloadButton.waitForExistence(timeout: 10))
        fileMenu.downloadButton.tap()
    }
    
    func processDownload() {
        XCTAssertTrue(notificationCompletedDownload.waitForExistence(timeout: 40))
        
        XCTAssertTrue(uploadFinishedButton.waitForExistence(timeout: 40))
    }
    
    func emptyFolderTest() {
        XCTAssertTrue(emptyFolder.waitForExistence(timeout: 10))
    }
}
