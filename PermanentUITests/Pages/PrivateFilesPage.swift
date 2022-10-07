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
        app.otherElements["plusButton"]
    }
    var addNewFolder: XCUIElement {
        app.buttons["New Folder"]
    }
    var uploadButton: XCUIElement {
        app.buttons["Upload"]
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
        
        let createFolderAlert = CreateFolderAlertPage(app: app)
        
        XCTAssertTrue(createFolderAlert.textField.waitForExistence(timeout: 5))
        createFolderAlert.textField.typeText(name)
        
        XCTAssertTrue(createFolderAlert.createButton.waitForExistence(timeout: 5))
        createFolderAlert.createButton.tap()
        
        sleep(3)
    }
    
    func enterFolder(named name: String) {
        let folderCell = app.collectionViews.cells.containing(.staticText, identifier: name).firstMatch
        folderCell.tap()
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
        XCTAssertTrue(fileMenu.deleteButton.waitForExistence(timeout: 10))
        fileMenu.deleteButton.tap()
        
        let deleteAlert = DeleteAlertPage(app: app)
        
        XCTAssertTrue(deleteAlert.deleteButton.waitForExistence(timeout: 10))
        deleteAlert.deleteButton.tap()
    }
    
    func goBack() {
        XCTAssertTrue(backButton.waitForExistence(timeout: 10))
        backButton.tap()
    }
    
    func emptyFolderTest() {
        XCTAssertTrue(emptyFolder.waitForExistence(timeout: 10))
    }
}
