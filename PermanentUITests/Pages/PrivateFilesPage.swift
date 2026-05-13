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
        app.images["fabPlusButton"]
    }
    var addNewFolder: XCUIElement {
        app.buttons["Create New Folder"]
    }
    var uploadPhotosButton: XCUIElement {
        app.buttons["Upload Photos from Library"]
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
    var searchButton: XCUIElement {
        app.buttons["searchButton"]
    }
    var switchViewButton: XCUIElement {
        app.buttons["switchViewButton"]
    }
    var headerSelectButton: XCUIElement {
        app.buttons["headerSelectButton"]
    }
    var headerClearSelectionButton: XCUIElement {
        app.buttons["headerClearSelectionButton"]
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

        XCTAssertTrue(uploadPhotosButton.waitForExistence(timeout: 10))
        uploadPhotosButton.tap()
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
        sleep(3)
    }
    
    func goBack() {
        XCTAssertTrue(backButton.waitForExistence(timeout: 10))
        backButton.tap()
    }
    
    func emptyFolderTest() {
        XCTAssertTrue(emptyFolder.waitForExistence(timeout: 10))
    }

    func toggleListGridView() {
        XCTAssertTrue(switchViewButton.waitForExistence(timeout: 10))
        switchViewButton.tap()
        sleep(1)
    }

    func tapSearchButton() {
        XCTAssertTrue(searchButton.waitForExistence(timeout: 10))
        searchButton.tap()
    }

    func enterMultiSelectMode() {
        XCTAssertTrue(headerSelectButton.waitForExistence(timeout: 10))
        headerSelectButton.tap()
        sleep(1)
    }

    func selectAllInMultiSelect() {
        XCTAssertTrue(headerSelectButton.waitForExistence(timeout: 10))
        headerSelectButton.tap()
        sleep(1)
    }

    func cancelMultiSelect() {
        XCTAssertTrue(headerClearSelectionButton.waitForExistence(timeout: 10))
        headerClearSelectionButton.tap()
        sleep(1)
    }

    func renameFirstElementFromFolder(name: String) {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 60))
        firstElementMoreButton.tap()

        let fileMenu = FileMenuPage(app: app)
        XCTAssertTrue(fileMenu.renameButton.waitForExistence(timeout: 10))
        fileMenu.renameButton.tap()

        let renameAlert = RenameAlertPage(app: app)
        XCTAssertTrue(renameAlert.textField.waitForExistence(timeout: 10))

        // Prefer the SwiftUI rename dialog's dedicated clear button; fall back to the
        // legacy "Clear text" UIKit button.
        let swiftUIClearButton = app.buttons["renameClearButton"]
        if swiftUIClearButton.exists {
            swiftUIClearButton.tap()
        } else {
            renameAlert.textField.selectAndDeleteText(inApp: app)
        }

        renameAlert.textField.tap()
        renameAlert.textField.typeText(name)

        XCTAssertTrue(renameAlert.renameButton.waitForExistence(timeout: 10))
        renameAlert.renameButton.tap()
        sleep(3)
    }

    func copyFirstElementToCurrentFolder() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 60))
        firstElementMoreButton.tap()

        let fileMenu = FileMenuPage(app: app)
        XCTAssertTrue(fileMenu.copyButton.waitForExistence(timeout: 10))
        fileMenu.copyButton.tap()
        sleep(2)
    }

    func moveFirstElementToCurrentFolder() {
        XCTAssertTrue(firstElementMoreButton.waitForExistence(timeout: 60))
        firstElementMoreButton.tap()

        let fileMenu = FileMenuPage(app: app)
        XCTAssertTrue(fileMenu.moveButton.waitForExistence(timeout: 10))
        fileMenu.moveButton.tap()
        sleep(2)
    }

    func tapPasteHere() {
        let pasteButton = app.buttons["Paste Here"].firstMatch
        XCTAssertTrue(pasteButton.waitForExistence(timeout: 10))
        if pasteButton.isHittable {
            pasteButton.tap()
        } else {
            pasteButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        sleep(3)
    }

    func tapMoveHere() {
        let moveButton = app.buttons["Move Here"].firstMatch
        XCTAssertTrue(moveButton.waitForExistence(timeout: 10))
        if moveButton.isHittable {
            moveButton.tap()
        } else {
            moveButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        sleep(3)
    }

    func assertElementExists(named name: String) {
        XCTAssertTrue(app.collectionViews.staticTexts[name].firstMatch.waitForExistence(timeout: 10))
    }

    func tapFirstFileCell() {
        // Tap the actual UICollectionViewCell so didSelectItemAt fires (tapping an
        // inner .other element doesn't reach the collection view's tap handler).
        let firstCell = app.collectionViews.cells.element(boundBy: 0)
        XCTAssertTrue(firstCell.waitForExistence(timeout: 30))

        // Wait briefly until the cell is hittable — thumbnails may still be loading.
        var attempts = 0
        while !firstCell.isHittable && attempts < 15 {
            sleep(1)
            attempts += 1
        }

        // Tap in the left portion to avoid the more-button on the right side of list cells.
        firstCell.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5)).tap()
        sleep(3)
    }

    func deleteElement(named name: String) {
        let cell = app.collectionViews.cells.containing(.staticText, identifier: name).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 10))

        let moreButton = cell.buttons.firstMatch
        XCTAssertTrue(moreButton.waitForExistence(timeout: 10))
        moreButton.tap()

        let fileMenu = FileMenuPage(app: app)
        XCTAssertTrue(fileMenu.deleteButton.waitForExistence(timeout: 10))
        fileMenu.deleteButton.tap()

        let deleteAlert = DeleteAlertPage(app: app)
        XCTAssertTrue(deleteAlert.deleteButton.waitForExistence(timeout: 10))
        deleteAlert.deleteButton.tap()
        sleep(3)
    }

    @discardableResult
    func deleteFirstElementIfPresent() -> Bool {
        guard firstElementMoreButton.waitForExistence(timeout: 5) else { return false }
        firstElementMoreButton.tap()

        let fileMenu = FileMenuPage(app: app)
        guard fileMenu.deleteButton.waitForExistence(timeout: 5) else {
            if fileMenu.closeButton.exists { fileMenu.closeButton.tap() }
            return false
        }
        fileMenu.deleteButton.tap()

        let deleteAlert = DeleteAlertPage(app: app)
        XCTAssertTrue(deleteAlert.deleteButton.waitForExistence(timeout: 10))
        deleteAlert.deleteButton.tap()
        sleep(3)
        return true
    }

    func copyElement(named name: String) {
        let cell = app.collectionViews.cells.containing(.staticText, identifier: name).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 10))

        let moreButton = cell.buttons.firstMatch
        XCTAssertTrue(moreButton.waitForExistence(timeout: 10))
        moreButton.tap()

        let fileMenu = FileMenuPage(app: app)
        XCTAssertTrue(fileMenu.copyButton.waitForExistence(timeout: 10))
        fileMenu.copyButton.tap()
        sleep(2)
    }

    func moveElement(named name: String) {
        let cell = app.collectionViews.cells.containing(.staticText, identifier: name).firstMatch
        XCTAssertTrue(cell.waitForExistence(timeout: 10))

        let moreButton = cell.buttons.firstMatch
        XCTAssertTrue(moreButton.waitForExistence(timeout: 10))
        moreButton.tap()

        let fileMenu = FileMenuPage(app: app)
        XCTAssertTrue(fileMenu.moveButton.waitForExistence(timeout: 10))
        fileMenu.moveButton.tap()
        sleep(2)
    }
}
