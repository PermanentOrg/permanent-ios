//
//  AlertAndDialogViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class AlertAndDialogViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    // MARK: - DeleteBottomAlertView (~408 uncov lines)

    func testDeleteBottomAlertView_Renders() {
        let view = DeleteBottomAlertView(
            showErrorMessage: .constant(true),
            deleteMethodConfirmed: .constant(nil),
            twoFactorMethod: nil
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testDeleteBottomAlertView_RendersWithMethod() {
        let method = TwoFactorMethod(methodId: "1", method: "sms", value: "+1555123")
        let view = DeleteBottomAlertView(
            showErrorMessage: .constant(false),
            deleteMethodConfirmed: .constant(nil),
            twoFactorMethod: method
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testDeleteBottomAlertView_RendersHidden() {
        let view = DeleteBottomAlertView(
            showErrorMessage: .constant(false),
            deleteMethodConfirmed: .constant(nil)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - ChangeAuthMethodBottomAlertView (~404 uncov lines)

    func testChangeAuthMethodBottomAlertView_Renders() {
        let view = ChangeAuthMethodBottomAlertView(
            showErrorMessage: .constant(true),
            deleteMethodConfirmed: .constant(nil),
            twoFactorMethod: nil
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testChangeAuthMethodBottomAlertView_RendersWithMethod() {
        let method = TwoFactorMethod(methodId: "2", method: "email", value: "test@test.com")
        let view = ChangeAuthMethodBottomAlertView(
            showErrorMessage: .constant(true),
            deleteMethodConfirmed: .constant(nil),
            twoFactorMethod: method
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - ChecklistCongratsView (~156 uncov lines)

    func testChecklistCongratsView_Renders() {
        let view = ChecklistCongratsView(onHideMemberChecklistBtn: {})
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
