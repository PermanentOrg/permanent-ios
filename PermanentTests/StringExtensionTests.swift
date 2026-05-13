//
//  StringExtensionTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class StringExtensionTests: XCTestCase {

    // MARK: - isNotEmpty

    func testIsNotEmpty_NonEmptyString_ReturnsTrue() {
        XCTAssertTrue("hello".isNotEmpty)
    }

    func testIsNotEmpty_EmptyString_ReturnsFalse() {
        XCTAssertFalse("".isNotEmpty)
    }

    func testIsNotEmpty_SingleChar_ReturnsTrue() {
        XCTAssertTrue("a".isNotEmpty)
    }

    func testIsNotEmpty_Whitespace_ReturnsTrue() {
        XCTAssertTrue(" ".isNotEmpty)
    }

    // MARK: - dateOnly

    func testDateOnly_WithTimeComponent_ReturnDatePart() {
        XCTAssertEqual("2026-05-11T14:30:00".dateOnly, "2026-05-11")
    }

    func testDateOnly_WithSpace_ReturnDatePart() {
        XCTAssertEqual("2026-05-11 14:30:00".dateOnly, "2026-05-11")
    }

    func testDateOnly_DateOnly_ReturnsSame() {
        XCTAssertEqual("2026-05-11".dateOnly, "2026-05-11")
    }

    func testDateOnly_EmptyString_ReturnsEmpty() {
        XCTAssertEqual("".dateOnly, "")
    }

    func testDateOnly_NoSeparator_ReturnsFull() {
        XCTAssertEqual("20260511".dateOnly, "20260511")
    }

    // MARK: - pluralized

    func testPluralized_AddsS() {
        XCTAssertEqual("file".pluralized(), "files")
    }

    func testPluralized_EmptyString() {
        XCTAssertEqual("".pluralized(), "s")
    }

    func testPluralized_AlreadyPlural() {
        XCTAssertEqual("items".pluralized(), "itemss")
    }

    // MARK: - parenthesized

    func testParenthesized_WrapsInParens() {
        XCTAssertEqual("3".parenthesized(), "(3)")
    }

    func testParenthesized_EmptyString() {
        XCTAssertEqual("".parenthesized(), "()")
    }

    func testParenthesized_LongString() {
        XCTAssertEqual("hello world".parenthesized(), "(hello world)")
    }

    // MARK: - isValidEmail

    func testIsValidEmail_ValidEmail() {
        XCTAssertTrue("user@example.com".isValidEmail)
    }

    func testIsValidEmail_ValidWithPlus() {
        XCTAssertTrue("user+tag@example.com".isValidEmail)
    }

    func testIsValidEmail_ValidWithDots() {
        XCTAssertTrue("first.last@example.com".isValidEmail)
    }

    func testIsValidEmail_ValidWithSubdomain() {
        XCTAssertTrue("user@mail.example.com".isValidEmail)
    }

    func testIsValidEmail_InvalidNoAt() {
        XCTAssertFalse("userexample.com".isValidEmail)
    }

    func testIsValidEmail_InvalidNoDomain() {
        XCTAssertFalse("user@".isValidEmail)
    }

    func testIsValidEmail_InvalidNoUser() {
        XCTAssertFalse("@example.com".isValidEmail)
    }

    func testIsValidEmail_InvalidEmpty() {
        XCTAssertFalse("".isValidEmail)
    }

    func testIsValidEmail_InvalidSpaces() {
        XCTAssertFalse("user @example.com".isValidEmail)
    }

    func testIsValidEmail_InvalidDoubleDot() {
        XCTAssertFalse("user@example..com".isValidEmail)
    }

    func testIsValidEmail_ValidUnderscore() {
        XCTAssertTrue("user_name@example.com".isValidEmail)
    }

    func testIsValidEmail_ValidHyphenDomain() {
        XCTAssertTrue("user@my-domain.com".isValidEmail)
    }

    func testIsValidEmail_ValidNumbers() {
        XCTAssertTrue("user123@example456.com".isValidEmail)
    }

    // MARK: - isPhoneNumber

    func testIsPhoneNumber_ValidSimple() {
        XCTAssertTrue("1234567890".isPhoneNumber)
    }

    func testIsPhoneNumber_ValidWithPlus() {
        XCTAssertTrue("+1234567890".isPhoneNumber)
    }

    func testIsPhoneNumber_TooShort() {
        XCTAssertFalse("1234".isPhoneNumber)
    }

    func testIsPhoneNumber_EmptyString() {
        XCTAssertFalse("".isPhoneNumber)
    }

    func testIsPhoneNumber_WithLetters() {
        XCTAssertFalse("123abc4567".isPhoneNumber)
    }

    func testIsPhoneNumber_WithDashes() {
        XCTAssertFalse("123-456-7890".isPhoneNumber)
    }

    func testIsPhoneNumber_FiveDigits() {
        XCTAssertFalse("12345".isPhoneNumber)
    }

    func testIsPhoneNumber_SixteenDigits() {
        XCTAssertTrue("1234567890123456".isPhoneNumber)
    }

    // MARK: - isUSPhoneNumber

    func testIsUSPhoneNumber_TenDigits() {
        XCTAssertTrue("5551234567".isUSPhoneNumber)
    }

    func testIsUSPhoneNumber_WithParensAndDash() {
        XCTAssertTrue("(555)123-4567".isUSPhoneNumber)
    }

    func testIsUSPhoneNumber_WithDashes() {
        XCTAssertTrue("555-123-4567".isUSPhoneNumber)
    }

    func testIsUSPhoneNumber_WithDots() {
        XCTAssertTrue("555.123.4567".isUSPhoneNumber)
    }

    func testIsUSPhoneNumber_WithSpaces() {
        XCTAssertTrue("555 123 4567".isUSPhoneNumber)
    }

    func testIsUSPhoneNumber_TooShort() {
        XCTAssertFalse("55512345".isUSPhoneNumber)
    }

    func testIsUSPhoneNumber_Empty() {
        XCTAssertFalse("".isUSPhoneNumber)
    }
}
