//
//  RedeemCodeViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class RedeemCodeViewTests: XCTestCase {

    // MARK: - RedeemCodeView Rendering

    func testRedeemCodeView_RendersWithDefaultViewModel() {
        let vm = RedeemCodeViewModel()
        let keyboard = KeyboardResponder()
        let view = RedeemCodeView(viewModel: vm, keyboard: keyboard)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testRedeemCodeView_RendersWithDismissAction() {
        let vm = RedeemCodeViewModel()
        let keyboard = KeyboardResponder()
        var dismissed = false
        let view = RedeemCodeView(viewModel: vm, keyboard: keyboard, dismissAction: { _ in dismissed = true })
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
        XCTAssertFalse(dismissed)
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
