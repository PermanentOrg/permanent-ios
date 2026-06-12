//
//  DonateViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

final class DonateViewModelTests: XCTestCase {

    // MARK: - storageSizeForAmount

    func testStorageSize_NilAmount_ReturnsZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(nil), 0)
    }

    func testStorageSize_ZeroAmount_ReturnsZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(0), 0)
    }

    func testStorageSize_TenDollars_ReturnsOne() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(10), 1)
    }

    func testStorageSize_TwentyDollars_ReturnsTwo() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(20), 2)
    }

    func testStorageSize_FiftyDollars_ReturnsFive() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(50), 5)
    }

    func testStorageSize_HundredDollars_ReturnsTen() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(100), 10)
    }

    func testStorageSize_FifteenDollars_FloorsToOne() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(15), 1)
    }

    func testStorageSize_NineDollars_FloorsToZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(9), 0)
    }

    func testStorageSize_NegativeAmount_ReturnsZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(-5), 0)
    }

    func testStorageSize_LargeAmount_ReturnsCorrect() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(1000), 100)
    }

    func testStorageSize_FractionalAmount() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.storageSizeForAmount(10.5), 1)
    }

    // MARK: - paymentSheetPayload

    func testPaymentPayload_ContainsAccountId() {
        let vm = DonateViewModel()
        let payload = vm.paymentSheetPayload(accountId: 42, email: "test@test.com", amount: 100, isAnonymous: false, name: "John")
        XCTAssertEqual(payload["accountId"] as? Int, 42)
    }

    func testPaymentPayload_ContainsEmail() {
        let vm = DonateViewModel()
        let payload = vm.paymentSheetPayload(accountId: 1, email: "user@example.com", amount: 50, isAnonymous: false, name: "Jane")
        XCTAssertEqual(payload["email"] as? String, "user@example.com")
    }

    func testPaymentPayload_ContainsAmount() {
        let vm = DonateViewModel()
        let payload = vm.paymentSheetPayload(accountId: 1, email: "a@b.com", amount: 200, isAnonymous: false, name: "Bob")
        XCTAssertEqual(payload["amount"] as? Int, 200)
    }

    func testPaymentPayload_ContainsAnonymousTrue() {
        let vm = DonateViewModel()
        let payload = vm.paymentSheetPayload(accountId: 1, email: "a@b.com", amount: 10, isAnonymous: true, name: "Anon")
        XCTAssertEqual(payload["anonymous"] as? Bool, true)
    }

    func testPaymentPayload_ContainsName() {
        let vm = DonateViewModel()
        let payload = vm.paymentSheetPayload(accountId: 1, email: "a@b.com", amount: 10, isAnonymous: false, name: "Alice")
        XCTAssertEqual(payload["name"] as? String, "Alice")
    }

    func testPaymentPayload_HasFiveKeys() {
        let vm = DonateViewModel()
        let payload = vm.paymentSheetPayload(accountId: 1, email: "a@b.com", amount: 10, isAnonymous: false, name: "X")
        XCTAssertEqual(payload.count, 5)
    }

    func testPaymentPayload_AnonymousFalse() {
        let vm = DonateViewModel()
        let payload = vm.paymentSheetPayload(accountId: 1, email: "a@b.com", amount: 10, isAnonymous: false, name: "X")
        XCTAssertEqual(payload["anonymous"] as? Bool, false)
    }

    // MARK: - Session-dependent computed properties (no session)

    func testAccountId_NoSession_ReturnsNil() {
        let vm = DonateViewModel()
        XCTAssertNil(vm.accountId)
    }

    func testAccountName_NoSession_ReturnsNil() {
        let vm = DonateViewModel()
        XCTAssertNil(vm.accountName)
    }

    func testEmail_NoSession_ReturnsNil() {
        let vm = DonateViewModel()
        XCTAssertNil(vm.email)
    }

    // MARK: - createPaymentIntent edge case

    func testCreatePaymentIntent_NoSession_ReturnsNil() {
        let vm = DonateViewModel()
        let expectation = expectation(description: "completion")

        vm.createPaymentIntent(amount: 100) { secret in
            XCTAssertNil(secret)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
