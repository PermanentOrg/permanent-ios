//
//  SharedFilesUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 10.08.2022.
//

import XCTest

class SharedFilesUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app.launch()
        sleep(5)
    }

    override func tearDownWithError() throws {
    }
    
    func testSharedFilesMenu() throws {
        let accountEmail = uiTestCredentials.username
//        let accountPassword = uiTestCredentials.password
//
//        let signUpPage = SignUpPage(app: app, testCase: self)
//        signUpPage.navigateToLogin()
//
//        let loginPage = LoginPage(app: app, testCase: self)
//        loginPage.login(username: accountEmail, password: accountPassword)
 
        let leftMenu = LeftSideMenuPage(app: app, testCase: self)
        leftMenu.goToSharedFiles()
        
        let sharedFilesPage = SharedFilesPage(app: app, testCase: self)
        sharedFilesPage.goToSharedWithMeTab()
        sharedFilesPage.enterFolderWithOwnerAccess()
        sharedFilesPage.testAddButtonIsPresent()
        
        sharedFilesPage.createNewFolder(name: "a test folder")
        
        sharedFilesPage.goBack()
        
        sharedFilesPage.toggleRightSideMenu()
        
        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
    }
}
