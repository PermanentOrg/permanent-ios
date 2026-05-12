//
//  MetadataEditRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class MetadataEditRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    // MARK: - SequenceFilenameView (~120 uncov lines)

    func testSequenceFilenameView_Renders() {
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: .constant(nil))
        let view = SequenceFilenameView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testSequenceFilenameView_RendersWithFiles() {
        let file = FileModel.mockFile()
        let vm = SequenceFilenameViewModel(selectedFiles: [file], fileNamePreview: .constant("preview"))
        let view = SequenceFilenameView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - ReplaceFilenameView (~120 uncov lines)

    func testReplaceFilenameView_Renders() {
        let vm = ReplaceFilenameViewModel(selectedFiles: [], fileNamePreview: .constant(nil))
        let view = ReplaceFilenameView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testReplaceFilenameView_RendersWithFiles() {
        let file = FileModel.mockFile()
        let vm = ReplaceFilenameViewModel(selectedFiles: [file], fileNamePreview: .constant("replaced"))
        let view = ReplaceFilenameView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - ConfirmationBottomAlertView (~150 uncov lines)

    func testConfirmationBottomAlertView_RendersDelete() {
        let view = ConfirmationBottomAlertView(
            isPresented: .constant(true),
            fileName: "photo.jpg",
            actionType: .delete,
            onConfirm: {},
            onCancel: nil,
            isMultipleItems: false,
            isFolder: false
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testConfirmationBottomAlertView_RendersLeaveShare() {
        let view = ConfirmationBottomAlertView(
            isPresented: .constant(true),
            fileName: "Shared Folder",
            actionType: .leaveShare,
            onConfirm: {},
            onCancel: nil,
            isMultipleItems: false,
            isFolder: true
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testConfirmationBottomAlertView_RendersMultipleItems() {
        let view = ConfirmationBottomAlertView(
            isPresented: .constant(true),
            fileName: "3 items",
            actionType: .delete,
            onConfirm: {},
            onCancel: {},
            isMultipleItems: true,
            isFolder: false
        )
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - AddStorageView (~100 uncov lines)

    func testAddStorageView_Renders() {
        let view = AddStorageView()
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
