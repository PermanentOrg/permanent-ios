//
//  LoginUITests.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 26.07.2022.
//

import XCTest

class LoginUITests: BaseUITestCase {
    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
    }

    func testPositiveLogin() throws {
        let accountEmail = uiTestCredentials.username
        let accountPassword = uiTestCredentials.password
        
        let signUpPage = SignUpPage(app: app, testCase: self)
        signUpPage.navigateToLogin()
        
        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)
        
        let privateFilesPage = PrivateFilesPage(app: app, testCase: self)
        privateFilesPage.waitForExistence()
        privateFilesPage.toggleRightSideMenu()
        
        let rightSideMenu = RightSideMenuPage(app: app, testCase: self, accountEmail: accountEmail)
        rightSideMenu.waitForExistence()
        
        rightSideMenu.logOut()
        
        signUpPage.waitForExistence()
    }
    
    func testNegativeLogin() throws {
        let accountEmail = "invalidUsername@server.com"
        let accountPassword = "password"
        
        let signUpPage = SignUpPage(app: app, testCase: self)
        signUpPage.navigateToLogin()
        
        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.login(username: accountEmail, password: accountPassword)
        
        loginPage.pressCancelButton()
        
        signUpPage.waitForExistence()
    }
    
    func testForgotPasswordScreen() throws {
        let accountEmail = uiTestCredentials.username
        let invalidAccountEmail = "invalidUsername@server.com"
        
        let signUpPage = SignUpPage(app: app, testCase: self)
        signUpPage.navigateToLogin()
        
        let loginPage = LoginPage(app: app, testCase: self)
        loginPage.navigateToForgotPasswordPage()
        
        let forgotPasswordPage = ForgotPasswordPage(app: app, testCase: self)
        forgotPasswordPage.navigateToLoginPage()
        
        loginPage.navigateToForgotPasswordPage()
        forgotPasswordPage.recoverPassword(email: accountEmail)
        forgotPasswordPage.pressOkButton()
        
        loginPage.navigateToForgotPasswordPage()
        forgotPasswordPage.recoverPassword(email: invalidAccountEmail)
        forgotPasswordPage.pressOkButton()
        
        loginPage.navigateToSignUpPage()
        
        signUpPage.waitForExistence()
    }
}
