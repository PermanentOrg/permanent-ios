//
//  VerificationCodeTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 28.07.2021.
//
import XCTest

@testable import Permanent

class SuccessfulVerificationMFACodeTestURLs: TestURLs {
    override var urls: [URL? : Data] {
        get {
            return [
                URL(string:"https://www.permanent.org/api/auth/verify"):"{\"Results\":[{\"data\":[{\"AccountVO\":{\"accountId\":4916,\"primaryEmail\":\"lucian.cerbu@vspartners.us\",\"fullName\":\"Lucian Cerbu VSP\",\"address\":null,\"address2\":null,\"country\":null,\"city\":null,\"state\":null,\"zip\":null,\"primaryPhone\":null,\"defaultArchiveId\":6721,\"level\":null,\"apiToken\":null,\"betaParticipant\":null,\"facebookAccountId\":null,\"googleAccountId\":null,\"status\":\"status.auth.ok\",\"type\":\"type.account.standard\",\"emailStatus\":\"status.auth.verified\",\"phoneStatus\":\"status.auth.none\",\"notificationPreferences\":\"{\\\"textPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}, \\\"emailPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}, \\\"inAppPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}}\",\"agreed\":null,\"optIn\":null,\"emailArray\":null,\"inviteCode\":null,\"rememberMe\":null,\"keepLoggedIn\":null,\"accessRole\":null,\"spaceTotal\":3221225472,\"spaceLeft\":3185847435,\"fileTotal\":null,\"fileLeft\":299993,\"changePrimaryEmail\":null,\"changePrimaryPhone\":null,\"createdDT\":\"2021-06-18T13:20:24\",\"updatedDT\":\"2021-07-22T15:03:14\"}}],\"message\":[\"Verify successful.\"],\"status\":true,\"resultDT\":\"2021-07-22T15:03:14\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"csrf\":\"02d01615c724a055fa7baef826d43617\",\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)! ]
        }
    }
}

class FailedVerificationCodeTestURLs: TestURLs {
    override var urls: [URL? : Data] {
        get {
            return [                URL(string:"https://www.permanent.org/api/auth/verify"):"{\"Results\":[{\"data\":null,\"message\":[\"warning.auth.token_does_not_match\"],\"status\":false,\"resultDT\":\"2021-07-27T22:26:39\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":false,\"actionFailKeys\":[0],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"csrf\":\"1176129730a4ba6ac626acf735c27b4e\",\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)!]
        }
    }
}

class VerificationCodeTests: XCTestCase {
    var sut: VerificationCodeViewModel!
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = VerificationCodeViewModel()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testValidMFAVerificationCode() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<SuccessfulVerificationMFACodeTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config, delegateQueue: OperationQueue())

        let verifyCodeCredentials = VerifyCodeCredentials(email: "account@test.com", code: "1234", type: .mfa)
    
        let promise = expectation(description: "Test verification code with valid data.")
        
        sut.verify(for: verifyCodeCredentials, then: { status in
            XCTAssertEqual(status, .success, "Failed! Checked valid MFA verification code.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 2)
    }
    
    func testValidPhoneVerificationCode() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<SuccessfulVerificationMFACodeTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config, delegateQueue: OperationQueue())

        let verifyCodeCredentials = VerifyCodeCredentials(email: "account@test.com", code: "1234", type: .phone)
    
        let promise = expectation(description: "Test verification code with valid data.")
        
        sut.verify(for: verifyCodeCredentials, then: { status in
            XCTAssertEqual(status, .success, "Failed! Checked valid phone verification code.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 2)
    }
    
    func testInvalidMFAVerificationCode() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<FailedVerificationCodeTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config, delegateQueue: OperationQueue())

        let verifyCodeCredentials = VerifyCodeCredentials(email: "account@test.com", code: "1234", type: .mfa)
    
        let promise = expectation(description: "Test verification code with invalid data.")
        
        sut.verify(for: verifyCodeCredentials, then: { status in
            XCTAssertEqual(status, .error(message: "The code is incorrect."), "Failed! Checked invalid MFA verification code.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 2)
    }
    
    func testInvalidPhoneVerificationCode() {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<FailedVerificationCodeTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config, delegateQueue: OperationQueue())

        let verifyCodeCredentials = VerifyCodeCredentials(email: "account@test.com", code: "1234", type: .phone)
    
        let promise = expectation(description: "Test verification code with valid data.")
        
        sut.verify(for: verifyCodeCredentials, then: { status in
            XCTAssertEqual(status, .error(message: "The code is incorrect."), "Failed! Checked invalid phone verification code.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 2)
    }
}
