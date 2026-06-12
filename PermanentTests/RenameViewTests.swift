//
//  RenameViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.03.2026.
//

import SwiftUI
import UIKit
import XCTest
@testable import Permanent

@MainActor
final class RenameViewTests: XCTestCase {

    func testRendersFolderRenameView() async {
        var dismissed = false
        let view = RenameView(
            currentName: "My Folder",
            isFolder: true,
            thumbnailURL: nil,
            onRename: { _ in },
            onDismiss: { dismissed = true }
        )

        let host = hostView(view)
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertFalse(dismissed)
    }

    func testRendersFileRenameView() async {
        let view = RenameView(
            currentName: "MyFile.pdf",
            isFolder: false,
            thumbnailURL: nil,
            onRename: { _ in },
            onDismiss: nil
        )

        let host = hostView(view)
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testRendersFileRenameViewWithThumbnailURL() async {
        let view = RenameView(
            currentName: "MyFile.pdf",
            isFolder: false,
            thumbnailURL: "https://example.com/thumb.png",
            onRename: { _ in },
            onDismiss: nil
        )

        let host = hostView(view)
        _ = host.view
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }
}
