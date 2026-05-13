//
//  LoginPage.swift
//  PermanentUITests
//
//  Created by Lucian Cerbu on 27.07.2022.
//

import Foundation
import XCTest

class LoginPage {
    let app: XCUIApplication
    
    var emailField: XCUIElement {
        app.textFields.firstMatch
    }
    var passwordField: XCUIElement {
        app.secureTextFields.firstMatch
    }
    var logInButton: XCUIElement {
        app.buttons["Sign in"]
    }
    var signUpButton: XCUIElement {
        app.buttons["Sign Up"]
    }
    var forgotPasswordButton: XCUIElement {
        app.buttons["Forgot password?"]
    }

    var loginScreenTitle: XCUIElement {
        app.staticTexts["Sign in to\nPermanent"]
    }

    var errorBannerText: XCUIElement {
        app.staticTexts["Incorrect email or password."]
    }

    var bannerOkButton: XCUIElement {
        app.buttons["OK"]
    }
    
    init(app: XCUIApplication, testCase: XCTestCase) {
        self.app = app
    }
    
    func login(username: String, password: String) {
        XCTAssertTrue(emailField.waitForExistence(timeout: 5))
        emailField.tap()
        emailField.typeText(username)
        
        XCTAssertTrue(passwordField.waitForExistence(timeout: 5))
        passwordField.tap()
        passwordField.typeText(password)
        
        XCTAssertTrue(logInButton.waitForExistence(timeout: 5))
        logInButton.tap()

        sleep(5)

        dismissSavePasswordPrompt()
    }

    func dismissSavePasswordPrompt() {
        let notNowButton = app.buttons["Not Now"]
        if notNowButton.exists {
            notNowButton.tap()
            sleep(1)
            return
        }

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let springboardNotNow = springboard.buttons["Not Now"]
        if springboardNotNow.exists {
            springboardNotNow.tap()
            sleep(1)
            return
        }

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()
        sleep(1)
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.05)).tap()
        sleep(1)
    }
    
    func waitForExistence() {
        XCTAssertTrue(loginScreenTitle.waitForExistence(timeout: 30))
    }

    func dismissErrorBanner() {
        XCTAssertTrue(errorBannerText.waitForExistence(timeout: 10))
        XCTAssertTrue(bannerOkButton.waitForExistence(timeout: 5))
        bannerOkButton.tap()
        sleep(1)
    }
    
    func navigateToForgotPasswordPage() {
        XCTAssertTrue(forgotPasswordButton.waitForExistence(timeout: 5))
        forgotPasswordButton.tap()
    }
    
    func navigateToSignUpPage() {
        XCTAssertTrue(signUpButton.waitForExistence(timeout: 5))
        signUpButton.tap()
    }
}
