//
//  ShareManagementUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 13.05.2026.
//

import XCTest

class ShareManagementUITests: BaseUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
    }

    func testShareLinkCreateRestrictAndRevoke() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        // Login
        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        // Create a test folder and upload a photo
        privateFilesPage.createNewFolder(name: "share test")
        privateFilesPage.enterFolder(named: "share test")

        privateFilesPage.enterPhotoLibrary()

        let photoLibraryPage = PhotoLibraryPage(app: app, testCase: self)
        photoLibraryPage.waitForExistence()
        photoLibraryPage.uploadFirstPhoto()

        privateFilesPage.processUpload()

        // Open file menu and go to Share Management
        XCTAssertTrue(privateFilesPage.firstElementMoreButton.waitForExistence(timeout: 10))
        privateFilesPage.firstElementMoreButton.tap()

        let fileMenu = FileMenuPage(app: app)
        XCTAssertTrue(fileMenu.shareLinkButton.waitForExistence(timeout: 10))
        fileMenu.shareLinkButton.tap()

        // Create share link (auto-navigates to Link Settings)
        let sharePage = ShareManagementPage(app: app)
        sharePage.waitForShareItemView()
        sharePage.createLink()

        // Already on Link Settings — change to Restricted
        sharePage.changeToRestricted()
        sharePage.saveSettings()

        // Re-open link settings to revoke
        sharePage.openLinkSettings()
        sharePage.revokeLink()

        // Verify we're back on the share item view with the create link card
        XCTAssertTrue(sharePage.createLinkCard.waitForExistence(timeout: 10))

        // Close share management (tap the X button)
        let closeButton = app.buttons["Close"].firstMatch
        if closeButton.waitForExistence(timeout: 3) {
            closeButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()
        }
        sleep(2)

        // Delete the uploaded file
        privateFilesPage.deleteFirstElementFromFolder()

        // Verify folder is empty
        privateFilesPage.emptyFolderTest()

        // Go back and delete the test folder
        privateFilesPage.goBack()
        privateFilesPage.deleteFirstElementFromFolder()

        // Sign out
        privateFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }
}
