//
//  ShareMoreViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class ShareMoreViewRenderingTests: XCTestCase {

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

    // MARK: - ShareGrantArchiveAccessView

    func testShareGrantArchiveAccessView_Renders() {
        let vm = makeShareItemVM()
        let view = ShareGrantArchiveAccessView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - RoleSelectionView

    func testRoleSelectionView_Renders() {
        let vm = makeShareItemVM()
        let view = RoleSelectionView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - ShareInviteAndGrantAccessView

    func testShareInviteAndGrantAccessView_Renders() {
        let vm = makeShareItemVM()
        let view = ShareInviteAndGrantAccessView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - ShareCardView

    func testShareCardView_Renders() {
        let view = ShareCardView(
            icon: "person.fill",
            title: "Test Title",
            subtitle: "Test subtitle",
            action: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testShareCardView_RendersLoading() {
        let view = ShareCardView(
            icon: "link",
            title: "Loading",
            subtitle: "Please wait",
            action: {},
            isLoading: true
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - RevokeBottomAlertView

    func testRevokeBottomAlertView_Renders() {
        let view = RevokeBottomAlertView(
            isPresented: .constant(true),
            onRevoke: {}
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - SharePreviewHeaderView

    func testSharePreviewHeaderView_Renders() {
        let view = SharePreviewHeaderView(
            shareName: "Test Share",
            sharedByName: "John",
            archiveName: "My Archive",
            thumbnailURL: nil
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - SharePreviewGridView

    func testSharePreviewGridView_RendersEmpty() {
        let view = SharePreviewGridView(items: [], isBlurred: false)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testSharePreviewGridView_RendersBlurred() {
        let view = SharePreviewGridView(items: [], isBlurred: true)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
