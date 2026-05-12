//
//  FilenameViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class FilenameViewModelTests: XCTestCase {

    // MARK: - ReplaceFilenameViewModel

    func testReplace_InitState() {
        let vm = ReplaceFilenameViewModel(selectedFiles: [], fileNamePreview: .constant(nil))
        XCTAssertTrue(vm.findText.isEmpty)
        XCTAssertTrue(vm.replaceText.isEmpty)
    }

    func testReplace_GetSelectedFiles_EmptyList() {
        let vm = ReplaceFilenameViewModel(selectedFiles: [], fileNamePreview: .constant(nil))
        XCTAssertTrue(vm.getSelectedFiles().isEmpty)
    }

    func testReplace_GetSelectedFiles_PerformsReplacement() throws {
        let file = FileModel.mockFile()
        let vm = ReplaceFilenameViewModel(selectedFiles: [file], fileNamePreview: .constant(nil))
        vm.findText = "Test"
        vm.replaceText = "Replaced"
        let result = vm.getSelectedFiles()
        XCTAssertEqual(result.count, 1)
        let firstName = try XCTUnwrap(result.first?.name)
        XCTAssertTrue(firstName.contains("Replaced"), "Expected replaced name to contain 'Replaced', got '\(firstName)'")
        XCTAssertFalse(firstName.contains("Test"), "Original 'Test' should have been replaced in '\(firstName)'")
    }

    func testReplace_UpdatePreview_ChangesBinding() throws {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let file = FileModel.mockFile()
        let vm = ReplaceFilenameViewModel(selectedFiles: [file], fileNamePreview: binding)
        vm.findText = "Test"
        vm.replaceText = "Preview"
        vm.updateReplacePreview()
        let previewValue = try XCTUnwrap(preview)
        XCTAssertTrue(previewValue.contains("Preview"), "Expected preview to contain 'Preview', got '\(previewValue)'")
    }

    // MARK: - SequenceFilenameViewModel

    func testSequence_GetSelectedFiles_EmptyList() {
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: .constant(nil))
        XCTAssertTrue(vm.getSelectedFiles().isEmpty)
    }

    func testSequence_GetSelectedFiles_WithBaseText_ReturnsTransformedFiles() {
        let file = FileModel.mockFile()
        let vm = SequenceFilenameViewModel(selectedFiles: [file], fileNamePreview: .constant(nil))
        vm.baseText = "photo"
        let result = vm.getSelectedFiles()
        XCTAssertEqual(result.count, 1)
    }

    func testSequence_CalculateZeros_MultipleFiles_ReturnsPaddedString() {
        let files = (0..<15).map { _ in FileModel.mockFile() }
        let vm = SequenceFilenameViewModel(selectedFiles: files, fileNamePreview: .constant(nil))
        let result = vm.calculateZeros(currentFile: 1)
        XCTAssertTrue(result.contains("0"), "Should pad with zeros for multi-digit file counts")
    }

    func testSequence_DateDetails_NilFile_ReturnsNil() {
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: .constant(nil))
        XCTAssertNil(vm.dateDetails(file: nil))
    }

    // MARK: - AppendFilenameViewModel

    func testAppend_GetSelectedFiles_EmptyList() {
        let vm = AppendFilenameViewModel(selectedFiles: [], fileNamePreview: .constant(nil))
        XCTAssertTrue(vm.getSelectedFiles().isEmpty)
    }
}
