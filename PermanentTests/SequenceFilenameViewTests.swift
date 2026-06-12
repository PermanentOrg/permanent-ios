//
//  SequenceFilenameViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class SequenceFilenameViewTests: XCTestCase {

    // MARK: - SequenceFilenameViewModel Initial State

    func testViewModel_InitialState() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [FileModel.mockFile()], fileNamePreview: binding)

        XCTAssertFalse(vm.isSelectingFormat)
        XCTAssertFalse(vm.isSelectingWhere)
        XCTAssertFalse(vm.isSelectingAdditionalData)
        XCTAssertNil(vm.selectedFormatOptions)
        XCTAssertNil(vm.selectedWhereOptions)
        XCTAssertNil(vm.selectedAdditionalOption)
        XCTAssertEqual(vm.baseText, "")
        XCTAssertEqual(vm.startNumberText, "1")
        XCTAssertEqual(vm.selectedFiles.count, 1)
    }

    func testViewModel_InitialState_EmptyFiles() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: binding)

        XCTAssertTrue(vm.selectedFiles.isEmpty)
    }

    // MARK: - SequenceFilenameViewModel Options

    func testViewModel_FormatOptions() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: binding)

        XCTAssertEqual(vm.formatOptions.count, 2)
        XCTAssertEqual(vm.formatOptions[0].title, "Date & Time")
        XCTAssertEqual(vm.formatOptions[1].title, "Count")
    }

    func testViewModel_WhereOptions() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: binding)

        XCTAssertEqual(vm.whereOptions.count, 2)
        XCTAssertEqual(vm.whereOptions[0].title, "Before name")
        XCTAssertEqual(vm.whereOptions[1].title, "After name")
    }

    func testViewModel_AdditionalOptions() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: binding)

        XCTAssertEqual(vm.additionalOptions.count, 3)
        XCTAssertEqual(vm.additionalOptions[0].title, "Created")
        XCTAssertEqual(vm.additionalOptions[1].title, "Last modified")
        XCTAssertEqual(vm.additionalOptions[2].title, "Uploaded")
    }

    // MARK: - SequenceFilenameViewModel getSelectedFiles

    func testViewModel_GetSelectedFiles_EmptyBaseText_ReturnsEmpty() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [FileModel.mockFile()], fileNamePreview: binding)

        vm.baseText = ""
        let result = vm.getSelectedFiles()

        XCTAssertTrue(result.isEmpty)
    }

    func testViewModel_GetSelectedFiles_CountBeforeName() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [FileModel.mockFile()], fileNamePreview: binding)

        vm.baseText = "photo"
        vm.selectedFormatOptions = PullDownItem(title: "Count")
        vm.selectedWhereOptions = PullDownItem(title: "Before name")
        vm.startNumberText = "1"

        let result = vm.getSelectedFiles()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "1photo")
    }

    func testViewModel_GetSelectedFiles_CountAfterName() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [FileModel.mockFile()], fileNamePreview: binding)

        vm.baseText = "photo"
        vm.selectedFormatOptions = PullDownItem(title: "Count")
        vm.selectedWhereOptions = PullDownItem(title: "After name")
        vm.startNumberText = "1"

        let result = vm.getSelectedFiles()

        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result[0].name, "photo1")
    }

    func testViewModel_GetSelectedFiles_CountWithMultipleFiles() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let files = [FileModel.mockFile(), FileModel.mockFile(), FileModel.mockFile()]
        let vm = SequenceFilenameViewModel(selectedFiles: files, fileNamePreview: binding)

        vm.baseText = "img"
        vm.selectedFormatOptions = PullDownItem(title: "Count")
        vm.selectedWhereOptions = PullDownItem(title: "After name")
        vm.startNumberText = "1"

        let result = vm.getSelectedFiles()

        XCTAssertEqual(result.count, 3)
        XCTAssertEqual(result[0].name, "img1")
        XCTAssertEqual(result[1].name, "img2")
        XCTAssertEqual(result[2].name, "img3")
    }

    // MARK: - SequenceFilenameViewModel calculateZeros

    func testViewModel_CalculateZeros_SingleFile() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [FileModel.mockFile()], fileNamePreview: binding)

        vm.startNumberText = "1"
        let zeros = vm.calculateZeros(currentFile: 1)

        XCTAssertEqual(zeros, "")
    }

    func testViewModel_CalculateZeros_TenFiles() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let files = (0..<10).map { _ in FileModel.mockFile() }
        let vm = SequenceFilenameViewModel(selectedFiles: files, fileNamePreview: binding)

        vm.startNumberText = "1"
        let zerosFirst = vm.calculateZeros(currentFile: 1)
        let zerosLast = vm.calculateZeros(currentFile: 10)

        XCTAssertEqual(zerosFirst, "0")
        XCTAssertEqual(zerosLast, "")
    }

    // MARK: - SequenceFilenameViewModel updatePreview

    func testViewModel_UpdatePreview_EmptyBaseText() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [FileModel.mockFile()], fileNamePreview: binding)

        vm.baseText = ""
        vm.updatePreview()

        XCTAssertEqual(preview, "Test File.pdf")
    }

    func testViewModel_UpdatePreview_CountBeforeName() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [FileModel.mockFile()], fileNamePreview: binding)

        vm.baseText = "photo"
        vm.selectedFormatOptions = PullDownItem(title: "Count")
        vm.selectedWhereOptions = PullDownItem(title: "Before name")
        vm.startNumberText = "1"
        vm.updatePreview()

        XCTAssertEqual(preview, "1photo")
    }

    // MARK: - SequenceFilenameViewModel dateDetails

    func testViewModel_DateDetails_NilFile() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: binding)

        let date = vm.dateDetails(file: nil)
        XCTAssertNil(date)
    }

    // MARK: - SequenceFilenameView Rendering Tests

    func testSequenceFilenameView_RendersWithSingleFile() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [FileModel.mockFile()], fileNamePreview: binding)
        let view = SequenceFilenameView(viewModel: vm)
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
