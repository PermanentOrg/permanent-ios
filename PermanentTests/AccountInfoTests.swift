//
//  AccountInfoTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 30.07.2021.
//

import XCTest

@testable import Permanent

class SuccessfulAccountInfoTestURLs: TestURLs {
    override var urls: [URL? : Data] {
        return [
            URL(string: "https://www.permanent.org/api/auth/loggedIn"): "{\"Results\":[{\"data\":[{\"SimpleVO\":{\"key\":\"bool\",\"value\":true,\"createdDT\":null,\"updatedDT\":null}}],\"message\":[\"Status retrieved\"],\"status\":true,\"resultDT\":\"2021-08-03T17:59:25\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)!,
            URL(string: "https://www.permanent.org/api/account/get"): "{\"Results\":[{\"data\":[{\"AccountVO\":{\"accountId\":4642,\"primaryEmail\":\"testaccount+prmnttst0001@server.com\",\"fullName\":\"testAccount\",\"address\":null,\"address2\":null,\"country\":null,\"city\":null,\"state\":null,\"zip\":null,\"primaryPhone\":null,\"defaultArchiveId\":6053,\"level\":null,\"apiToken\":null,\"betaParticipant\":null,\"facebookAccountId\":null,\"googleAccountId\":null,\"status\":\"status.auth.ok\",\"type\":\"type.account.standard\",\"emailStatus\":\"status.auth.verified\",\"phoneStatus\":\"status.auth.none\",\"notificationPreferences\":\"{\\\"textPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}, \\\"emailPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}, \\\"inAppPreference\\\": {\\\"apps\\\": {\\\"confirmations\\\": 1}, \\\"share\\\": {\\\"requests\\\": 1, \\\"activities\\\": 1, \\\"confirmations\\\": 1}, \\\"account\\\": {\\\"confirmations\\\": 1, \\\"recommendations\\\": 1}, \\\"archive\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}, \\\"relationships\\\": {\\\"requests\\\": 1, \\\"confirmations\\\": 1}}}\",\"agreed\":null,\"optIn\":null,\"emailArray\":null,\"inviteCode\":null,\"rememberMe\":null,\"keepLoggedIn\":null,\"accessRole\":null,\"spaceTotal\":2147483648,\"spaceLeft\":1948732003,\"fileTotal\":null,\"fileLeft\":199969,\"changePrimaryEmail\":null,\"changePrimaryPhone\":null,\"createdDT\":\"2021-03-18T08:28:15\",\"updatedDT\":\"2021-07-27T23:15:14\"}}],\"message\":[\"Account has been retrieved.\"],\"status\":true,\"resultDT\":\"2021-08-03T18:01:55\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)!,
            URL(string: "https://www.permanent.org/api/account/update"): "{\"Results\":[{\"data\":[{\"AccountVO\":{\"accountId\":\"4642\",\"primaryEmail\":\"testaccount+prmnttst0001@server.com\",\"fullName\":\"testAccount\",\"address\":\"temporary address\",\"address2\":null,\"country\":\"ro\",\"city\":\"city\",\"state\":\"state\",\"zip\":\"333111\",\"primaryPhone\":\"+12345678901\",\"defaultArchiveId\":null,\"level\":null,\"apiToken\":null,\"betaParticipant\":null,\"facebookAccountId\":null,\"googleAccountId\":null,\"status\":\"status.auth.ok\",\"type\":null,\"emailStatus\":null,\"phoneStatus\":\"status.auth.unverified\",\"notificationPreferences\":null,\"createdDT\":null,\"updatedDT\":\"2021-08-03T18:05:35\"}}],\"message\":[\"Account was updated successfully.\"],\"status\":true,\"resultDT\":\"2021-08-03T18:05:35\",\"createdDT\":null,\"updatedDT\":null}],\"isSuccessful\":true,\"actionFailKeys\":[],\"isSystemUp\":true,\"systemMessage\":\"Everything is A-OK\",\"sessionId\":null,\"createdDT\":null,\"updatedDT\":null}".data(using: .utf8)!
        ]
    }
}

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
        sut = InfoViewModel()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }
    
    func testGetUserValidData() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<SuccessfulAccountInfoTestURLs>.self]

        sut.sessionProtocol = APINetworkSession(configuration: config)
        
        let accountId: Int = 1234
        PreferencesManager.shared.set(accountId, forKey: Constants.Keys.StorageKeys.accountIdStorageKey)

        let userData: UpdateUserData = ("testAccount", "testaccount+prmnttst0001@server.com", nil, nil, nil, nil, nil, nil, nil)
        let promise = expectation(description: "Test get of valid data from user.")
        
        sut.getUserData(then: { [self] status in
            XCTAssertEqual(status, .success(message: "User details were received"), "Failed!User data Not received.")
            XCTAssertEqual(sut.userData.fullName, userData.fullName, "Failed! User [fullName] not received correctly.")
            XCTAssertEqual(sut.userData.primaryEmail, userData.primaryEmail, "Failed! User [primaryEmail] not received correctly.")
            XCTAssertEqual(sut.userData.primaryPhone, userData.primaryPhone, "Failed! User [primaryPhone] not received correctly.")
            XCTAssertEqual(sut.userData.address, userData.address, "Failed! User [address] not received correctly.")
            XCTAssertEqual(sut.userData.city, userData.city, "Failed! User [city] not received correctly.")
            XCTAssertEqual(sut.userData.state, userData.state, "Failed! User [state] not received correctly.")
            XCTAssertEqual(sut.userData.zip, userData.zip, "Failed! User [zip] not received correctly.")
            XCTAssertEqual(sut.userData.country, userData.country, "Failed! User [country] not received correctly.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 6)
    }
    
    func testUpdateUserData() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<SuccessfulAccountInfoTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config)
        
        let accountId:Int = 1234
        PreferencesManager.shared.set(accountId, forKey: Constants.Keys.StorageKeys.accountIdStorageKey)

        var userData: UpdateUserData = ("testAccount", "testaccount+prmnttst0001@server.com", nil, nil, nil, nil, nil, nil, nil)

        let validTestResult = expectation(description: "Test get of valid data from user.")
        let invalidUserNameResult = expectation(description: "Test invalid user name.")
        let dataWasNotModified = expectation(description: "Test update data was not modified.")
        
        sut.updateUserData(userData, then: { status in
            XCTAssertEqual(status, .success(message: "Updates were saved"), "Failed!User data Not received.")
            validTestResult.fulfill()
        })
        
        userData.fullName = nil
        sut.dataIsNotModified = false
        sut.updateUserData(userData, then: { status in
            XCTAssertEqual(status, .error(message: "Account name can\'t be empty."), "Failed!Tested invalid user name.")
            invalidUserNameResult.fulfill()
        })
        
        userData.fullName = "testAccount"
        sut.dataIsNotModified = true
        sut.updateUserData(userData, then: { status in
            XCTAssertEqual(status, .error(message: "No modifications were done"), "Failed!Tested data was not modified.")
            dataWasNotModified.fulfill()
        })
        
        wait(for: [validTestResult, invalidUserNameResult, dataWasNotModified], timeout: 6)
    }
    
    func testGetUserInvalidData() throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ResponseURLProtocol<FailedAccountInfoTestURLs>.self]
        sut.sessionProtocol = APINetworkSession(configuration: config)
        
        let accountId:Int = 1234
        PreferencesManager.shared.set(accountId, forKey: Constants.Keys.StorageKeys.accountIdStorageKey)

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
            XCTAssertEqual(status, .error(message: nil), "Failed!User data Not received.")
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
