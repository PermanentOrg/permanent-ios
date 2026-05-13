//
//  SecurityMoreViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class SecurityMoreViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    private func makeContainerVM() -> TwoStepConfirmationContainerViewModel {
        TwoStepConfirmationContainerViewModel(
            refreshSecurityView: .constant(false),
            methodSelectedForDelete: .constant(nil),
            twoStepVerificationBottomBannerMessage: .constant(.none)
        )
    }

    // MARK: - TwoStepConfirmPasswordView

    func testTwoStepConfirmPasswordView_Renders() {
        let containerVM = makeContainerVM()
        let vm = TwoStepConfirmPasswordViewModel(containerViewModel: containerVM)
        let view = TwoStepConfirmPasswordView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - TwoStepChooseVerificationView

    func testTwoStepChooseVerificationView_RendersEmail() {
        let containerVM = makeContainerVM()
        let vm = TwoStepChooseVerificationViewModel(containerViewModel: containerVM, isEmailMethodSelected: true)
        let view = TwoStepChooseVerificationView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testTwoStepChooseVerificationView_RendersPhone() {
        let containerVM = makeContainerVM()
        let vm = TwoStepChooseVerificationViewModel(containerViewModel: containerVM, isEmailMethodSelected: false)
        let view = TwoStepChooseVerificationView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - CustomPasswordFieldView

    func testCustomPasswordFieldView_Renders() {
        let view = CustomPasswordFieldView(password: .constant(""), onSubmit: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - CustomEmailFieldView

    func testCustomEmailFieldView_Renders() {
        let view = CustomEmailFieldView(email: .constant(""), onSubmit: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - CustomPhoneFieldView

    func testCustomPhoneFieldView_Renders() {
        let view = CustomPhoneFieldView(
            phone: .constant(""),
            rawPhoneNumber: .constant(""),
            onSubmit: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - TwoStepBottomNotificationView

    func testTwoStepBottomNotificationView_Renders() {
        let view = TwoStepBottomNotificationView(
            message: .successCodeSend,
            isVisible: .constant(true)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - RoundButtonUsualBlue50View

    func testRoundButtonUsualBlue50View_Renders() {
        let view = RoundButtonUsualBlue50View(
            isDisabled: false,
            isLoading: false,
            text: "Submit",
            action: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - LoginSecurityView

    func testLoginSecurityView_Renders() {
        let vm = LoginSecurityViewModel()
        let view = LoginSecurityView(viewModel: StateObject(wrappedValue: vm))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
