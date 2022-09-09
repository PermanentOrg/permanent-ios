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
    
        let signUpPage = SignUpPage(app: app, testCase: self)
        signUpPage.navigateToLogin()

        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)
 
        let leftMenu = LeftSideMenuPage(app: app, testCase: self)
        leftMenu.goToSharedFiles()
        
        let sharedFilesPage = SharedFilesPage(app: app, testCase: self)
        
        sharedFilesPage.testMoreFileOptionsForSharedByMe()
        
        sharedFilesPage.goToSharedWithMeTab()
        sharedFilesPage.enterFolderWithOwnerAccess()
        sleep(1)
        sharedFilesPage.testAddButtonIsPresent()
        
        sharedFilesPage.createNewFolder(name: "a test")
        ///TO DO -redesign test case, after this bug is resolved : when you are creating a new folder in shared with me section, reload the shared files menu is needed.
        leftMenu.goToSharedFiles()
        
        sharedFilesPage.goToSharedWithMeTab()
        sharedFilesPage.enterFolderWithOwnerAccess()
        
        sharedFilesPage.renameFirstElementFromFolder(name: "a test folder")
        leftMenu.goToSharedFiles()
        
        sharedFilesPage.goToSharedWithMeTab()
        sharedFilesPage.enterFolderWithOwnerAccess()
        
        sharedFilesPage.enterFolder(withName: "a test folder")
        sharedFilesPage.enterPhotoLibrary()
        
        let photoLibraryPage = PhotoLibraryPage(app: app, testCase: self)
        photoLibraryPage.waitForExistence()
        
        photoLibraryPage.uploadFirstPhoto()
        
        sharedFilesPage.processUpload()
        
        sharedFilesPage.renameFirstElementFromFolder(name: "uploaded file")
        
        sleep(1)
        
        sharedFilesPage.downloadFirstElementFromFolder()
                        
        sharedFilesPage.processDownload()
        
        sharedFilesPage.deleteFirstElementFromFolder()
        
        sharedFilesPage.emptyFolderTest()
        
        sharedFilesPage.goBack()
        
        sharedFilesPage.deleteFirstElementFromFolder()
        
        sharedFilesPage.goBack()
        
        sharedFilesPage.testMoreFileOptionsMenuOwnerAccess()
        
        leftMenu.goToSharedFiles()
        
        sharedFilesPage.goToSharedWithMeTab()
        
        sharedFilesPage.enterFolderWithViewerAccess()
        
        sharedFilesPage.testMoreFileOptionsMenuViewerAccess()
        
        sharedFilesPage.toggleRightSideMenu()
        
        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        rightSideMenu.logOut()
        sleep(2)
        
        XCTAssertTrue(signUpPage.signUpStaticText.waitForExistence(timeout: 10))
    }
}
