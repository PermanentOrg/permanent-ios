//
//  ShareViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class ShareViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    private func makeShareItemVM() -> ShareItemViewModel {
        let file = FileModel.mockFile()
        return ShareItemViewModel(fileModel: file)
    }

    // MARK: - ShareEditInvitationView

    func testShareEditInvitationView_Renders() {
        let vm = makeShareItemVM()
        let view = ShareEditInvitationView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - ShareArchivesFromPastSharesView

    func testShareArchivesFromPastSharesView_Renders() {
        let vm = makeShareItemVM()
        let view = ShareArchivesFromPastSharesView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - GeneralAccessView

    func testGeneralAccessView_Renders() {
        let vm = makeShareItemVM()
        let view = GeneralAccessView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
