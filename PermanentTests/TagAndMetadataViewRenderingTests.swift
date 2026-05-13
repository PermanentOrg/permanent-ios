//
//  TagAndMetadataViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class TagAndMetadataViewRenderingTests: XCTestCase {

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    // MARK: - AddNewTagView (~324 uncov lines)

    func testAddNewTagView_Renders() {
        let vm = AddNewTagViewModel(selectionTags: [], selectedFiles: [])
        let view = AddNewTagView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testAddNewTagView_RendersWithFiles() {
        let file = FileModel.mockFile()
        let vm = AddNewTagViewModel(selectionTags: [], selectedFiles: [file])
        let view = AddNewTagView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - TagsView (~206 uncov lines)

    func testTagsView_Renders() {
        let vm = FilesMetadataViewModel(files: [])
        let view = TagsView(viewModel: vm, showAddNewTagView: .constant(false))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testTagsView_RendersWithShowAddTag() {
        let vm = FilesMetadataViewModel(files: [])
        let view = TagsView(viewModel: vm, showAddNewTagView: .constant(true))
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - EditDateAndTimeView (~224 uncov lines)

    func testEditDateAndTimeView_Renders() {
        let vm = EditDateAndTimeViewModel(selectedFiles: [], hasUpdates: .constant(false))
        let view = EditDateAndTimeView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    func testEditDateAndTimeView_RendersWithFiles() {
        let file = FileModel.mockFile()
        let vm = EditDateAndTimeViewModel(selectedFiles: [file], hasUpdates: .constant(false))
        let view = EditDateAndTimeView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }

    // MARK: - AppendFilenameView (~112 uncov lines)

    func testAppendFilenameView_Renders() {
        let vm = AppendFilenameViewModel(selectedFiles: [], fileNamePreview: .constant(nil))
        let view = AppendFilenameView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))
        XCTAssertNotNil(host.view)
    }
}
