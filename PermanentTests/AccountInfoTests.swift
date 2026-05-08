//
//  AccountInfoTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 30.07.2021.
//

import XCTest

@testable import Permanent

class FailedAccountInfoTestURLs: TestURLs {
    override var urls: [URL? : Data] {
        return [
            URL(string: "https://www.permanent.org/api/account/get"): "{\"Results\":[{\"data\":[{\"AccountVO\":{\"accountId\":4642,\"primaryEmail\":\"luciancerbu87@gmail.com\",\"fullName\":\"Lucian Cerbu\",\"address\":null,\"address2\":null,\"country\":null,\"city\":null,\"state\":null,\"zip\":null,\"primaryPhone\":null,\"defaultArchiveId\":6053,\"level\":null,\"apiToken\":null,\"betaParticipant\":null,\"facebookAccountId\":null,\"googleAccountId\":null,\"status\":\"status.auth.ok\",\"type\":\"type.account.standard\",\"emailStatus\":\"status.auth.verified\",\"phoneStatus\":\"status.auth.none\",\"notificationPreferences\":\"{\\\"textPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}, \\\"emailPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}, \\\"inAppPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}}\",\"agreed\":null,\"optIn\":null,\"emailArray\":null,\"inviteCode\":null,\"rememberMe\":null,\"keepLoggedIn\":null,\"accessRole\":null,\"spaceTotal\":2147483648,\"spaceLeft\":1948732003,\"fileTotal\":null,\"fileLeft\":199969,\"changePrimaryEmail\":null,\"changePrimaryPhone\":null,\"createdDT\":\"2021-03-18T08:28:15\",\"updatedDT\":\"2021-07-27T23:15:14\"}}],\"message\":[\"Account has been retrieved.\"],\"status\":true,\"resultDT\":\"2021-08-03T18:01:55\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":false,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)!,
            URL(string: "https://www.permanent.org/api/account/update"): "{\"Results\":[{\"data\":[{\"AccountVO\":{\"accountId\":\"4642\",\"primaryEmail\":\"testaccount+prmnttst0001@server.com\",\"fullName\":\"testAccount\",\"address\":\"temporary address\",\"address2\":null,\"country\":\"ro\",\"city\":\"city\",\"state\":\"state\",\"zip\":\"333111\",\"primaryPhone\":\"+12345678901\",\"defaultArchiveId\":null,\"level\":null,\"apiToken\":null,\"betaParticipant\":null,\"facebookAccountId\":null,\"googleAccountId\":null,\"status\":\"status.auth.ok\",\"type\":null,\"emailStatus\":null,\"phoneStatus\":\"status.auth.unverified\",\"notificationPreferences\":null,\"createdDT\":null,\"updatedDT\":\"2021-08-03T18:05:35\"}}],\"message\":[\"Account was updated successfully.\"],\"status\":true,\"resultDT\":\"2021-08-03T18:05:35\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":false,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)!
        ]
    }
}

class AccountInfoTests: XCTestCase {
    var sut: InfoViewModel!
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = InfoViewModel(accountId: 1234)
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testGetUserInvalidData() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<FailedAccountInfoTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config)

        let promise = expectation(description: "Test error case, from get user data api.")

        sut.getUserData(then: { status in
            XCTAssertEqual(status, .error(message: "Something went wrong. Please try again later."), "Failed!User data was received.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 6)
    }
    
    func testUpdateUserDataError() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<FailedAccountInfoTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config)

        let userData: UpdateUserData = ("testAccount", "testaccount+prmnttst0001@server.com", nil, nil, nil, nil, nil, nil, nil)
        let invalidTestResult = expectation(description: "Test invalid api response.")
        
        sut.updateUserData(userData, then: { status in
            XCTAssertEqual(status, .error(message: "Something went wrong. Please try again later."), "Failed!User data Not received.")
            invalidTestResult.fulfill()
        })
        wait(for: [invalidTestResult], timeout: 6)
    }
    
    func testPhoneNumberFormat() throws {
        let formatString = "+ZZZZZZZZZZZ"
        let phoneNumbers = [
            "1234567890000": "+12345678900",
            "aassnnc221123331": "+221123331",
            "+2223311234441231": "+22233112344"
        ]
        
        for (inputPhoneNumber, outputPhoneNumber) in phoneNumbers {
            XCTAssertEqual(sut.format(with: formatString, phone: inputPhoneNumber), outputPhoneNumber, "Test scenario.")
        }
    }
    
    func testValuesFromTestField() throws {
        let userData: UpdateUserData = ("testAccount", "testaccount+prmnttst0001@server.com", "+123456", "Test location", "Test location2", "Test city", "N/A", nil, "RO")
        sut.userData = userData
        
        sut.userData.zip = "123456"
        sut.dataIsNotModified = true
        
        sut.getValuesFromTextFieldValue(receivedData: userData)
        XCTAssertFalse(sut.dataIsNotModified, "")
    }
}
