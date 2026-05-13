//
//  InfoViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

final class InfoViewModelTests: XCTestCase {

    // MARK: - Init

    func testInit_UserDataFieldsNil() {
        let vm = InfoViewModel(accountId: 42)
        XCTAssertNil(vm.userData.fullName)
        XCTAssertNil(vm.userData.primaryEmail)
        XCTAssertNil(vm.userData.primaryPhone)
        XCTAssertNil(vm.userData.address)
        XCTAssertNil(vm.userData.address2)
        XCTAssertNil(vm.userData.city)
        XCTAssertNil(vm.userData.state)
        XCTAssertNil(vm.userData.zip)
        XCTAssertNil(vm.userData.country)
    }

    func testInit_DataIsNotModifiedFalse() {
        let vm = InfoViewModel(accountId: 1)
        XCTAssertFalse(vm.dataIsNotModified)
    }

    func testInit_AccountIdStored() {
        let vm = InfoViewModel(accountId: 99)
        XCTAssertEqual(vm.accountId, 99)
    }

    func testInit_NilAccountId() {
        let vm = InfoViewModel(accountId: nil)
        XCTAssertNil(vm.accountId)
    }

    // MARK: - format(with:phone:)

    func testFormat_USPhone_TenDigits() {
        let vm = InfoViewModel(accountId: nil)
        let result = vm.format(with: "(ZZZ) ZZZ-ZZZZ", phone: "5551234567")
        XCTAssertEqual(result, "(555) 123-4567")
    }

    func testFormat_USPhone_WithExistingFormatting() {
        let vm = InfoViewModel(accountId: nil)
        let result = vm.format(with: "(ZZZ) ZZZ-ZZZZ", phone: "(555) 123-4567")
        XCTAssertEqual(result, "(555) 123-4567")
    }

    func testFormat_EmptyPhone() {
        let vm = InfoViewModel(accountId: nil)
        let result = vm.format(with: "(ZZZ) ZZZ-ZZZZ", phone: "")
        XCTAssertEqual(result, "")
    }

    func testFormat_ShortPhone() {
        let vm = InfoViewModel(accountId: nil)
        let result = vm.format(with: "(ZZZ) ZZZ-ZZZZ", phone: "555")
        XCTAssertEqual(result, "(555")
    }

    func testFormat_PhoneWithLetters_StripsNonDigits() {
        let vm = InfoViewModel(accountId: nil)
        let result = vm.format(with: "ZZZ-ZZZ", phone: "12abc34")
        XCTAssertEqual(result, "123-4")
    }

    func testFormat_PhoneWithSpaces_StripsSpaces() {
        let vm = InfoViewModel(accountId: nil)
        let result = vm.format(with: "ZZZZ", phone: "1 2 3 4")
        XCTAssertEqual(result, "1234")
    }

    func testFormat_SimpleMask() {
        let vm = InfoViewModel(accountId: nil)
        let result = vm.format(with: "ZZ-ZZ", phone: "1234")
        XCTAssertEqual(result, "12-34")
    }

    func testFormat_LongerPhoneThanMask_Truncates() {
        let vm = InfoViewModel(accountId: nil)
        let result = vm.format(with: "ZZ", phone: "12345")
        XCTAssertEqual(result, "12")
    }

    func testFormat_InternationalPrefix() {
        let vm = InfoViewModel(accountId: nil)
        let result = vm.format(with: "+Z (ZZZ) ZZZ-ZZZZ", phone: "+15551234567")
        XCTAssertEqual(result, "+1 (555) 123-4567")
    }

    func testFormat_AllMaskCharsNoZ() {
        let vm = InfoViewModel(accountId: nil)
        let result = vm.format(with: "----", phone: "1234")
        XCTAssertEqual(result, "----")
    }

    // MARK: - getValuesFromTextFieldValue

