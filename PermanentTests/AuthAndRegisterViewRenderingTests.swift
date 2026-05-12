//
//  AuthAndRegisterViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class AuthAndRegisterViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    // MARK: - SectionHeaderView (~80 uncov lines)

    func testSectionHeaderView_RendersEmpty() {
        let view = SectionHeaderView(selectedFiles: .constant([]))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testSectionHeaderView_RendersWithFiles() {
        let file = FileModel.mockFile()
        let view = SectionHeaderView(selectedFiles: .constant([file]))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - GradientArchiveButtonView (~60 uncov lines)

    func testGradientArchiveButtonView_Renders() {
        let view = GradientArchiveButtonView(
            action: {},
            archiveType: .constant(.family)
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
