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

    // MARK: - Int64.readableFileSize (the same number as web: 1024 bytes to a KB, two decimals)

    func testReadableFileSize_WholeMegabytes_NoDecimal() {
        XCTAssertEqual(Int64(4 * 1024 * 1024).readableFileSize, "4 MB")
    }

    func testReadableFileSize_FractionalMegabytes_TwoDecimals() {
        XCTAssertEqual(Int64(5_882_511).readableFileSize, "5.61 MB")
    }

    func testReadableFileSize_DecimalMegabytes_AreLessThanTheNumberSays() {
        XCTAssertEqual(Int64(4_000_000).readableFileSize, "3.81 MB")
    }

    /// The reason this helper exists: always a period, never a comma, even though the
    /// device locale would otherwise render "5,61 MB".
    func testReadableFileSize_UsesPeriodNeverComma() {
        let result = Int64(5_882_511).readableFileSize
        XCTAssertTrue(result.contains("."), "Expected a period, got: \(result)")
        XCTAssertFalse(result.contains(","), "Expected no comma, got: \(result)")
    }

    func testReadableFileSize_Zero_ReturnsEmpty() {
        XCTAssertEqual(Int64(0).readableFileSize, "")
    }

    func testReadableFileSize_Negative_ReturnsEmpty() {
        XCTAssertEqual(Int64(-10).readableFileSize, "")
    }

    func testReadableFileSize_SubKilobyte_ShowsBytes() {
        XCTAssertEqual(Int64(500).readableFileSize, "500 bytes")
        XCTAssertEqual(Int64(1023).readableFileSize, "1023 bytes")
    }

    func testReadableFileSize_OneByte_IsSingular() {
        XCTAssertEqual(Int64(1).readableFileSize, "1 byte")
    }

    func testReadableFileSize_ExactlyOneKB() {
        XCTAssertEqual(Int64(1024).readableFileSize, "1 KB")
    }

    func testReadableFileSize_Gigabytes() {
        XCTAssertEqual(Int64(3_758_096_384).readableFileSize, "3.5 GB")
    }
}
