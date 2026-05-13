//
//  StringAndIntExtensionTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class StringAndIntExtensionTests: XCTestCase {

    // MARK: - String isNotEmpty

    func testIsNotEmpty() {
        XCTAssertTrue("hello".isNotEmpty)
        XCTAssertFalse("".isNotEmpty)
        XCTAssertTrue(" ".isNotEmpty)
    }

    // MARK: - String isValidEmail

    func testIsValidEmail_ValidAddresses() {
        XCTAssertTrue("user@example.com".isValidEmail)
        XCTAssertTrue("user@mail.example.com".isValidEmail)
        XCTAssertTrue("user+tag@example.com".isValidEmail)
        XCTAssertTrue("first.last@example.com".isValidEmail)
    }

    func testIsValidEmail_InvalidAddresses() {
        XCTAssertFalse("userexample.com".isValidEmail)
        XCTAssertFalse("user@".isValidEmail)
        XCTAssertFalse("".isValidEmail)
        XCTAssertFalse("user@example".isValidEmail)
        XCTAssertFalse("@example.com".isValidEmail)
    }

    // MARK: - String isPhoneNumber

    func testIsPhoneNumber_Valid() {
        XCTAssertTrue("5551234567".isPhoneNumber)
        XCTAssertTrue("123456".isPhoneNumber)
        XCTAssertTrue("1234567890123456".isPhoneNumber)
    }

    func testIsPhoneNumber_Invalid() {
        XCTAssertFalse("1234".isPhoneNumber)
        XCTAssertFalse("555abc1234".isPhoneNumber)
        XCTAssertFalse("".isPhoneNumber)
    }

    // MARK: - String isUSPhoneNumber

    func testIsUSPhoneNumber() {
        XCTAssertTrue("5551234567".isUSPhoneNumber)
        XCTAssertTrue("555-123-4567".isUSPhoneNumber)
        XCTAssertFalse("555123".isUSPhoneNumber)
    }

    // MARK: - String utilities

    func testPluralized() {
        XCTAssertEqual("file".pluralized(), "files")
    }

    func testParenthesized() {
        XCTAssertEqual("test".parenthesized(), "(test)")
    }

    // MARK: - Int bytesToReadableForm

    func testBytesToReadable_Zero() {
        XCTAssertEqual(0.bytesToReadableForm(useDecimal: false), "0 B")
    }

    func testBytesToReadable_Kilobytes() {
        XCTAssertEqual(1024.bytesToReadableForm(useDecimal: false), "1 KB")
    }

    func testBytesToReadable_Megabytes() {
        XCTAssertEqual((1024 * 1024).bytesToReadableForm(useDecimal: false), "1 MB")
    }

    func testBytesToReadable_Gigabytes() {
        XCTAssertEqual((1024 * 1024 * 1024).bytesToReadableForm(useDecimal: false), "1 GB")
    }

    func testBytesToReadable_Terabytes() {
        XCTAssertEqual((1024 * 1024 * 1024 * 1024).bytesToReadableForm(useDecimal: false), "1 TB")
    }

    func testBytesToReadable_WithDecimal_Gigabytes() {
        XCTAssertEqual((1024 * 1024 * 1024).bytesToReadableForm(useDecimal: true), "1.0 GB")
    }

    // MARK: - Int64 bytesToReadableForm

    func testInt64BytesToReadable() {
        XCTAssertEqual(Int64(0).bytesToReadableForm(useDecimal: false), "0 B")
        XCTAssertEqual(Int64(1024 * 1024 * 1024).bytesToReadableForm(useDecimal: false), "1 GB")
        XCTAssertEqual(Int64(1024 * 1024 * 1024 * 1024).bytesToReadableForm(useDecimal: false), "1 TB")
    }
}
