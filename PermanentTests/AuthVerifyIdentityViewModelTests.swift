//
//  AuthVerifyIdentityViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class AuthVerifyIdentityViewModelTests: XCTestCase {

    private func makeVM() -> AuthVerifyIdentityViewModel {
        let container = AuthenticatorContainerViewModel()
        return AuthVerifyIdentityViewModel(containerViewModel: container)
    }

    func testInit_DefaultState() {
        let vm = makeVM()
        XCTAssertEqual(vm.pinCode, "")
        XCTAssertFalse(vm.digitsDisabled)
        XCTAssertNotNil(vm.containerViewModel)
    }

    func testPinCode_SetAndClear() {
        let vm = makeVM()
        vm.pinCode = "1234"
        XCTAssertEqual(vm.pinCode, "1234")

        vm.pinCode = ""
        XCTAssertEqual(vm.pinCode, "")
    }

    func testDigitsDisabled_Toggle() {
        let vm = makeVM()
        vm.digitsDisabled = true
        XCTAssertTrue(vm.digitsDisabled)

        vm.digitsDisabled = false
        XCTAssertFalse(vm.digitsDisabled)
    }
}
