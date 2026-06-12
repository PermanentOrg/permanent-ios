//
//  GiftStorageViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class GiftStorageViewModelTests: XCTestCase {

    // MARK: - Initial State

    func testViewModel_InitialState_NilAccount() {
        let vm = GiftStorageViewModel(accountData: nil)

        XCTAssertEqual(vm.giftAmountValue, 0)
        XCTAssertNil(vm.amountText)
        XCTAssertEqual(vm.storageGifted, 0)
        XCTAssertFalse(vm.notEnoughStorageSpace)
        XCTAssertEqual(vm.spaceNeeded, 0)
        XCTAssertEqual(vm.spaceLeftAfterDonation, 0)
        XCTAssertTrue(vm.isSendButtonDisabled)
        XCTAssertFalse(vm.showConfirmation)
        XCTAssertFalse(vm.changesConfirmed)
        XCTAssertTrue(vm.emails.isEmpty)
        XCTAssertFalse(vm.sentGiftError)
        XCTAssertFalse(vm.sentGiftWasSuccessfull)
        XCTAssertFalse(vm.isLoading)
    }

    func testViewModel_InitialState_SpaceValuesZeroWithNilAccount() {
        let vm = GiftStorageViewModel(accountData: nil)

        XCTAssertEqual(vm.spaceTotal, 0)
        XCTAssertEqual(vm.spaceLeft, 0)
        XCTAssertEqual(vm.spaceUsed, 0)
    }

    // MARK: - updateGiftAmountText

    func testUpdateGiftAmount_NoEmailsNoAmount() {
        let vm = GiftStorageViewModel(accountData: nil)

        vm.giftAmountValue = 0
        vm.emails = []

        XCTAssertNil(vm.amountText)
        XCTAssertTrue(vm.isSendButtonDisabled)
    }

    func testUpdateGiftAmount_AmountButNoEmails() {
        let vm = GiftStorageViewModel(accountData: nil)

        vm.giftAmountValue = 5
        vm.emails = []

        XCTAssertNil(vm.amountText)
        XCTAssertTrue(vm.isSendButtonDisabled)
    }

    func testUpdateGiftAmount_EmailsButNoAmount() {
        let vm = GiftStorageViewModel(accountData: nil)

        vm.emails = ["test@test.com"]
        vm.giftAmountValue = 0

        XCTAssertNil(vm.amountText)
        XCTAssertTrue(vm.isSendButtonDisabled)
    }

    func testUpdateGiftAmount_InsufficientStorage() {
        let vm = GiftStorageViewModel(accountData: nil)
        vm.spaceLeft = 1_073_741_824

        vm.emails = ["test@test.com"]
        vm.giftAmountValue = 5

        XCTAssertTrue(vm.notEnoughStorageSpace)
        XCTAssertTrue(vm.isSendButtonDisabled)
        XCTAssertNotNil(vm.amountText)
    }

    func testUpdateGiftAmount_SufficientStorage() {
        let vm = GiftStorageViewModel(accountData: nil)
        vm.spaceLeft = 10_737_418_240

        vm.emails = ["test@test.com"]
        vm.giftAmountValue = 1

        XCTAssertFalse(vm.notEnoughStorageSpace)
        XCTAssertFalse(vm.isSendButtonDisabled)
        XCTAssertNotNil(vm.amountText)
    }

    func testUpdateGiftAmount_SpaceNeededCalculation() {
        let vm = GiftStorageViewModel(accountData: nil)
        vm.spaceLeft = 100_000_000_000

        vm.emails = ["a@test.com", "b@test.com"]
        vm.giftAmountValue = 2

        let expectedSpaceNeeded = 2 * 2 * 1024 * 1024 * 1024
        XCTAssertEqual(vm.spaceNeeded, expectedSpaceNeeded)
    }

    // MARK: - Properties

    func testViewModel_GiftBorderColorDefault() {
        let vm = GiftStorageViewModel(accountData: nil)
        XCTAssertNotNil(vm.giftBorderColor)
    }

    func testViewModel_NoteTextDefault() {
        let vm = GiftStorageViewModel(accountData: nil)
        XCTAssertEqual(vm.noteText, "")
    }

    func testViewModel_NoteTextCanBeSet() {
        let vm = GiftStorageViewModel(accountData: nil)
        vm.noteText = "Enjoy the storage!"
        XCTAssertEqual(vm.noteText, "Enjoy the storage!")
    }

    func testViewModel_ShowConfirmationCanBeToggled() {
        let vm = GiftStorageViewModel(accountData: nil)
        vm.showConfirmation = true
        XCTAssertTrue(vm.showConfirmation)
    }
}
