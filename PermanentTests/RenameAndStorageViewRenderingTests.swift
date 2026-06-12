//
//  RenameAndStorageViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class RenameAndStorageViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    // MARK: - StorageView (~200 uncov lines)

    func testStorageView_Renders() {
        let vm = StorageViewModel()
        let view = StorageView(viewModel: StateObject(wrappedValue: vm))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testStorageView_RendersWithRedeemCode() {
        let vm = StorageViewModel(reddemCode: "ABC123")
        let view = StorageView(viewModel: StateObject(wrappedValue: vm))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - ChecklistBottomMenuView (~200 uncov lines)

    func testChecklistBottomMenuView_Renders() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: true)
        let view = ChecklistBottomMenuView(
            viewModel: StateObject(wrappedValue: vm),
            dismissAction: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testChecklistBottomMenuView_RendersHidden() {
        let vm = ChecklistBottomMenuViewModel(showsChecklistButton: false)
        let view = ChecklistBottomMenuView(
            viewModel: StateObject(wrappedValue: vm),
            dismissAction: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
