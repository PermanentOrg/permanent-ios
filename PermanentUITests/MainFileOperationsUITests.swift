//
//  MainFileOperationsUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 13.05.2026.
//

import XCTest

class MainFileOperationsUITests: BaseUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
    }

    /// The navigation path this run should exercise. Default DEV-Debug is Stela V2;
    /// `TEST_RUNNER_STELA_NAV=0` forces the V1 failsafe (see BaseUITestCase).
    private var expectedNavSource: String {
        ProcessInfo.processInfo.environment["STELA_NAV"] == "0" ? "v1" : "v2"
    }

    /// Folder drill-in must give the same outcome on V2 and V1, and runs under both flag states. The
    /// nav-source accessibility id proves which path ran, so V2 can't pass on the V1 failsafe.
    func testFolderNavigationParity() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        let folderName = "aaae2e_nav_\(UUID().uuidString.prefix(6))"
        privateFilesPage.createNewFolder(name: folderName)
        privateFilesPage.assertElementExists(named: folderName)

        // Drill in — this is the Stela V2 (or V1 failsafe) navigateMin path.
        privateFilesPage.enterFolder(named: folderName)
        privateFilesPage.emptyFolderTest()

        // Confirm the children loaded via the path this run is meant to exercise.
        let navSource = app.collectionViews["files-nav-source-\(expectedNavSource)"]
        XCTAssertTrue(navSource.waitForExistence(timeout: 15),
                      "folder drill-in should have loaded via \(expectedNavSource)")

        privateFilesPage.goBack()
        privateFilesPage.waitForExistence()

        // Cleanup by name so no real archive item is touched.
        privateFilesPage.deleteElement(named: folderName)

        // Sign out.
        privateFilesPage.toggleRightSideMenu()
        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }

    func testSearchInPrivateFiles() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        // Open the search screen.
        privateFilesPage.tapSearchButton()

        let searchPage = SearchFilesPage(app: app)
        searchPage.waitForExistence()

        // Search for a known item in the archive ("z_Tree" is always present), then clear.
        searchPage.typeQuery("z_Tree")
        searchPage.assertResultExists(named: "z_Tree")
        searchPage.clearText()

        // Close the search screen.
        searchPage.close()

        // Verify we're back on the Private Files screen.
        privateFilesPage.waitForExistence()

        // Sign out.
        privateFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }

    func testListGridViewToggleAndRenameFolder() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        // Toggle list/grid view twice to verify both layouts render.
        privateFilesPage.toggleListGridView()
        privateFilesPage.toggleListGridView()

        // A folder we can safely rename, prefixed so it sorts to the top of the A-Z list and the
        // file-menu helpers target it consistently.
        let originalName = "aaa_rename_\(UUID().uuidString.prefix(6))"
        let renamedName = "aaa_renamed_\(UUID().uuidString.prefix(6))"
        privateFilesPage.createNewFolder(name: originalName)
        privateFilesPage.assertElementExists(named: originalName)

        // Rename the folder via the file menu.
        privateFilesPage.renameFirstElementFromFolder(name: renamedName)
        privateFilesPage.assertElementExists(named: renamedName)

        // Cleanup: target the renamed folder by name so we never tap a real archive item.
        privateFilesPage.deleteElement(named: renamedName)

        // Sign out.
        privateFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }

    func testMultiSelectSelectAllAndCancel() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()

        // Create a couple of folders so multi-select has something to act on. The
        // "aaa_" prefix keeps them at the top of the Name (A-Z) list.
        let firstFolder = "aaa_multi_a_\(UUID().uuidString.prefix(6))"
        let secondFolder = "aaa_multi_b_\(UUID().uuidString.prefix(6))"
        privateFilesPage.createNewFolder(name: firstFolder)
        privateFilesPage.createNewFolder(name: secondFolder)

        // Enter multi-select mode.
        privateFilesPage.enterMultiSelectMode()

        // Tapping again should select all items.
        privateFilesPage.selectAllInMultiSelect()

        // Cancel multi-select mode.
        privateFilesPage.cancelMultiSelect()

        // Cleanup: target each created folder by name so existing archive items are never touched.
        privateFilesPage.deleteElement(named: firstFolder)
        privateFilesPage.deleteElement(named: secondFolder)

        // Sign out.
        privateFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }
}
