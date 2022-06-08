//
//  DonateTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 06.06.2022.
//
import XCTest

@testable import Permanent

class DonateTests: XCTestCase {
    var sut: DonateViewModel!
    override func setUpWithError() throws {
        try super.setUpWithError()
        sut = DonateViewModel()
    }
    
    override func tearDownWithError() throws {
        sut = nil
        try super.tearDownWithError()
    }

    func testStorageAmmountValid() throws {
        let inputOutputData: [Double?: Int] = [
            0: 0,
            1: 0,
            9: 0,
            22: 2,
            59: 5,
            60: 6
        ]
        
        for (input, output) in inputOutputData {
            let currentResult = sut.storageSizeForAmount(input)
                    
            XCTAssertEqual(currentResult, output, "Verify if output value \(output) is equal with current value \(currentResult)")
        }
    }
    
    func testStorageAmmountInvalid() throws {
        let inputOutputData: [Double?: Int] = [
            0: 0,
            -1: 0,
            -22: 0
        ]
        
        for (input, output) in inputOutputData {
            let currentResult = sut.storageSizeForAmount(input)
                    
            XCTAssertEqual(currentResult, output, "Verify if output value \(output) is equal with current value \(currentResult)")
        }
    }
    
    func testJsonInitWithValidValues() throws {
        let testAccountId = 22
        let testEmail = "test@test.com"
        let testAmount = 3
        let isAnonymous = true
        let testName = "Test account"
        
        let currentResult = sut.paymentSheetPayload(accountId: testAccountId, email: testEmail, amount: testAmount, isAnonymous: isAnonymous, name: testName)
        
        XCTAssertEqual(testAccountId, currentResult["accountId"] as? Int, "Verification of account id from JSON")
        XCTAssertEqual(testEmail, currentResult["email"] as? String, "Verification of email from JSON")
        XCTAssertEqual(testAmount, currentResult["amount"] as? Int, "Verification of amount from JSON")
        XCTAssertEqual(isAnonymous, currentResult["anonymous"] as? Bool, "Verification of isAnonymous from JSON")
        XCTAssertEqual(testName, currentResult["name"] as? String, "Verification of name from JSON")
    }
}
