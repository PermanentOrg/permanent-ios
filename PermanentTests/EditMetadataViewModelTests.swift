//
//  EditMetadataViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

final class EditMetadataViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func mockFile(name: String = "TestFile.jpg") -> FileModel {
        var file = FileModel.mockFile()
        file.name = name
        return file
    }

    // MARK: - ReplaceFilenameViewModel

    func testReplace_InitialState() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = ReplaceFilenameViewModel(selectedFiles: [mockFile()], fileNamePreview: binding)

        XCTAssertEqual(vm.findText, "")
        XCTAssertEqual(vm.replaceText, "")
        XCTAssertEqual(vm.selectedFiles.count, 1)
    }

    func testReplace_GetSelectedFiles_ReplacesText() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = ReplaceFilenameViewModel(selectedFiles: [mockFile(name: "photo_001.jpg")], fileNamePreview: binding)

        vm.findText = "photo"
        vm.replaceText = "image"

        let result = vm.getSelectedFiles()
        XCTAssertEqual(result.first?.name, "image_001.jpg")
    }

    func testReplace_GetSelectedFiles_NoMatch() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = ReplaceFilenameViewModel(selectedFiles: [mockFile(name: "photo.jpg")], fileNamePreview: binding)

        vm.findText = "video"
        vm.replaceText = "image"

        let result = vm.getSelectedFiles()
        XCTAssertEqual(result.first?.name, "photo.jpg")
    }

    func testReplace_UpdateReplacePreview() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = ReplaceFilenameViewModel(selectedFiles: [mockFile(name: "photo.jpg")], fileNamePreview: binding)

        vm.findText = "photo"
        vm.replaceText = "picture"
        vm.updateReplacePreview()

        XCTAssertEqual(preview, "picture.jpg")
    }

    // MARK: - AppendFilenameViewModel

    func testAppend_InitialState() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = AppendFilenameViewModel(selectedFiles: [mockFile()], fileNamePreview: binding)

        XCTAssertEqual(vm.textToAppend, "")
        XCTAssertEqual(vm.selectedOption?.title, "Before name")
    }

    func testAppend_GetSelectedFiles_BeforeName() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = AppendFilenameViewModel(selectedFiles: [mockFile(name: "photo.jpg")], fileNamePreview: binding)

        vm.textToAppend = "2023_"
        vm.selectedOption = vm.whereOptions.first

        let result = vm.getSelectedFiles()
        XCTAssertEqual(result.first?.name, "2023_photo.jpg")
    }

    func testAppend_GetSelectedFiles_AfterName() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = AppendFilenameViewModel(selectedFiles: [mockFile(name: "photo.jpg")], fileNamePreview: binding)

        vm.textToAppend = "_edited"
        vm.selectedOption = vm.whereOptions.last

        let result = vm.getSelectedFiles()
        XCTAssertEqual(result.first?.name, "photo.jpg_edited")
    }

    func testAppend_WhereOptions() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = AppendFilenameViewModel(selectedFiles: [], fileNamePreview: binding)

        XCTAssertEqual(vm.whereOptions.count, 2)
        XCTAssertEqual(vm.whereOptions[0].title, "Before name")
        XCTAssertEqual(vm.whereOptions[1].title, "After Name")
    }

    // MARK: - SequenceFilenameViewModel

    func testSequence_InitialState() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [mockFile()], fileNamePreview: binding)

        XCTAssertEqual(vm.baseText, "")
        XCTAssertEqual(vm.startNumberText, "1")
        XCTAssertFalse(vm.isSelectingFormat)
        XCTAssertFalse(vm.isSelectingWhere)
        XCTAssertFalse(vm.isSelectingAdditionalData)
    }

    func testSequence_FormatOptions() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: binding)

        XCTAssertEqual(vm.formatOptions.count, 2)
        XCTAssertEqual(vm.formatOptions[0].title, "Date & Time")
        XCTAssertEqual(vm.formatOptions[1].title, "Count")
    }

    func testSequence_WhereOptions() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: binding)

        XCTAssertEqual(vm.whereOptions.count, 2)
        XCTAssertEqual(vm.whereOptions[0].title, "Before name")
        XCTAssertEqual(vm.whereOptions[1].title, "After name")
    }

    func testSequence_AdditionalOptions() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [], fileNamePreview: binding)

        XCTAssertEqual(vm.additionalOptions.count, 3)
        XCTAssertEqual(vm.additionalOptions[0].title, "Created")
        XCTAssertEqual(vm.additionalOptions[1].title, "Last modified")
        XCTAssertEqual(vm.additionalOptions[2].title, "Uploaded")
    }

    func testSequence_CalculateZeros_SingleFile() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [mockFile()], fileNamePreview: binding)
        vm.startNumberText = "1"

        let result = vm.calculateZeros(currentFile: 1)
        XCTAssertEqual(result, "")
    }

    func testSequence_CalculateZeros_TenFiles() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let files = (0..<10).map { i in mockFile(name: "file\(i).jpg") }
        let vm = SequenceFilenameViewModel(selectedFiles: files, fileNamePreview: binding)
        vm.startNumberText = "1"

        let zerosForFirst = vm.calculateZeros(currentFile: 1)
        XCTAssertEqual(zerosForFirst, "0")

        let zerosForTenth = vm.calculateZeros(currentFile: 10)
        XCTAssertEqual(zerosForTenth, "")
    }

    func testSequence_GetSelectedFiles_EmptyBaseText() {
        var preview: String? = nil
        let binding = Binding(get: { preview }, set: { preview = $0 })
        let vm = SequenceFilenameViewModel(selectedFiles: [mockFile()], fileNamePreview: binding)

        let result = vm.getSelectedFiles()
        XCTAssertTrue(result.isEmpty)
    }

    // MARK: - MetadataEditFileNamesViewModel

    func testMetadataEditFileNames_InitialState() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let file = mockFile(name: "photo.jpg")
        let vm = MetadataEditFileNamesViewModel(selectedFiles: [file], hasUpdates: binding)

        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showAlert)
        XCTAssertFalse(vm.changesWereSaved)
        XCTAssertEqual(vm.fileNamePreview, "photo.jpg")
        XCTAssertFalse(vm.showConfirmation)
        XCTAssertFalse(vm.changesConfirmed)
        XCTAssertNil(vm.currentViewModel)
    }

    func testMetadataEditFileNames_SelectedFilesCount() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let files = [mockFile(name: "a.jpg"), mockFile(name: "b.jpg")]
        let vm = MetadataEditFileNamesViewModel(selectedFiles: files, hasUpdates: binding)

        XCTAssertEqual(vm.selectedFiles.count, 2)
    }

    // MARK: - EditDateAndTimeViewModel

    func testEditDateTime_InitialState() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let vm = EditDateAndTimeViewModel(selectedFiles: [], hasUpdates: binding)

        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.changesConfirmed)
        XCTAssertFalse(vm.showConfirmation)
        XCTAssertFalse(vm.changesWereSaved)
        XCTAssertFalse(vm.showAlert)
    }

    func testEditDateTime_GetCommonDate_AllSame() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let file1 = mockFile()
        let file2 = mockFile()
        let vm = EditDateAndTimeViewModel(selectedFiles: [file1, file2], hasUpdates: binding)

        XCTAssertNotNil(vm.selectedDate)
    }

    func testEditDateTime_StartingDateIs1900() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let vm = EditDateAndTimeViewModel(selectedFiles: [], hasUpdates: binding)

        let components = Calendar.current.dateComponents([.year], from: vm.startingDate)
        XCTAssertEqual(components.year, 1900)
    }

    // MARK: - FilesMetadataViewModel

    func testFilesMetadata_InitialState() {
        let vm = FilesMetadataViewModel(files: [])

        // isLoading may be true because init calls refreshFiles()
        XCTAssertFalse(vm.showAlert)
        XCTAssertTrue(vm.allTags.isEmpty)
        XCTAssertFalse(vm.hasUpdates)
        XCTAssertEqual(vm.locationSectionText, "Locations")
    }

    func testFilesMetadata_GetAddressString() {
        let vm = FilesMetadataViewModel(files: [])

        let address = vm.getAddressString(["123", "Main St", "NYC", "US"])
        XCTAssertEqual(address, "123, Main St, NYC, US")
    }

    func testFilesMetadata_GetAddressString_WithNils() {
        let vm = FilesMetadataViewModel(files: [])

        let address = vm.getAddressString([nil, "Main St", nil, "US"])
        XCTAssertEqual(address, "Main St, US")
    }

    func testFilesMetadata_GetAddressString_AllNil() {
        let vm = FilesMetadataViewModel(files: [])

        let address = vm.getAddressString([nil, nil, nil, nil])
        XCTAssertEqual(address, "")
    }
}
