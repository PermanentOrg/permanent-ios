//
//  UploadFilesUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 27.07.2022.
//

import XCTest

class UploadFilesUITests: XCTestCase {
    let app = XCUIApplication()
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        
        app.launch()
        sleep(5)
    }

    override func tearDownWithError() throws {
    }
    
    func testAddFilesOwner() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password
        
        let signUpPage = SignUpPage(app: app, testCase: self)
        signUpPage.navigateToLogin()
        
        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)
        
        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()
        
        privateFilesPage.createNewFolder(name: "uploads")
        
        privateFilesPage.enterPhotoLibrary()
        
        let photoLibraryPage = PhotoLibraryPage(app: app, testCase: self)
        photoLibraryPage.waitForExistence()
        
        photoLibraryPage.uploadFirstPhoto()
        
        privateFilesPage.processUpload()
        
        privateFilesPage.deleteFirstElementFromFolder()
        
        privateFilesPage.emptyFolderTest()
        
        privateFilesPage.goBack()
        
        privateFilesPage.deleteFirstElementFromFolder()
        
        privateFilesPage.emptyFolderTest()
        
        privateFilesPage.toggleRightSideMenu()
        
        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
    }
}
