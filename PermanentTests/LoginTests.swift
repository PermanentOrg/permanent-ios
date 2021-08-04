//
//  PermanentTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 20.07.2021.
//

import XCTest

@testable import Permanent

class SuccessfulLoginTestURLs: TestURLs {
    override var urls: [URL? : Data] {
        get {
            return [
                URL(string:"https://www.permanent.org/api/auth/login"):"{\"Results\":[{\"data\":null,\"message\":[\"warning.auth.mfaToken\"],\"status\":false,\"resultDT\":\"2021-07-22T13:03:56\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":false,\"actionFailKeys\":[0],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"csrf\":\"bbcd4d14543c96a5fd64f0e795eab818\",\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)!,
                URL(string:"https://www.permanent.org/api/auth/verify"):"{\"Results\":[{\"data\":[{\"AccountVO\":{\"accountId\":4916,\"primaryEmail\":\"testaccount+prmnttst0001@server.com\",\"fullName\":\"testAccount\",\"address\":null,\"address2\":null,\"country\":null,\"city\":null,\"state\":null,\"zip\":null,\"primaryPhone\":null,\"defaultArchiveId\":6721,\"level\":null,\"apiToken\":null,\"betaParticipant\":null,\"facebookAccountId\":null,\"googleAccountId\":null,\"status\":\"status.auth.ok\",\"type\":\"type.account.standard\",\"emailStatus\":\"status.auth.verified\",\"phoneStatus\":\"status.auth.none\",\"notificationPreferences\":\"{\\\"textPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}, \\\"emailPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}, \\\"inAppPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}}\",\"agreed\":null,\"optIn\":null,\"emailArray\":null,\"inviteCode\":null,\"rememberMe\":null,\"keepLoggedIn\":null,\"accessRole\":null,\"spaceTotal\":3221225472,\"spaceLeft\":3185847435,\"fileTotal\":null,\"fileLeft\":299993,\"changePrimaryEmail\":null,\"changePrimaryPhone\":null,\"createdDT\":\"2021-06-18T13:20:24\",\"updatedDT\":\"2021-07-22T15:03:14\"}}],\"message\":[\"Verify successful.\"],\"status\":true,\"resultDT\":\"2021-07-22T15:03:14\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"csrf\":\"02d01615c724a055fa7baef826d43617\",\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)! ]
        }
    }
}

class FailedLoginTestURLs: TestURLs {
    override var urls: [URL? : Data] {
        get {
            return [URL(string:"https://www.permanent.org/api/auth/login"):"{\"Results\":[{\"data\":null,\"message\":[\"warning.signin.unknown\"],\"status\":false,\"resultDT\":\"2021-07-22T13:18:01\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":false,\"actionFailKeys\":[0],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"csrf\":\"50b44b4f2db2e7913c12c57b89170bab\",\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)!]
        }
    }
}

class LoginTests: XCTestCase {
    var sut: AuthViewModel!
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = AuthViewModel()
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testLoginTestInvalidCredentials() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<FailedLoginTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config)

        let credentialsInvalid = LoginCredentials("account@test.com", "simplePass")
    
        let promise = expectation(description: "Test Login with incorrect username or password.")
        
        sut.login(with: credentialsInvalid, then: { status in
            XCTAssertEqual(status, .error(message: "Incorrect username or password."), "Failed! Checked incorrect username/password.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 6)
    }
    
    func testLoginTestValidCredentials() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<SuccessfulLoginTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config)

        let credentialsValid = LoginCredentials("account@test.com", "simplePass")
    
        let promise = expectation(description: "Test login with valid username or password.")
        
        sut.login(with: credentialsValid, then: { status in
            XCTAssertEqual(status, .mfaToken, "Failed! Checked valid username/password.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 6)
    }
    
    func testEmptyEmailField() {
        let credentials = LoginCredentials("account@test.com", "simplePassword")
        let email: String? = nil
        let password: String? = credentials.password
        
        XCTAssertFalse(sut.areFieldsValid(emailField: email, passwordField: password) , "Failed! Checked empty email field.")
    }
    
    func testEmptyPassField() {
        let credentials = LoginCredentials("account@test.com", "simplePassword")
        let email: String? = credentials.email
        let password: String? = nil
        
        XCTAssertFalse(sut.areFieldsValid(emailField: email, passwordField: password), "Failed! Checked empty password field.")
    }
    
    func testValidEmailPassFields() {
        let credentials = LoginCredentials("account@test.com", "simplePassword")
        let email: String? = credentials.email
        let password: String? = credentials.password
        
        XCTAssertTrue(sut.areFieldsValid(emailField: email, passwordField: password), "Failed! Checked valid email/password fields.")
    }
}