    func testGetValues_SameData_SetsModifiedTrue() {
        let vm = InfoViewModel(accountId: nil)
        vm.userData = ("John", "john@test.com", "555", "123 St", nil, "NYC", "NY", "10001", "US")

        let received: UpdateUserData = ("John", "john@test.com", "555", "123 St", nil, "NYC", "NY", "10001", "US")
        vm.getValuesFromTextFieldValue(receivedData: received)
        XCTAssertTrue(vm.dataIsNotModified)
    }

    func testGetValues_DifferentName_SetsModifiedFalse() {
        let vm = InfoViewModel(accountId: nil)
        vm.userData = ("John", "john@test.com", nil, nil, nil, nil, nil, nil, nil)

        let received: UpdateUserData = ("Jane", "john@test.com", nil, nil, nil, nil, nil, nil, nil)
        vm.getValuesFromTextFieldValue(receivedData: received)
        XCTAssertFalse(vm.dataIsNotModified)
    }

    func testGetValues_DifferentEmail_SetsModifiedFalse() {
        let vm = InfoViewModel(accountId: nil)
        vm.userData = ("John", "old@test.com", nil, nil, nil, nil, nil, nil, nil)

        let received: UpdateUserData = ("John", "new@test.com", nil, nil, nil, nil, nil, nil, nil)
        vm.getValuesFromTextFieldValue(receivedData: received)
        XCTAssertFalse(vm.dataIsNotModified)
    }

    func testGetValues_ModifiedData_UpdatesUserData() {
        let vm = InfoViewModel(accountId: nil)
        vm.userData = ("Old", nil, nil, nil, nil, nil, nil, nil, nil)

        let received: UpdateUserData = ("New", nil, nil, nil, nil, nil, nil, nil, nil)
        vm.getValuesFromTextFieldValue(receivedData: received)
        XCTAssertEqual(vm.userData.fullName, "New")
    }

    func testGetValues_SameData_DoesNotUpdateUserData() {
        let vm = InfoViewModel(accountId: nil)
        vm.userData = ("Same", "same@test.com", nil, nil, nil, nil, nil, nil, nil)

        let received: UpdateUserData = ("Same", "same@test.com", nil, nil, nil, nil, nil, nil, nil)
        vm.getValuesFromTextFieldValue(receivedData: received)
        XCTAssertTrue(vm.dataIsNotModified)
    }

    func testGetValues_DifferentCity_SetsModifiedFalse() {
        let vm = InfoViewModel(accountId: nil)
        vm.userData = (nil, nil, nil, nil, nil, "NYC", nil, nil, nil)

        let received: UpdateUserData = (nil, nil, nil, nil, nil, "LA", nil, nil, nil)
        vm.getValuesFromTextFieldValue(receivedData: received)
        XCTAssertFalse(vm.dataIsNotModified)
    }

    func testGetValues_DifferentZip_SetsModifiedFalse() {
        let vm = InfoViewModel(accountId: nil)
        vm.userData = (nil, nil, nil, nil, nil, nil, nil, "10001", nil)

        let received: UpdateUserData = (nil, nil, nil, nil, nil, nil, nil, "90210", nil)
        vm.getValuesFromTextFieldValue(receivedData: received)
        XCTAssertFalse(vm.dataIsNotModified)
    }

    // MARK: - getUserData edge cases

