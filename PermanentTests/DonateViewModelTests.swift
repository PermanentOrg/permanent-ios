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

    // MARK: - wholeDollarAmount

    func testWholeDollarAmount_NilText_ReturnsZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.wholeDollarAmount(from: nil), 0)
    }

    func testWholeDollarAmount_EmptyText_ReturnsZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.wholeDollarAmount(from: ""), 0)
    }

    func testWholeDollarAmount_WholeNumber_ReturnsIt() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.wholeDollarAmount(from: "20"), 20)
    }

    func testWholeDollarAmount_Fraction_FloorsToWholeDollars() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.wholeDollarAmount(from: "10.99"), 10)
    }

    func testWholeDollarAmount_UnderOneDollar_ReturnsZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.wholeDollarAmount(from: ".5"), 0)
    }

    func testWholeDollarAmount_Negative_ReturnsZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.wholeDollarAmount(from: "-5"), 0)
    }

    func testWholeDollarAmount_Junk_ReturnsZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.wholeDollarAmount(from: "abc"), 0)
    }

    func testWholeDollarAmount_UpperLimit_ReturnsIt() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.wholeDollarAmount(from: "10000"), 10000)
    }

    func testWholeDollarAmount_Infinity_ReturnsZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.wholeDollarAmount(from: "inf"), 0)
    }

    func testWholeDollarAmount_BeyondIntRange_ReturnsZero() {
        let vm = DonateViewModel()
        XCTAssertEqual(vm.wholeDollarAmount(from: "1e300"), 0)
    }

    // MARK: - createStoragePurchase edge cases

    func testCreateStoragePurchase_NoSession_ReturnsNil() {
        let vm = DonateViewModel()
        let expectation = expectation(description: "completion")

        vm.createStoragePurchase(amountInUSD: 10) { secret in
            XCTAssertNil(secret)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testCreateStoragePurchase_ZeroAmount_ReturnsNil() {
        let vm = DonateViewModel()
        let expectation = expectation(description: "completion")

        vm.createStoragePurchase(amountInUSD: 0) { secret in
            XCTAssertNil(secret)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}
