//
//  SharedFilesUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 10.08.2022.
//

import XCTest

class SharedFilesUITests: BaseUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
    }
    
    func testSharedFilesMenu() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)

        let leftMenu = LeftSideMenuPage(app: app, testCase: self)
        leftMenu.goToSharedFiles()

        let sharedFilesPage = SharedFilesPage(app: app, testCase: self)

        sharedFilesPage.emptyFolderTest()

        sharedFilesPage.goToSharedWithMeTab()
        sleep(2)

        sharedFilesPage.toggleRightSideMenu()

        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)

        loginPage.waitForExistence()
    }
}
