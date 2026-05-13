//
//  FileMenuActionsUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 13.05.2026.
//

import XCTest

class FileMenuActionsUITests: BaseUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
    }

    func testCopyPhotoToAnotherFolder() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        // Create the source and destination folders. The "aaa_" prefix keeps them at
        // the top of the Name (A-Z) list so existing archive items are never touched.
        let sourceFolder = "aaa_copy_src_\(UUID().uuidString.prefix(6))"
        let destFolder = "aaa_copy_dst_\(UUID().uuidString.prefix(6))"
        privateFilesPage.createNewFolder(name: sourceFolder)
        privateFilesPage.createNewFolder(name: destFolder)

        // Upload a photo inside the source folder.
        privateFilesPage.enterFolder(named: sourceFolder)
        privateFilesPage.enterPhotoLibrary()

        let photoLibraryPage = PhotoLibraryPage(app: app, testCase: self)
        photoLibraryPage.waitForExistence()
        photoLibraryPage.uploadFirstPhoto()
        privateFilesPage.processUpload()

        // Initiate a copy on the uploaded photo, then paste it inside the destination folder.
        privateFilesPage.copyFirstElementToCurrentFolder()
        privateFilesPage.goBack()
        privateFilesPage.enterFolder(named: destFolder)
        privateFilesPage.tapPasteHere()

        // Cleanup: clear the destination folder and the copy, then the source folder.
        privateFilesPage.deleteFirstElementFromFolder()
        privateFilesPage.emptyFolderTest()
        privateFilesPage.goBack()

        privateFilesPage.deleteElement(named: destFolder)

        // The source may or may not still contain the original photo depending on
        // copy semantics in the current backend; clean it up best-effort.
        privateFilesPage.enterFolder(named: sourceFolder)
        privateFilesPage.deleteFirstElementIfPresent()
        privateFilesPage.goBack()

        privateFilesPage.deleteElement(named: sourceFolder)

        // Sign out.
        privateFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }

    func testMovePhotoToAnotherFolder() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        // Create the source and destination folders. The "aaa_" prefix keeps them at
        // the top of the Name (A-Z) list so existing archive items are never touched.
        let sourceFolder = "aaa_move_src_\(UUID().uuidString.prefix(6))"
        let destFolder = "aaa_move_dst_\(UUID().uuidString.prefix(6))"
        privateFilesPage.createNewFolder(name: sourceFolder)
        privateFilesPage.createNewFolder(name: destFolder)

        // Upload a photo inside the source folder.
        privateFilesPage.enterFolder(named: sourceFolder)
        privateFilesPage.enterPhotoLibrary()

        let photoLibraryPage = PhotoLibraryPage(app: app, testCase: self)
        photoLibraryPage.waitForExistence()
        photoLibraryPage.uploadFirstPhoto()
        privateFilesPage.processUpload()

        // Initiate a move on the uploaded photo, navigate to the destination, and drop it there.
        privateFilesPage.moveFirstElementToCurrentFolder()
        privateFilesPage.goBack()
        privateFilesPage.enterFolder(named: destFolder)
        privateFilesPage.tapMoveHere()

        // Cleanup: clear the destination folder (which now holds the moved file).
        privateFilesPage.deleteFirstElementFromFolder()
        privateFilesPage.emptyFolderTest()
        privateFilesPage.goBack()

        privateFilesPage.deleteElement(named: destFolder)
        privateFilesPage.deleteElement(named: sourceFolder)

        // Sign out.
        privateFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }
}
