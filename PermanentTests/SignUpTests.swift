//
//  SignUpTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 26.07.2021.
//

import XCTest

@testable import Permanent

class SuccessfulSignUpTestURLs: TestURLs {
    override var urls: [URL? : Data] {
        return [
            URL(string: "https://www.permanent.org/api/account/post"):"{\"Results\":[{\"data\":[{\"AccountVO\":{\"accountId\":5035,\"primaryEmail\":\"testaccount+prmnttst0001@server.com\",\"fullName\":\"testAccount\",\"address\":null,\"address2\":null,\"country\":null,\"city\":null,\"state\":null,\"zip\":null,\"primaryPhone\":null,\"defaultArchiveId\":7006,\"level\":null,\"apiToken\":null,\"betaParticipant\":null,\"facebookAccountId\":null,\"googleAccountId\":null,\"status\":\"status.auth.ok\",\"type\":\"type.account.test\",\"emailStatus\":\"status.auth.unverified\",\"phoneStatus\":\"status.auth.none\",\"notificationPreferences\":\"{\\n                                        \\\"emailPreference\\\": {\\n                                        \\\"account\\\": {\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"recommendations\\\": 1\\n                                        },\\n                                        \\\"apps\\\": {\\n                                        \\\"confirmations\\\": 1\\n                                        },\\n                                        \\\"archive\\\": {\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"requests\\\": 1\\n                                        },\\n                                        \\\"relationships\\\": {\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"requests\\\": 1\\n                                        },\\n                                        \\\"share\\\": {\\n                                        \\\"activities\\\": 1,\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"requests\\\": 1\\n                                        }},\\n                                        \\\"inAppPreference\\\":  {\\n                                        \\\"account\\\": {\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"recommendations\\\": 1\\n                                        },\\n                                        \\\"apps\\\": {\\n                                        \\\"confirmations\\\": 1\\n                                        },\\n                                        \\\"archive\\\": {\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"requests\\\": 1\\n                                        },\\n                                        \\\"relationships\\\": {\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"requests\\\": 1\\n                                        },\\n                                        \\\"share\\\": {\\n                                        \\\"activities\\\": 1,\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"requests\\\": 1\\n                                        }},\\n                                        \\\"textPreference\\\": {\\n                                        \\\"account\\\": {\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"recommendations\\\": 1\\n                                        },\\n                                        \\\"apps\\\": {\\n                                        \\\"confirmations\\\": 1\\n                                        },\\n                                        \\\"archive\\\": {\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"requests\\\": 1\\n                                        },\\n                                        \\\"relationships\\\": {\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"requests\\\": 1\\n                                        },\\n                                        \\\"share\\\": {\\n                                        \\\"activities\\\": 1,\\n                                        \\\"confirmations\\\": 1,\\n                                        \\\"requests\\\": 1\\n                                        }}}\",\"createdDT\":\"2021-07-26T13:38:33\",\"updatedDT\":\"2021-07-26T13:38:33\"}}],\"message\":[\"New account created accountId: 5035\"],\"status\":true,\"resultDT\":\"2021-07-26T13:38:36\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"csrf\":\"c92c2b03d5191ded47e48ee89cacae3c\",\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)!
        ]
    }
}

class FailedSignUpTestURLs: TestURLs {
    override var urls: [URL? : Data] {
        return [
            URL(string: "https://www.permanent.org/api/account/post"):"{\"Results\":[{\"data\":null,\"message\":[\"warning.registration.duplicate_email\"],\"status\":false,\"resultDT\":\"2021-07-26T13:59:05\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":false,\"actionFailKeys\":[0],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"csrf\":\"ed88b0eb1557a7d5e7591683d154c625\",\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)!
        ]
    }
}
}

class SignUpTests: XCTestCase {
    var sut: AuthViewModel!
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = AuthViewModel()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testSigupTestInvalidCredentials() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<FailedSignUpTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config)
        
        let credentialsInvalid = SignUpCredentials(name: "testAccount", loginCredentials: LoginCredentials(email: "testaccount+prmnttst0001@server.com", password: "simplePass"))
        
        let promise = expectation(description: "Test Sign Up with duplicate email.")
        
        sut.signUp(with: credentialsInvalid, then: { status in
            XCTAssertEqual(status, .error(message: "This email is already in use."), "Failed! Checked with duplicate email.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 6)
    }
    
    func testSigupTestValidCredentials() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<SuccessfulSignUpTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config)
        
        let credentialsInvalid = SignUpCredentials(name: "testAccount", loginCredentials: LoginCredentials(email: "testaccount+prmnttst0001@server.com", password: "simplePass"))
        
        let promise = expectation(description: "Test Sign Up with valid username/email/password.")
        
        sut.signUp(with: credentialsInvalid, then: { status in
            XCTAssertEqual(status, .success, "Failed! Checked with valid username/email/password.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 6)
    }
    
    func testEmptyEmailField() {
        var credentials: (nameField: String?, emailField: String?, passwordField: String?) = (nameField: "testAccount", emailField: "account@test.com", passwordField: "simplePassword")
        credentials.emailField = nil
        
        XCTAssertFalse(sut.areFieldsValid(nameField: credentials.nameField, emailField: credentials.emailField, passwordField: credentials.passwordField), "Failed! Checked empty email field.")
    }
    
    func testEmptyUsernameField() {
        var credentials: (nameField: String?, emailField: String?, passwordField: String?) = (nameField: "testAccount", emailField: "account@test.com", passwordField: "simplePassword")
        credentials.nameField = nil
        
        XCTAssertFalse(sut.areFieldsValid(nameField: credentials.nameField, emailField: credentials.emailField, passwordField: credentials.passwordField), "Failed! Checked empty username field.")
    }
    
    func testShortPasswordField() {
        var credentials: (nameField: String?, emailField: String?, passwordField: String?) = (nameField: "testAccount", emailField: "account@test.com", passwordField: "simplePassword")
        credentials.passwordField = "1234"
        
        XCTAssertFalse(sut.areFieldsValid(nameField: credentials.nameField, emailField: credentials.emailField, passwordField: credentials.passwordField), "Failed! Checked short password field.")
    }
    
    func testEmptyPasswordField() {
        var credentials: (nameField: String?, emailField: String?, passwordField: String?) = (nameField: "testAccount", emailField: "account@test.com", passwordField: "simplePassword")
        credentials.passwordField = nil
        
        XCTAssertFalse(sut.areFieldsValid(nameField: credentials.nameField, emailField: credentials.emailField, passwordField: credentials.passwordField), "Failed! Checked empty password field.")
    }
    
    func testValidUsernameEmailPasswordFields() {
        let credentials: (nameField: String?, emailField: String?, passwordField: String?) = (nameField: "testAccount", emailField: "account@test.com", passwordField: "simplePassword")
        
        XCTAssertTrue(sut.areFieldsValid(nameField: credentials.nameField, emailField: credentials.emailField, passwordField: credentials.passwordField), "Failed! Checked valid username/email/password fields.")
    }
}
