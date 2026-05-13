//
//  SharedFilesBrowsingUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 13.05.2026.
//

import XCTest

class SharedFilesBrowsingUITests: BaseUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
    }

    func testSharedFilesTabsAndViewToggle() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let leftMenu = LeftSideMenuPage(app: app, testCase: self)
        leftMenu.goToSharedFiles()

        let sharedFilesPage = SharedFilesPage(app: app, testCase: self)
        sharedFilesPage.waitForExistence()

        // Toggle between list and grid view on the default "Shared By Me" tab.
        sharedFilesPage.toggleListGridView()
        sharedFilesPage.toggleListGridView()

        // Switch to "Shared With Me" tab.
        sharedFilesPage.goToSharedWithMeTab()

        // Toggle the view again on the Shared With Me tab.
        sharedFilesPage.toggleListGridView()
        sharedFilesPage.toggleListGridView()

        // Switch back to "Shared By Me" to verify navigation works both ways.
        sharedFilesPage.goToSharedByMeTab()

        // Sign out
        sharedFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }
}
