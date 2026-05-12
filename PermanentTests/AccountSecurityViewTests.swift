//
//  AccountSecurityViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class AccountSecurityViewTests: XCTestCase {

    // MARK: - LoginSecurityViewModel Initial State

    func testLoginSecurityViewModel_InitialState() {
        let vm = LoginSecurityViewModel()

        XCTAssertFalse(vm.addStorageIsPresented)
        XCTAssertFalse(vm.redeemStorageIspresented)
        XCTAssertTrue(vm.twoFactorMethods.isEmpty)
    }

    func testLoginSecurityViewModel_AllPropertiesCanBeSet() {
        let vm = LoginSecurityViewModel()

        vm.addStorageIsPresented = true
        vm.redeemStorageIspresented = true
        vm.isTwoStepVerificationToggleOn = true
        vm.isSecurityToggleOn = true
        vm.twoFactorBadgeStatus = SecurityBadgeStatus(text: "ON", color: .green)
        vm.twoFactorMethods = [
            TwoFactorMethod(methodId: "1", method: "sms", value: "+1234567890"),
            TwoFactorMethod(methodId: "2", method: "email", value: "test@test.com")
        ]

        XCTAssertTrue(vm.addStorageIsPresented)
        XCTAssertTrue(vm.redeemStorageIspresented)
        XCTAssertTrue(vm.isTwoStepVerificationToggleOn)
        XCTAssertTrue(vm.isSecurityToggleOn)
        XCTAssertEqual(vm.twoFactorBadgeStatus?.text, "ON")
        XCTAssertEqual(vm.twoFactorBadgeStatus?.color, .green)
        XCTAssertEqual(vm.twoFactorMethods.count, 2)
    }

    func testLoginSecurityViewModel_GetAuthTypeText_ReturnsNonEmpty() {
        let vm = LoginSecurityViewModel()

        let authText = vm.getAuthTypeText()
        XCTAssertFalse(authText.isEmpty)
    }

    // MARK: - SecurityBadgeStatus Tests

    func testSecurityBadgeStatus_Equatable() {
        let status1 = SecurityBadgeStatus(text: "ON", color: .green)
        let status2 = SecurityBadgeStatus(text: "ON", color: .green)
        let status3 = SecurityBadgeStatus(text: "OFF", color: .red)

        XCTAssertEqual(status1, status2)
        XCTAssertNotEqual(status1, status3)
    }

    // MARK: - TwoStepConfirmationContainerViewModel Tests

    func testTwoStepConfirmationContainerViewModel_InitialState() {
        var refreshSecurityView = false
        var methodForDelete: TwoFactorMethod? = nil
        var bannerMessage: BannerBottomMessage = .none

        let vm = TwoStepConfirmationContainerViewModel(
            refreshSecurityView: Binding(get: { refreshSecurityView }, set: { refreshSecurityView = $0 }),
            methodSelectedForDelete: Binding(get: { methodForDelete }, set: { methodForDelete = $0 }),
            twoStepVerificationBottomBannerMessage: Binding(get: { bannerMessage }, set: { bannerMessage = $0 })
        )

        XCTAssertEqual(vm.phoneNumber, "")
        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showErrorBanner)
        XCTAssertEqual(vm.bannerErrorMessage, .none)
        XCTAssertFalse(vm.showAddVerificationMethod)
        XCTAssertFalse(vm.dismissContainer)
        XCTAssertFalse(vm.changingAuthMethodFlow)
    }

    func testTwoStepConfirmationContainerViewModel_SetContentType() {
        var refreshSecurityView = false
        var methodForDelete: TwoFactorMethod? = nil
        var bannerMessage: BannerBottomMessage = .none

        let vm = TwoStepConfirmationContainerViewModel(
            refreshSecurityView: Binding(get: { refreshSecurityView }, set: { refreshSecurityView = $0 }),
            methodSelectedForDelete: Binding(get: { methodForDelete }, set: { methodForDelete = $0 }),
            twoStepVerificationBottomBannerMessage: Binding(get: { bannerMessage }, set: { bannerMessage = $0 })
        )

        vm.setContentType(.choosePhoneNumber)
        XCTAssertEqual(vm.contentType, .choosePhoneNumber)

        vm.setContentType(.chooseEmail)
        XCTAssertEqual(vm.contentType, .chooseEmail)
    }

    func testTwoStepConfirmationContainerViewModel_DisplayBanner() {
        var refreshSecurityView = false
        var methodForDelete: TwoFactorMethod? = nil
        var bannerMessage: BannerBottomMessage = .none

        let vm = TwoStepConfirmationContainerViewModel(
            refreshSecurityView: Binding(get: { refreshSecurityView }, set: { refreshSecurityView = $0 }),
            methodSelectedForDelete: Binding(get: { methodForDelete }, set: { methodForDelete = $0 }),
            twoStepVerificationBottomBannerMessage: Binding(get: { bannerMessage }, set: { bannerMessage = $0 })
        )

        vm.displayBanner(bannerErrorMessage: .invalidPinCode)
        XCTAssertTrue(vm.showErrorBanner)
        XCTAssertEqual(vm.bannerErrorMessage, .invalidPinCode)
    }

    // MARK: - TwoStepConfirmationContentType Tests

    func testTwoStepConfirmationContentType_ScreenTitles() {
        XCTAssertEqual(TwoStepConfirmationContentType.confirmPassword.screenTitle(), "Confirm Password")
        XCTAssertEqual(TwoStepConfirmationContentType.chooseVerification.screenTitle(), "Choose Verification")
        XCTAssertEqual(TwoStepConfirmationContentType.register.screenTitle(), "Register")
        XCTAssertEqual(TwoStepConfirmationContentType.chooseEmail.screenTitle(), "Add email verification method")
        XCTAssertEqual(TwoStepConfirmationContentType.choosePhoneNumber.screenTitle(), "Add text verification method")
        XCTAssertEqual(TwoStepConfirmationContentType.none.screenTitle(), "")
    }

    // MARK: - TwoStepChoosePhoneViewModel Tests

    func testTwoStepChoosePhoneViewModel_InitialState() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChoosePhoneViewModel(containerViewModel: container)

        XCTAssertEqual(vm.formattedPhone, "")
        XCTAssertEqual(vm.rawPhone, "")
        XCTAssertFalse(vm.isLoadingPhoneValidation)
        XCTAssertFalse(vm.isLoadingCodeVerification)
        XCTAssertFalse(vm.phoneAlreadyConfirmed)
        XCTAssertEqual(vm.remainingTime, 0)
        XCTAssertTrue(vm.canResend)
        XCTAssertEqual(vm.sendCodeButtonTitle, "Send Code")
        XCTAssertEqual(vm.pinCode, "")
    }

    func testTwoStepChoosePhoneViewModel_PhoneCanBeSet() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChoosePhoneViewModel(containerViewModel: container)

        vm.formattedPhone = "+1 555-1234"
        vm.rawPhone = "5551234"

        XCTAssertEqual(vm.formattedPhone, "+1 555-1234")
        XCTAssertEqual(vm.rawPhone, "5551234")
    }

    func testTwoStepChoosePhoneViewModel_PinCodeCanBeSet() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChoosePhoneViewModel(containerViewModel: container)

        vm.pinCode = "123456"
        XCTAssertEqual(vm.pinCode, "123456")
    }

    func testTwoStepChoosePhoneViewModel_HoldsContainerReference() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChoosePhoneViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    // MARK: - TwoStepChooseEmailViewModel Tests

    func testTwoStepChooseEmailViewModel_InitialState() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseEmailViewModel(containerViewModel: container)

        XCTAssertEqual(vm.textFieldEmail, "")
        XCTAssertFalse(vm.isLoadingEmailValidation)
        XCTAssertFalse(vm.isLoadingCodeVerification)
        XCTAssertFalse(vm.emailAlreadyConfirmed)
        XCTAssertEqual(vm.remainingTime, 0)
        XCTAssertTrue(vm.canResend)
        XCTAssertEqual(vm.sendCodeButtonTitle, "Send Code")
        XCTAssertEqual(vm.pinCode, "")
    }

    func testTwoStepChooseEmailViewModel_EmailCanBeSet() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseEmailViewModel(containerViewModel: container)

        vm.textFieldEmail = "test@example.com"
        XCTAssertEqual(vm.textFieldEmail, "test@example.com")
    }

    func testTwoStepChooseEmailViewModel_PinCodeCanBeSet() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseEmailViewModel(containerViewModel: container)

        vm.pinCode = "654321"
        XCTAssertEqual(vm.pinCode, "654321")
    }

    func testTwoStepChooseEmailViewModel_HoldsContainerReference() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseEmailViewModel(containerViewModel: container)

        XCTAssertTrue(vm.containerViewModel === container)
    }

    // MARK: - LoginSecurityView Rendering Tests

    func testLoginSecurityView_RendersWithoutCrash() {
        let view = LoginSecurityView(viewModel: StateObject(wrappedValue: LoginSecurityViewModel()))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - TwoStepChoosePhoneView Rendering Tests

    func testTwoStepChoosePhoneView_RendersWithoutCrash() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChoosePhoneViewModel(containerViewModel: container)
        let view = TwoStepChoosePhoneView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testTwoStepChoosePhoneView_RendersWithPhoneSet() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChoosePhoneViewModel(containerViewModel: container)
        vm.formattedPhone = "+1 555-1234"
        let view = TwoStepChoosePhoneView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - TwoStepChooseEmailView Rendering Tests

    func testTwoStepChooseEmailView_RendersWithoutCrash() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseEmailViewModel(containerViewModel: container)
        let view = TwoStepChooseEmailView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testTwoStepChooseEmailView_RendersWithEmailSet() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseEmailViewModel(containerViewModel: container)
        vm.textFieldEmail = "test@example.com"
        let view = TwoStepChooseEmailView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
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
