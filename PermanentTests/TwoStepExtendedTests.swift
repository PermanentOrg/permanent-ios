//
//  TwoStepExtendedTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class TwoStepExtendedTests: XCTestCase {

    // MARK: - TwoStepVerificationViewModel Initial State

    func testVerificationVM_InitialState_Disabled() {
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

    func testVerificationVM_InitialState_Enabled() {
        let vm = TwoStepVerificationViewModel(isTwoFactorEnabled: true, twoFactorMethods: [])

        XCTAssertTrue(vm.isTwoFactorEnabled)
    }

    func testVerificationVM_InitialState_WithMethods() {
        let method = TwoFactorMethod(methodId: "1", method: "email", value: "test@example.com")
        let vm = TwoStepVerificationViewModel(isTwoFactorEnabled: true, twoFactorMethods: [method])

        XCTAssertEqual(vm.twoFactorMethods.count, 1)
        XCTAssertEqual(vm.twoFactorMethods[0].value, "test@example.com")
    }

    // MARK: - TwoStepVerificationViewModel Properties

    func testVerificationVM_AllPropertiesCanBeSet() {
        let method = TwoFactorMethod(methodId: "1", method: "email", value: "test@test.com")
        let vm = TwoStepVerificationViewModel(isTwoFactorEnabled: true, twoFactorMethods: [method])

        vm.phoneNumber = "+1 555-1234"
        vm.isLoading = true
        vm.showError = true
        vm.errorMessage = "Something went wrong"
        vm.changeAuthFlow = true
        vm.showBottomBanner = true
        vm.bottomBannerMessage = .invalidData
        vm.deleteMethodConfirmed = method
        vm.methodSelectedForDelete = method
        vm.refreshAccountDataRequired = true

        XCTAssertEqual(vm.phoneNumber, "+1 555-1234")
        XCTAssertTrue(vm.isLoading)
        XCTAssertTrue(vm.showError)
        XCTAssertEqual(vm.errorMessage, "Something went wrong")
        XCTAssertTrue(vm.changeAuthFlow)
        XCTAssertTrue(vm.showBottomBanner)
        XCTAssertEqual(vm.bottomBannerMessage, .invalidData)
        XCTAssertEqual(vm.deleteMethodConfirmed?.methodId, "1")
        XCTAssertNotNil(vm.methodSelectedForDelete)
        XCTAssertTrue(vm.refreshAccountDataRequired)
    }

    // MARK: - TwoStepConfirmPasswordViewModel Initial State

    func testConfirmPasswordVM_InitialState() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        XCTAssertEqual(vm.textFieldPassword, "")
        XCTAssertFalse(vm.isLoading)
        XCTAssertTrue(vm.containerViewModel === container)
    }

    // MARK: - TwoStepConfirmPasswordViewModel Properties

    func testConfirmPasswordVM_AllPropertiesCanBeSet() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        vm.textFieldPassword = "myPassword123"
        vm.isLoading = true

        XCTAssertEqual(vm.textFieldPassword, "myPassword123")
        XCTAssertTrue(vm.isLoading)
    }

    // MARK: - TwoStepConfirmPasswordViewModel Validation

    func testConfirmPasswordVM_AreFieldsValid_BothValid() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        XCTAssertTrue(vm.areFieldsValid(emailField: "test@test.com", passwordField: "password123"))
    }

    func testConfirmPasswordVM_AreFieldsValid_NilEmail() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: nil, passwordField: "password123"))
    }

    func testConfirmPasswordVM_AreFieldsValid_NilPassword() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "test@test.com", passwordField: nil))
    }

    func testConfirmPasswordVM_AreFieldsValid_EmptyEmail() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "", passwordField: "password123"))
    }

    func testConfirmPasswordVM_AreFieldsValid_EmptyPassword() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "test@test.com", passwordField: ""))
    }

    func testConfirmPasswordVM_AreFieldsValid_BothEmpty() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "", passwordField: ""))
    }

    func testConfirmPasswordVM_AreFieldsValid_BothNil() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: nil, passwordField: nil))
    }

    func testConfirmPasswordVM_AreFieldsValid_InvalidEmail() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "notanemail", passwordField: "password123"))
    }

    func testConfirmPasswordVM_AreFieldsValid_ShortPassword() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)

        XCTAssertFalse(vm.areFieldsValid(emailField: "test@test.com", passwordField: "short"))
    }

    // MARK: - TwoStepVerificationView Rendering

    func testTwoStepVerificationView_RendersDisabled() {
        let view = TwoStepVerificationView(isTwoFactorEnabled: false, twoFactorMethods: [])
            .environmentObject(NavigationStateManager())
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testTwoStepVerificationView_RendersEnabled() {
        let method = TwoFactorMethod(methodId: "1", method: "email", value: "test@test.com")
        let view = TwoStepVerificationView(isTwoFactorEnabled: true, twoFactorMethods: [method])
            .environmentObject(NavigationStateManager())
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - TwoStepConfirmPasswordView Rendering

    func testTwoStepConfirmPasswordView_Renders() {
        let container = makeTwoStepContainer()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: container)
        let view = TwoStepConfirmPasswordView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - TwoFactorMethod Model

    func testTwoFactorMethod_EmailType() {
        let method = TwoFactorMethod(methodId: "abc", method: "email", value: "user@example.com")

        XCTAssertEqual(method.methodId, "abc")
        XCTAssertEqual(method.type, .email)
        XCTAssertEqual(method.value, "user@example.com")
        XCTAssertEqual(method.id, "abc")
    }

    func testTwoFactorMethod_SMSType() {
        let method = TwoFactorMethod(methodId: "def", method: "sms", value: "+15551234")

        XCTAssertEqual(method.type, .sms)
        XCTAssertEqual(method.value, "+15551234")
    }

    func testTwoFactorMethod_Equatable() {
        let method1 = TwoFactorMethod(methodId: "1", method: "email", value: "a@b.com")
        let method2 = TwoFactorMethod(methodId: "1", method: "email", value: "a@b.com")

        XCTAssertEqual(method1, method2)
    }

    // MARK: - BannerBottomMessage Enum

    func testBannerBottomMessage_CasesHaveDistinctIdentity() {
        XCTAssertNotEqual(BannerBottomMessage.none, BannerBottomMessage.invalidData)
    }

    // MARK: - Helpers

    private func makeTwoStepContainer() -> TwoStepConfirmationContainerViewModel {
        var refreshSecurityView = false
        var methodForDelete: TwoFactorMethod? = nil
        var bannerMessage: BannerBottomMessage = .none

        return TwoStepConfirmationContainerViewModel(
            refreshSecurityView: Binding(get: { refreshSecurityView }, set: { refreshSecurityView = $0 }),
            methodSelectedForDelete: Binding(get: { methodForDelete }, set: { methodForDelete = $0 }),
            twoStepVerificationBottomBannerMessage: Binding(get: { bannerMessage }, set: { bannerMessage = $0 })
        )
    }

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }
}
