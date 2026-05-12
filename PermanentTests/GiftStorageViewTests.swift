//
//  GiftStorageViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class GiftStorageViewTests: XCTestCase {

    // MARK: - GiftStorageView Rendering Tests

    func testGiftStorageView_RendersWithNilAccount() {
        let view = GiftStorageView(viewModel: StateObject(wrappedValue: GiftStorageViewModel(accountData: nil)))
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
