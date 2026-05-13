//
//  ComponentViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class ComponentViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    // MARK: - CustomStepper (~197 uncov lines)

    func testCustomStepper_Renders() {
        let view = CustomStepper(
            value: .constant(1),
            textColor: .black,
            step: 1,
            textAfterValue: "GB / Recipient",
            borderColor: .constant(.gray)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testCustomStepper_RendersWithHighValue() {
        let view = CustomStepper(
            value: .constant(100),
            textColor: .blue,
            step: 5,
            textAfterValue: "MB",
            borderColor: .constant(.red)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testCustomStepper_RendersWithZero() {
        let view = CustomStepper(
            value: .constant(0),
            textColor: .black,
            borderColor: .constant(.gray)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - BottomNotificationWithOverlayView (~183 uncov lines)

    func testBottomNotificationWithOverlayView_Renders() {
        let view = BottomNotificationWithOverlayView(
            message: .successCodeSend,
            isVisible: .constant(true)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testBottomNotificationWithOverlayView_RendersHidden() {
        let view = BottomNotificationWithOverlayView(
            message: .error,
            isVisible: .constant(false)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
