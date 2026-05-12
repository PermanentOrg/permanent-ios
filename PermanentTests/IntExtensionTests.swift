//
//  IntExtensionTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class IntExtensionTests: XCTestCase {

    // MARK: - Int.bytesToReadableForm

    func testInt_ZeroBytes() {
        XCTAssertEqual(0.bytesToReadableForm(), "0 B")
    }

    func testInt_SmallBytes() {
        XCTAssertEqual(500.bytesToReadableForm(), "500 B")
    }

    func testInt_OneKB() {
        let result = 1024.bytesToReadableForm()
        XCTAssertTrue(result.contains("KB"), "Expected KB, got: \(result)")
    }

    func testInt_OneMB() {
        let result = (1024 * 1024).bytesToReadableForm()
        XCTAssertTrue(result.contains("MB"), "Expected MB, got: \(result)")
    }

    func testInt_OneGB() {
        let result = (1024 * 1024 * 1024).bytesToReadableForm()
        XCTAssertTrue(result.contains("GB"), "Expected GB, got: \(result)")
    }

    func testInt_UseDecimalTrue_HasDecimalPoint() {
        let result = (1500 * 1024).bytesToReadableForm(useDecimal: true)
        XCTAssertTrue(result.contains("."), "Expected decimal point, got: \(result)")
    }

    func testInt_UseDecimalFalse_NoDecimalPoint() {
        let result = (1500 * 1024).bytesToReadableForm(useDecimal: false)
        XCTAssertFalse(result.contains("."), "Expected no decimal point, got: \(result)")
    }

    func testInt_ExactlyOneKB() {
        let result = 1024.bytesToReadableForm(useDecimal: true)
        XCTAssertEqual(result, "1.0 KB")
    }

    func testInt_1023Bytes() {
        XCTAssertEqual(1023.bytesToReadableForm(), "1023 B")
    }

    func testInt_LargeSize() {
        let twoGB = 2 * 1024 * 1024 * 1024
        let result = twoGB.bytesToReadableForm()
        XCTAssertTrue(result.contains("GB"), "Expected GB, got: \(result)")
    }

    func testInt_HalfMB() {
        let halfMB = 512 * 1024
        let result = halfMB.bytesToReadableForm(useDecimal: true)
        XCTAssertTrue(result.contains("MB"), "Expected MB, got: \(result)")
    }

    func testInt_100MB_WithDecimal() {
        let hundredMB = 100 * 1024 * 1024
        let result = hundredMB.bytesToReadableForm(useDecimal: true)
        XCTAssertTrue(result.contains("MB") || result.contains("GB"), "Expected MB or GB, got: \(result)")
    }

    func testInt_100MB_WithoutDecimal() {
        let hundredMB = 100 * 1024 * 1024
        let result = hundredMB.bytesToReadableForm(useDecimal: false)
        XCTAssertFalse(result.contains("."), "Expected no decimal, got: \(result)")
    }

    // MARK: - Int64.bytesToReadableForm

    func testInt64_ZeroBytes() {
        XCTAssertEqual(Int64(0).bytesToReadableForm(), "0 B")
    }

    func testInt64_SmallBytes() {
        XCTAssertEqual(Int64(100).bytesToReadableForm(), "100 B")
    }

    func testInt64_OneKB() {
        let result = Int64(1024).bytesToReadableForm()
        XCTAssertTrue(result.contains("KB"), "Expected KB, got: \(result)")
    }

    func testInt64_OneMB() {
        let result = Int64(1024 * 1024).bytesToReadableForm()
        XCTAssertTrue(result.contains("MB"), "Expected MB, got: \(result)")
    }

    func testInt64_OneGB() {
        let result = Int64(1024 * 1024 * 1024).bytesToReadableForm()
        XCTAssertTrue(result.contains("GB"), "Expected GB, got: \(result)")
    }

    func testInt64_UseDecimalTrue() {
        let result = Int64(1500 * 1024).bytesToReadableForm(useDecimal: true)
        XCTAssertTrue(result.contains("."), "Expected decimal, got: \(result)")
    }

    func testInt64_UseDecimalFalse() {
        let result = Int64(1500 * 1024).bytesToReadableForm(useDecimal: false)
        XCTAssertFalse(result.contains("."), "Expected no decimal, got: \(result)")
    }

    func testInt64_OneTB() {
        let oneTB: Int64 = 1024 * 1024 * 1024 * 1024
        let result = oneTB.bytesToReadableForm()
        XCTAssertTrue(result.contains("TB"), "Expected TB, got: \(result)")
    }

    func testInt64_1023Bytes() {
        XCTAssertEqual(Int64(1023).bytesToReadableForm(), "1023 B")
    }
}