    func testGetUserData_NilAccountId_ReturnsError() {
        let vm = InfoViewModel(accountId: nil)
        let expectation = expectation(description: "completion")

        vm.getUserData { status in
            if case .error = status {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - updateUserData edge cases

    func testUpdateUserData_NilAccountId_ReturnsError() {
        let vm = InfoViewModel(accountId: nil)
        let data: UpdateUserData = ("Name", "test@test.com", nil, nil, nil, nil, nil, nil, nil)
        let expectation = expectation(description: "completion")

        vm.updateUserData(data) { status in
            if case .error = status {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateUserData_NilFullName_ReturnsError() {
        let vm = InfoViewModel(accountId: 1)
        let data: UpdateUserData = (nil, "test@test.com", nil, nil, nil, nil, nil, nil, nil)
        let expectation = expectation(description: "completion")

        vm.updateUserData(data) { status in
            if case .error = status {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateUserData_EmptyFullName_ReturnsError() {
        let vm = InfoViewModel(accountId: 1)
        let data: UpdateUserData = ("", "test@test.com", nil, nil, nil, nil, nil, nil, nil)
        let expectation = expectation(description: "completion")

        vm.updateUserData(data) { status in
            if case .error = status {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateUserData_InvalidEmail_ReturnsError() {
        let vm = InfoViewModel(accountId: 1)
        let data: UpdateUserData = ("Name", "not-an-email", nil, nil, nil, nil, nil, nil, nil)
        let expectation = expectation(description: "completion")

        vm.updateUserData(data) { status in
            if case .error = status {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateUserData_NilEmail_ReturnsError() {
        let vm = InfoViewModel(accountId: 1)
        let data: UpdateUserData = ("Name", nil, nil, nil, nil, nil, nil, nil, nil)
        let expectation = expectation(description: "completion")

        vm.updateUserData(data) { status in
            if case .error = status {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateUserData_DataNotModified_ReturnsError() {
        let vm = InfoViewModel(accountId: 1)
        vm.dataIsNotModified = true
        let data: UpdateUserData = ("Name", "test@test.com", nil, nil, nil, nil, nil, nil, nil)
        let expectation = expectation(description: "completion")

        vm.updateUserData(data) { status in
            if case .error = status {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - GetUserDataStatus

    func testGetUserDataStatus_SuccessEquatable() {
        XCTAssertEqual(GetUserDataStatus.success(message: "ok"), GetUserDataStatus.success(message: "ok"))
    }

    func testGetUserDataStatus_ErrorEquatable() {
        XCTAssertEqual(GetUserDataStatus.error(message: "fail"), GetUserDataStatus.error(message: "fail"))
    }

    func testGetUserDataStatus_SuccessNotEqualError() {
        XCTAssertNotEqual(GetUserDataStatus.success(message: "a"), GetUserDataStatus.error(message: "a"))
    }

    // MARK: - UpdateUserDataStatus

    func testUpdateUserDataStatus_SuccessEquatable() {
        XCTAssertEqual(UpdateUserDataStatus.success(message: "ok"), UpdateUserDataStatus.success(message: "ok"))
    }

    func testUpdateUserDataStatus_ErrorEquatable() {
        XCTAssertEqual(UpdateUserDataStatus.error(message: "fail"), UpdateUserDataStatus.error(message: "fail"))
    }

    func testUpdateUserDataStatus_SuccessNotEqualError() {
        XCTAssertNotEqual(UpdateUserDataStatus.success(message: "a"), UpdateUserDataStatus.error(message: "a"))
    }

    // MARK: - AccountUpdateError

    func testAccountUpdateError_PhoneInvalid_RawValue() {
        XCTAssertEqual(AccountUpdateError.phoneInvalid.rawValue, "warning.validation.phone")
    }

    func testAccountUpdateError_NameFieldIsEmpty_RawValue() {
        XCTAssertEqual(AccountUpdateError.nameFieldIsEmpty.rawValue, "error.empty.name")
    }

    func testAccountUpdateError_DataIsNotModified_RawValue() {
        XCTAssertEqual(AccountUpdateError.dataIsNotModified.rawValue, "warning.same.data")
    }

    func testAccountUpdateError_EmailIsEmpty_RawValue() {
        XCTAssertEqual(AccountUpdateError.emailIsEmpty.rawValue, "warning.validation.empty")
    }

    func testAccountUpdateError_EmailIsNotValid_RawValue() {
        XCTAssertEqual(AccountUpdateError.emailIsNotValid.rawValue, "error.invalid.email")
    }

    func testAccountUpdateError_DescriptionsNotEmpty() {
        let allCases: [AccountUpdateError] = [.phoneInvalid, .nameFieldIsEmpty, .dataIsNotModified, .emailIsEmpty, .emailIsNotValid]
        for error in allCases {
            XCTAssertFalse(error.description.isEmpty, "\(error) should have a description")
        }
    }
}
