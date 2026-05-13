//
//  RedeemCodeViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class RedeemCodeViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testInit_DefaultState() {
        let vm = RedeemCodeViewModel()

        XCTAssertFalse(vm.invalidDataInserted)
        XCTAssertTrue(vm.isConfirmButtonDisabled)
        XCTAssertEqual(vm.redeemCode, "")
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showAlert)
        XCTAssertEqual(vm.storageRedeemed, 0)
        XCTAssertFalse(vm.codeRedeemed)
    }

    func testInit_WithAccountData() {
        let accountData = AccountVOData.mock()
        let vm = RedeemCodeViewModel(accountData: accountData)
        XCTAssertEqual(vm.accountData?.accountID, accountData.accountID)
    }

    func testInit_WithRedeemCode() {
        let vm = RedeemCodeViewModel(redeemCode: "ABC123")
        XCTAssertEqual(vm.redeemCode, "ABC123")
        XCTAssertFalse(vm.isConfirmButtonDisabled)
    }

    func testInit_WithNilAccountData() {
        let vm = RedeemCodeViewModel(accountData: nil)
        XCTAssertNil(vm.accountData)
    }

    // MARK: - redeemCode didSet Validation

    func testRedeemCode_SetNonEmpty_EnablesConfirmButton() {
        let vm = RedeemCodeViewModel()
        vm.redeemCode = "TESTCODE"

        XCTAssertFalse(vm.isConfirmButtonDisabled)
        XCTAssertFalse(vm.invalidDataInserted)
    }

    func testRedeemCode_SetEmpty_FirstTime_DisablesButtonNoError() {
        let vm = RedeemCodeViewModel()
        vm.redeemCode = ""

        XCTAssertTrue(vm.isConfirmButtonDisabled)
        XCTAssertFalse(vm.invalidDataInserted)
    }

    func testRedeemCode_SetEmpty_AfterTyping_ShowsError() {
        let vm = RedeemCodeViewModel()
        vm.redeemCode = "SOMETHING"
        vm.redeemCode = ""

        XCTAssertTrue(vm.isConfirmButtonDisabled)
        XCTAssertTrue(vm.invalidDataInserted)
    }

    func testRedeemCode_TypeClearRetype_ResetsError() {
        let vm = RedeemCodeViewModel()
        vm.redeemCode = "ABC"
        vm.redeemCode = ""
        XCTAssertTrue(vm.invalidDataInserted)

        vm.redeemCode = "DEF"
        XCTAssertFalse(vm.invalidDataInserted)
        XCTAssertFalse(vm.isConfirmButtonDisabled)
    }

    func testRedeemCode_MultipleSets_KeepsButtonEnabled() {
        let vm = RedeemCodeViewModel()
        vm.redeemCode = "A"
        vm.redeemCode = "AB"
        vm.redeemCode = "ABC"

        XCTAssertFalse(vm.isConfirmButtonDisabled)
        XCTAssertFalse(vm.invalidDataInserted)
    }

    // MARK: - Loading state

    func testIsLoading_CanBeToggled() {
        let vm = RedeemCodeViewModel()
        XCTAssertFalse(vm.isLoading)

        vm.isLoading = true
        XCTAssertTrue(vm.isLoading)
    }

    // MARK: - Alert state

    func testShowAlert_CanBeToggled() {
        let vm = RedeemCodeViewModel()
        XCTAssertFalse(vm.showAlert)

        vm.showAlert = true
        XCTAssertTrue(vm.showAlert)
    }

    // MARK: - codeRedeemed state

    func testCodeRedeemed_CanBeSet() {
        let vm = RedeemCodeViewModel()
        vm.codeRedeemed = true
        XCTAssertTrue(vm.codeRedeemed)
    }

    // MARK: - storageRedeemed

    func testStorageRedeemed_CanBeSet() {
        let vm = RedeemCodeViewModel()
        vm.storageRedeemed = 500
        XCTAssertEqual(vm.storageRedeemed, 500)
    }

    // MARK: - firstTextFieldInput behavior

    func testFirstTextFieldInput_StaysTrueUntilNonEmptyInput() {
        let vm = RedeemCodeViewModel()
        XCTAssertTrue(vm.firstTextFieldInput)
        vm.redeemCode = ""
        XCTAssertTrue(vm.firstTextFieldInput)
        vm.redeemCode = "A"
        XCTAssertFalse(vm.firstTextFieldInput)
    }

    func testFirstTextFieldInput_OnceFlipped_StaysFalse() {
        let vm = RedeemCodeViewModel()
        vm.redeemCode = "X"
        XCTAssertFalse(vm.firstTextFieldInput)
        vm.redeemCode = ""
        XCTAssertFalse(vm.firstTextFieldInput)
        vm.redeemCode = "Y"
        XCTAssertFalse(vm.firstTextFieldInput)
    }

    // MARK: - Init with nil code

    func testInit_WithNilCode_EmptyString() {
        let vm = RedeemCodeViewModel(redeemCode: nil)
        XCTAssertEqual(vm.redeemCode, "")
        XCTAssertTrue(vm.isConfirmButtonDisabled)
    }

    // MARK: - Multiple state changes

    func testMultipleCodeChanges_StateConsistency() {
        let vm = RedeemCodeViewModel()
        vm.redeemCode = "A"
        XCTAssertFalse(vm.isConfirmButtonDisabled)
        XCTAssertFalse(vm.invalidDataInserted)

        vm.redeemCode = "AB"
        XCTAssertFalse(vm.isConfirmButtonDisabled)
        XCTAssertFalse(vm.invalidDataInserted)

        vm.redeemCode = ""
        XCTAssertTrue(vm.isConfirmButtonDisabled)
        XCTAssertTrue(vm.invalidDataInserted)

        vm.redeemCode = "NEW"
        XCTAssertFalse(vm.isConfirmButtonDisabled)
        XCTAssertFalse(vm.invalidDataInserted)
    }
}
