//
//  UploadFilesUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 27.07.2022.
//

import XCTest

class UploadFilesUITests: BaseUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
    }
    
    func testFilePreviewAndDetails() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        // Seed: aaa_-prefixed folder + one uploaded photo.
        let folderName = "aaa_preview_\(UUID().uuidString.prefix(6))"
        privateFilesPage.createNewFolder(name: folderName)
        privateFilesPage.enterFolder(named: folderName)

        privateFilesPage.enterPhotoLibrary()

        let photoLibraryPage = PhotoLibraryPage(app: app, testCase: self)
        photoLibraryPage.waitForExistence()
        photoLibraryPage.uploadFirstPhoto()

        privateFilesPage.processUpload()

        // Tap the uploaded photo to open FilePreview.
        privateFilesPage.tapFirstFileCell()

        let previewPage = FilePreviewPage(app: app)
        previewPage.waitForExistence()

        // Open the Details screen via the "info" nav-bar button.
        previewPage.openDetails()

        let detailsPage = FileDetailsPage(app: app)
        detailsPage.waitForExistence()

        // Exercise both segments of the Info / Details switcher.
        detailsPage.selectDetailsTab()
        detailsPage.selectInfoTab()

        // Closing FileDetails cascades through the delegate chain and also
        // dismisses the underlying FilePreview — both modal screens go away
        // and we land back on Private Files.
        detailsPage.close()

        privateFilesPage.waitForExistence()

        // Cleanup: delete the photo + the folder.
        privateFilesPage.deleteFirstElementFromFolder()
        privateFilesPage.emptyFolderTest()
        privateFilesPage.goBack()

        privateFilesPage.deleteElement(named: folderName)

        // Sign out.
        privateFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }

    func testAddFilesOwner() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        privateFilesPage.createNewFolder(name: "current test")

        privateFilesPage.enterFolder(named: "current test")

        privateFilesPage.enterPhotoLibrary()

        let photoLibraryPage = PhotoLibraryPage(app: app, testCase: self)
        photoLibraryPage.waitForExistence()

        photoLibraryPage.uploadFirstPhoto()

        privateFilesPage.processUpload()

        privateFilesPage.deleteFirstElementFromFolder()

        privateFilesPage.emptyFolderTest()

        privateFilesPage.goBack()

        privateFilesPage.deleteFirstElementFromFolder()

        privateFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }
}
