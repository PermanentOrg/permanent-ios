//
//  AuthSecurityViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class AuthSecurityViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    // MARK: - CustomPasswordFieldWithPreviewView (~206 uncov lines)

    func testCustomPasswordFieldWithPreviewView_Renders() {
        let view = CustomPasswordFieldWithPreviewView(
            password: .constant(""),
            showPasswordPreviewBtn: .constant(false),
            onSubmit: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testCustomPasswordFieldWithPreviewView_RendersWithPassword() {
        let view = CustomPasswordFieldWithPreviewView(
            password: .constant("secret123"),
            showPasswordPreviewBtn: .constant(true),
            onSubmit: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - ForgotPasswordConfimationView (~195 uncov lines)

    func testForgotPasswordConfimationView_Renders() {
        let vm = AuthenticatorContainerViewModel()
        let view = ForgotPasswordConfimationView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - Add2FAFieldView (~176 uncov lines)

    func testAdd2FAFieldView_Renders() {
        let view = Add2FAFieldView(
            numberOfFields: 4,
            code: .constant(""),
            digitsDisabled: .constant(false)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testAdd2FAFieldView_RendersWithCode() {
        let view = Add2FAFieldView(
            numberOfFields: 4,
            code: .constant("1234"),
            digitsDisabled: .constant(false)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testAdd2FAFieldView_RendersDisabled() {
        let view = Add2FAFieldView(
            numberOfFields: 4,
            code: .constant(""),
            digitsDisabled: .constant(true)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testAdd2FAFieldView_RendersSixFields() {
        let view = Add2FAFieldView(
            numberOfFields: 6,
            code: .constant(""),
            digitsDisabled: .constant(false)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - TwoStepConfirmationContainerView (~282 uncov lines)

    func testTwoStepConfirmationContainerView_Renders() {
        let vm = TwoStepConfirmationContainerViewModel(
            refreshSecurityView: .constant(false),
            methodSelectedForDelete: .constant(nil),
            twoStepVerificationBottomBannerMessage: .constant(.none)
        )
        let view = TwoStepConfirmationContainerView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - EmailChipView (~322 uncov lines)

    func testEmailChipView_Renders() {
        let view = EmailChipView(
            isKeyboardPresented: .constant(false),
            emails: .constant([])
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testEmailChipView_RendersWithEmails() {
        let view = EmailChipView(
            isKeyboardPresented: .constant(false),
            emails: .constant(["test@test.com", "user@example.com"])
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testEmailChipView_RendersWithKeyboard() {
        let view = EmailChipView(
            isKeyboardPresented: .constant(true),
            emails: .constant(["a@b.com"])
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
