//
//  TwoStepVerificationViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class TwoStepVerificationViewTests: XCTestCase {

    // MARK: - TwoStepVerificationViewModel Initial State

    func testViewModel_InitialState_NoMethods() {
        let vm = TwoStepVerificationViewModel(isTwoFactorEnabled: false, twoFactorMethods: [])

        XCTAssertFalse(vm.isTwoFactorEnabled)
        XCTAssertTrue(vm.twoFactorMethods.isEmpty)
        XCTAssertEqual(vm.phoneNumber, "")
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showError)
        XCTAssertEqual(vm.errorMessage, "")
        XCTAssertFalse(vm.checkVerificationMethod)
        XCTAssertFalse(vm.refreshAccountDataRequired)
        XCTAssertNil(vm.deleteMethodConfirmed)
        XCTAssertNil(vm.methodSelectedForDelete)
        XCTAssertNil(vm.changeMethodConfirmed)
        XCTAssertFalse(vm.changeAuthFlow)
        XCTAssertFalse(vm.showBottomBanner)
        XCTAssertEqual(vm.bottomBannerMessage, .none)
    }

    func testViewModel_InitialState_Enabled() {
        let vm = TwoStepVerificationViewModel(isTwoFactorEnabled: true, twoFactorMethods: [])

        XCTAssertTrue(vm.isTwoFactorEnabled)
    }

    // MARK: - Methods Sorting

    func testViewModel_SortsMethods_SMSFirst() {
        let emailMethod = TwoFactorMethod(methodId: "1", method: "email", value: "test@test.com")
        let smsMethod = TwoFactorMethod(methodId: "2", method: "sms", value: "+1234567890")

        let vm = TwoStepVerificationViewModel(
            isTwoFactorEnabled: true,
            twoFactorMethods: [emailMethod, smsMethod]
        )

        XCTAssertEqual(vm.twoFactorMethods.count, 2)
        XCTAssertEqual(vm.twoFactorMethods[0].type, .sms)
        XCTAssertEqual(vm.twoFactorMethods[1].type, .email)
    }

    func testViewModel_SortsMethods_AlreadySorted() {
        let smsMethod = TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890")
        let emailMethod = TwoFactorMethod(methodId: "2", method: "email", value: "test@test.com")

        let vm = TwoStepVerificationViewModel(
            isTwoFactorEnabled: true,
            twoFactorMethods: [smsMethod, emailMethod]
        )

        XCTAssertEqual(vm.twoFactorMethods[0].type, .sms)
    }

    func testViewModel_SingleSMSMethod() {
        let smsMethod = TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890")

        let vm = TwoStepVerificationViewModel(
            isTwoFactorEnabled: true,
            twoFactorMethods: [smsMethod]
        )

        XCTAssertEqual(vm.twoFactorMethods.count, 1)
        XCTAssertEqual(vm.twoFactorMethods[0].value, "+1234567890")
    }

    func testViewModel_SingleEmailMethod() {
        let emailMethod = TwoFactorMethod(methodId: "1", method: "email", value: "test@test.com")

        let vm = TwoStepVerificationViewModel(
            isTwoFactorEnabled: true,
            twoFactorMethods: [emailMethod]
        )

        XCTAssertEqual(vm.twoFactorMethods.count, 1)
        XCTAssertEqual(vm.twoFactorMethods[0].value, "test@test.com")
    }

    // MARK: - Property Changes

    func testViewModel_AllPropertiesCanBeSet() {
        let method = TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890")
        let vm = TwoStepVerificationViewModel(isTwoFactorEnabled: true, twoFactorMethods: [method])

        vm.phoneNumber = "+1234567890"
        vm.isLoading = true
        vm.showError = true
        vm.errorMessage = "Something went wrong"
        vm.checkVerificationMethod = true
        vm.changeAuthFlow = true
        vm.deleteMethodConfirmed = method
        vm.methodSelectedForDelete = method
        vm.changeMethodConfirmed = method

        XCTAssertEqual(vm.phoneNumber, "+1234567890")
        XCTAssertTrue(vm.isLoading)
        XCTAssertTrue(vm.showError)
        XCTAssertEqual(vm.errorMessage, "Something went wrong")
        XCTAssertTrue(vm.checkVerificationMethod)
        XCTAssertTrue(vm.changeAuthFlow)
        XCTAssertEqual(vm.deleteMethodConfirmed?.methodId, "1")
        XCTAssertEqual(vm.methodSelectedForDelete?.methodId, "1")
        XCTAssertNotNil(vm.changeMethodConfirmed)
    }

    func testViewModel_RefreshAccountData_ResetsFlag() {
        let vm = TwoStepVerificationViewModel(isTwoFactorEnabled: false, twoFactorMethods: [])

        vm.refreshAccountDataRequired = true
        XCTAssertTrue(vm.refreshAccountDataRequired)

        vm.refreshAccountData()
        XCTAssertFalse(vm.refreshAccountDataRequired)
    }

    // MARK: - Banner Display

    func testViewModel_DisplayBanner_ShowsBanner() {
        let vm = TwoStepVerificationViewModel(isTwoFactorEnabled: false, twoFactorMethods: [])

        XCTAssertFalse(vm.showBottomBanner)
        vm.displayBanner()
        XCTAssertTrue(vm.showBottomBanner)
    }

    func testViewModel_DisplayBannerWithAutoClose_ShowsBanner() {
        let vm = TwoStepVerificationViewModel(isTwoFactorEnabled: false, twoFactorMethods: [])

        vm.displayBannerWithAutoClose()
        XCTAssertTrue(vm.showBottomBanner)
    }

    func testViewModel_BottomBannerMessage() {
        let vm = TwoStepVerificationViewModel(isTwoFactorEnabled: false, twoFactorMethods: [])

        XCTAssertEqual(vm.bottomBannerMessage, .none)
    }

    // MARK: - TwoFactorMethod Struct

    func testTwoFactorMethod_SMSType() {
        let method = TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890")

        XCTAssertEqual(method.type, .sms)
        XCTAssertEqual(method.methodId, "1")
        XCTAssertEqual(method.value, "+1234567890")
        XCTAssertEqual(method.id, "1")
    }

    func testTwoFactorMethod_EmailType() {
        let method = TwoFactorMethod(methodId: "2", method: "email", value: "user@test.com")

        XCTAssertEqual(method.type, .email)
        XCTAssertEqual(method.value, "user@test.com")
    }

    func testTwoFactorMethod_Equatable() {
        let method1 = TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890")
        let method2 = TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890")
        let method3 = TwoFactorMethod(methodId: "2", method: "email", value: "test@test.com")

        XCTAssertEqual(method1, method2)
        XCTAssertNotEqual(method1, method3)
    }

    // MARK: - TwoStepVerificationView Rendering Tests

    func testTwoStepVerificationView_RendersDisabled() {
        let navState = NavigationStateManager()
        let view = TwoStepVerificationView(isTwoFactorEnabled: false, twoFactorMethods: [])
            .environmentObject(navState)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testTwoStepVerificationView_RendersEnabledWithSMS() {
        let navState = NavigationStateManager()
        let smsMethod = TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890")
        let view = TwoStepVerificationView(isTwoFactorEnabled: true, twoFactorMethods: [smsMethod])
            .environmentObject(navState)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testTwoStepVerificationView_RendersEnabledWithEmail() {
        let navState = NavigationStateManager()
        let emailMethod = TwoFactorMethod(methodId: "1", method: "email", value: "test@test.com")
        let view = TwoStepVerificationView(isTwoFactorEnabled: true, twoFactorMethods: [emailMethod])
            .environmentObject(navState)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testTwoStepVerificationView_RendersWithMultipleMethods() {
        let navState = NavigationStateManager()
        let smsMethod = TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890")
        let emailMethod = TwoFactorMethod(methodId: "2", method: "email", value: "test@test.com")
        let view = TwoStepVerificationView(isTwoFactorEnabled: true, twoFactorMethods: [emailMethod, smsMethod])
            .environmentObject(navState)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testTwoStepVerificationView_RendersWithEmptyMethodsEnabled() {
        let navState = NavigationStateManager()
        let view = TwoStepVerificationView(isTwoFactorEnabled: true, twoFactorMethods: [])
            .environmentObject(navState)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - Helpers

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }
}
