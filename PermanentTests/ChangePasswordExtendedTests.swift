//
//  ChangePasswordExtendedTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class ChangePasswordExtendedTests: XCTestCase {

    // MARK: - ChangePasswordViewModel Initial State

    func testViewModel_InitialState() {
        let vm = ChangePasswordViewModel()

        XCTAssertFalse(vm.showBottomBanner)
        XCTAssertEqual(vm.bottomBannerMessage, .none)
        XCTAssertFalse(vm.showBanner)
        XCTAssertEqual(vm.currentPassword, "")
        XCTAssertEqual(vm.newPassword, "")
        XCTAssertEqual(vm.confirmPassword, "")
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - ChangePasswordViewModel Properties

    func testViewModel_AllPropertiesCanBeSet() {
        let vm = ChangePasswordViewModel()

        vm.currentPassword = "OldPassword123!"
        vm.newPassword = "NewSecurePass1!"
        vm.confirmPassword = "NewSecurePass1!"
        vm.isLoading = true
        vm.showBottomBanner = true
        vm.bottomBannerMessage = .invalidPassword

        XCTAssertEqual(vm.currentPassword, "OldPassword123!")
        XCTAssertEqual(vm.newPassword, "NewSecurePass1!")
        XCTAssertEqual(vm.confirmPassword, "NewSecurePass1!")
        XCTAssertTrue(vm.isLoading)
        XCTAssertTrue(vm.showBottomBanner)
        XCTAssertEqual(vm.bottomBannerMessage, .invalidPassword)
    }

    // MARK: - evaluatePasswordStrength

    func testPasswordStrength_EmptyPassword_Weak() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength(""), .weak)
    }

    func testPasswordStrength_ShortLettersOnly_Weak() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("abc"), .weak)
    }

    func testPasswordStrength_LettersAndDigits6Chars_Weak() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("abc123"), .weak)
    }

    func testPasswordStrength_LettersAndDigits8CharsWithSpecial_Medium() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("abcd12!@"), .medium)
    }

    func testPasswordStrength_MixedCase10CharsWithSpecial_Strong() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("Abcd1234!@"), .strong)
    }

    func testPasswordStrength_AllLowercase_Weak() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("abcdefgh"), .weak)
    }

    func testPasswordStrength_NoSpecialChars_Weak() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("Abcdef12"), .weak)
    }

    func testPasswordStrength_StrongWithSymbols() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("MyP@ssw0rd!"), .strong)
    }

    func testPasswordStrength_MediumWithSpecial() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("pass12!@"), .medium)
    }

    func testPasswordStrength_OnlyDigits_Weak() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("12345678"), .weak)
    }

    func testPasswordStrength_OnlySpecialChars_Weak() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("!@#$%^&*"), .weak)
    }

    func testPasswordStrength_SingleChar_Weak() {
        let vm = ChangePasswordViewModel()
        XCTAssertEqual(vm.evaluatePasswordStrength("a"), .weak)
    }

    // MARK: - PasswordStrength Enum

    func testPasswordStrength_RawValues() {
        XCTAssertEqual(PasswordStrength.weak.rawValue, "weak")
        XCTAssertEqual(PasswordStrength.medium.rawValue, "medium")
        XCTAssertEqual(PasswordStrength.strong.rawValue, "strong")
    }

    func testPasswordStrength_ColorsAreDistinct() {
        let weakColor = PasswordStrength.weak.color
        let mediumColor = PasswordStrength.medium.color
        let strongColor = PasswordStrength.strong.color
        XCTAssertNotEqual(weakColor, strongColor, "Weak and strong should have different colors")
        XCTAssertNotEqual(mediumColor, strongColor, "Medium and strong should have different colors")
    }
}
