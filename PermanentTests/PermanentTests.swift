//
//  PermanentTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 20.07.2021.
//

import XCTest

@testable import Permanent

class LoginTests: XCTestCase {

    var sut: AuthViewModel!
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = AuthViewModel()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLoginTestInvalidCredentials() throws {
        let credentialsInvalid = LoginCredentials("ss@ss.ss", "12345678")
    
        let promise = expectation(description: "Test Login with incorrect username or password.")
        
        sut.login(with: credentialsInvalid, then: { status in
            XCTAssertEqual(status, .error(message: "Incorrect username or password."), "response of login req.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 2)
    }
    
    func testLoginTestValidCredentials() {
        let credentialsInvalid = LoginCredentials("lucian.cerbu@vspartners.us", "12345678")
    
        let promise = expectation(description: "Test login with valid username or password.")
        
        sut.login(with: credentialsInvalid, then: { status in
            
            
            XCTAssertEqual(status, .error(message: "Incorrect username or password."), "response of login req.")
            promise.fulfill()
        })
        wait(for: [promise], timeout: 2)
    }
}
