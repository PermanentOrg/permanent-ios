//
//  TwoStepVerificationTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class TwoStepVerificationTests: XCTestCase {

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

    // MARK: - TwoStepChooseVerificationViewModel Initial State

    func testChooseVerificationVM_InitialState_NilSelection() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseVerificationViewModel(containerViewModel: container, isEmailMethodSelected: nil)

        XCTAssertNil(vm.isEmailMethodSelected)
        XCTAssertTrue(vm.containerViewModel === container)
    }

    func testChooseVerificationVM_InitialState_EmailSelected() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseVerificationViewModel(containerViewModel: container, isEmailMethodSelected: true)

        XCTAssertEqual(vm.isEmailMethodSelected, true)
    }

    func testChooseVerificationVM_InitialState_SMSSelected() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseVerificationViewModel(containerViewModel: container, isEmailMethodSelected: false)

        XCTAssertEqual(vm.isEmailMethodSelected, false)
    }

    // MARK: - TwoStepChooseVerificationViewModel Properties

    func testChooseVerificationVM_CanToggleEmailMethod() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseVerificationViewModel(containerViewModel: container, isEmailMethodSelected: nil)

        vm.isEmailMethodSelected = true
        XCTAssertEqual(vm.isEmailMethodSelected, true)

        vm.isEmailMethodSelected = false
        XCTAssertEqual(vm.isEmailMethodSelected, false)

        vm.isEmailMethodSelected = nil
        XCTAssertNil(vm.isEmailMethodSelected)
    }

    // MARK: - TwoStepChooseVerificationView Rendering

    func testChooseVerificationView_RendersWithNilSelection() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseVerificationViewModel(containerViewModel: container, isEmailMethodSelected: nil)
        let view = TwoStepChooseVerificationView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testChooseVerificationView_RendersWithEmailSelected() {
        let container = makeTwoStepContainer()
        let vm = TwoStepChooseVerificationViewModel(containerViewModel: container, isEmailMethodSelected: true)
        let view = TwoStepChooseVerificationView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - TwoStepMethodType

    func testTwoStepMethodType_EmailName() {
        XCTAssertEqual(TwoStepMethodType.email.name(), "Email")
    }

    func testTwoStepMethodType_SMSName() {
        XCTAssertEqual(TwoStepMethodType.sms.name(), "Text message (SMS)")
    }

    // MARK: - TwoStepBottomNotificationView Rendering

    func testBottomNotification_RendersWithError() {
        var isVisible = true
        let binding = Binding(get: { isVisible }, set: { isVisible = $0 })
        let view = TwoStepBottomNotificationView(message: .invalidData, isVisible: binding)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testBottomNotification_RendersWithSuccess() {
        var isVisible = true
        let binding = Binding(get: { isVisible }, set: { isVisible = $0 })
        let view = TwoStepBottomNotificationView(message: .successResendCode, isVisible: binding)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testBottomNotification_RendersWithCodeExpired() {
        var isVisible = true
        let binding = Binding(get: { isVisible }, set: { isVisible = $0 })
        let view = TwoStepBottomNotificationView(message: .codeExpiredError, isVisible: binding)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testBottomNotification_RendersWithInvalidCredentials() {
        var isVisible = true
        let binding = Binding(get: { isVisible }, set: { isVisible = $0 })
        let view = TwoStepBottomNotificationView(message: .invalidCredentials, isVisible: binding)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testBottomNotification_RendersSuccessPasswordConfirmed() {
        var isVisible = true
        let binding = Binding(get: { isVisible }, set: { isVisible = $0 })
        let view = TwoStepBottomNotificationView(message: .successPasswordConfirmed, isVisible: binding)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - AuthBannerMessage Text

    func testAuthBannerMessage_AllCasesHaveText() {
        let cases: [AuthBannerMessage] = [
            .invalidData, .invalidCredentials, .invalidPassword,
            .incorrectEmail, .invalidPhoneNumber, .emptyPinCode,
            .invalidPinCode, .invalidEmail, .resentCodeError,
            .codeExpiredError, .successResendCode, .successCodeSend,
            .successPasswordConfirmed, .successEmailAdded, .successSmsAdded,
            .successEmailDeleted, .successSmsDeleted, .error, .generalError
        ]

        for message in cases {
            XCTAssertFalse(message.text.isEmpty, "Message \(message) should have non-empty text")
        }
    }

    func testAuthBannerMessage_NoneHasEmptyText() {
        XCTAssertTrue(AuthBannerMessage.none.text.isEmpty)
    }
}
