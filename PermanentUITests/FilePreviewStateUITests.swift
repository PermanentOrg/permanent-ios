//
//  FilePreviewStateUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 12.06.2026.
//

import XCTest

/// UI tests for the full screen image preview loading / failure states (VSP-1768).
/// The states are driven deterministically through the DEBUG-only launch arguments
/// handled by FilePreviewViewController and AppDelegate.
class FilePreviewStateUITests: BaseUITestCase {

    override func setUpWithError() throws {
        // Launch arguments must be appended before BaseUITestCase launches the app.
        if name.contains("LoadFailed") {
            app.launchArguments.append("--failFullResOnce")
        } else if name.contains("Offline") {
            app.launchArguments.append("--forceOffline")
        }
        try super.setUpWithError()
    }

    /// S6 → S8 → S4: the first full-res load fails and shows the retry card;
    /// tapping it retries and the image eventually renders without the overlay.
    func testImagePreviewLoadFailedShowsRetryAndRecovers() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        // Seed: aaa_-prefixed folder + one uploaded photo.
        let folderName = "aaa_state_\(UUID().uuidString.prefix(6))"
        privateFilesPage.createNewFolder(name: folderName)
        privateFilesPage.enterFolder(named: folderName)

        privateFilesPage.enterPhotoLibrary()

        let photoLibraryPage = PhotoLibraryPage(app: app, testCase: self)
        photoLibraryPage.waitForExistence()
        photoLibraryPage.uploadFirstPhoto()

        privateFilesPage.processUpload()
        privateFilesPage.tapFirstFileCell()

        let previewPage = FilePreviewPage(app: app)
        previewPage.waitForExistence()

        // --failFullResOnce makes the first full-res attempt fail → S6.
        previewPage.waitForLoadFailedState()

        // Tap to retry → S8 → the second attempt succeeds → overlay disappears (S4).
        previewPage.tapRetry()
        previewPage.waitForImageLoaded()

        previewPage.close()
        privateFilesPage.waitForExistence()

        // Cleanup: delete the photo + the folder.
        privateFilesPage.deleteFirstElementFromFolder()
        privateFilesPage.emptyFolderTest()
        privateFilesPage.goBack()
        privateFilesPage.deleteElement(named: folderName)

        privateFilesPage.toggleRightSideMenu()
        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)
        loginPage.waitForExistence()
    }

    /// S7: while offline, opening an image shows the offline card and tapping it
    /// does not start a load — the card stays until connectivity returns.
    func testImagePreviewOfflineStateBlocksLoading() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        let folderName = "aaa_state_\(UUID().uuidString.prefix(6))"
        privateFilesPage.createNewFolder(name: folderName)
        privateFilesPage.enterFolder(named: folderName)

        privateFilesPage.enterPhotoLibrary()

        let photoLibraryPage = PhotoLibraryPage(app: app, testCase: self)
        photoLibraryPage.waitForExistence()
        photoLibraryPage.uploadFirstPhoto()

        privateFilesPage.processUpload()
        privateFilesPage.tapFirstFileCell()

        let previewPage = FilePreviewPage(app: app)
        previewPage.waitForExistence()

        // --forceOffline makes the viewer treat the device as offline → S7.
        // (Real network stays up, so login/upload above and cleanup below still work.)
        previewPage.waitForOfflineState()

        // Tapping while offline must not start a load — the offline card stays.
        previewPage.tapRetry()
        sleep(2)
        previewPage.waitForOfflineState()

        previewPage.close()
        privateFilesPage.waitForExistence()

        privateFilesPage.deleteFirstElementFromFolder()
        privateFilesPage.emptyFolderTest()
        privateFilesPage.goBack()
        privateFilesPage.deleteElement(named: folderName)

        privateFilesPage.toggleRightSideMenu()
        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)
        loginPage.waitForExistence()
    }
}
