//
//  MetadataEditViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class MetadataEditViewTests: XCTestCase {

    // MARK: - FilesMetadataViewModel Initial State

    func testFilesMetadataViewModel_InitialState() {
        let file = FileModel.mockFile()
        let vm = FilesMetadataViewModel(files: [file])

        XCTAssertFalse(vm.showAlert)
        XCTAssertFalse(vm.hasUpdates)
        XCTAssertFalse(vm.descriptionWasSaved)
        XCTAssertEqual(vm.selectedFiles.count, 1)
    }

    func testFilesMetadataViewModel_MultipleFiles() {
        let file1 = FileModel.mockFile()
        let file2 = FileModel.mockFile()
        let vm = FilesMetadataViewModel(files: [file1, file2])

        XCTAssertEqual(vm.selectedFiles.count, 2)
    }

    func testFilesMetadataViewModel_EmptyFiles() {
        let vm = FilesMetadataViewModel(files: [])

        XCTAssertTrue(vm.selectedFiles.isEmpty)
        XCTAssertTrue(vm.allTags.isEmpty)
    }

    // MARK: - FilesMetadataViewModel Properties

    func testFilesMetadataViewModel_AllPropertiesCanBeSet() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])

        vm.showAlert = true
        vm.hasUpdates = true
        vm.isLoading = true
        vm.inputText = "Test description"

        XCTAssertTrue(vm.showAlert)
        XCTAssertTrue(vm.hasUpdates)
        XCTAssertTrue(vm.isLoading)
        XCTAssertEqual(vm.inputText, "Test description")
        XCTAssertEqual(vm.locationSectionText, "Locations")
        XCTAssertNil(vm.commonLocation)
    }

    // MARK: - FilesMetadataViewModel Tag Checking

    func testFilesMetadataViewModel_IsTagInAllFiles_ReturnsFalse_WhenNoTags() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])

        XCTAssertFalse(vm.isTagInAllFiles("nonexistent"))
    }

    func testFilesMetadataViewModel_AllTagsEmpty_WhenNoTagsOnFiles() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])

        XCTAssertTrue(vm.allTags.isEmpty)
    }

    // MARK: - FilesMetadataViewModel Address Helper

    func testFilesMetadataViewModel_GetAddressString_AllComponents() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])
        let address = vm.getAddressString(["123", "Main St", "Springfield", "US"])

        XCTAssertEqual(address, "123, Main St, Springfield, US")
    }

    func testFilesMetadataViewModel_GetAddressString_WithNils() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])
        let address = vm.getAddressString([nil, "Main St", nil, "US"])

        XCTAssertEqual(address, "Main St, US")
    }

    func testFilesMetadataViewModel_GetAddressString_AllNils() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])
        let address = vm.getAddressString([nil, nil, nil, nil])

        XCTAssertEqual(address, "")
    }

    func testFilesMetadataViewModel_GetAddressString_EmptyArray() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])
        let address = vm.getAddressString([])

        XCTAssertEqual(address, "")
    }

    // MARK: - FilesMetadataViewModel Date Helper

    func testFilesMetadataViewModel_GetCommonDate_ReturnsFormattedString() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])
        let dateString = vm.getCommonDate()

        XCTAssertFalse(dateString.isEmpty)
    }

    // MARK: - FilesMetadataViewModel Diff Flags

    func testFilesMetadataViewModel_HaveDiffDescription_FalseWithSingleFile() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])

        XCTAssertFalse(vm.haveDiffDescription)
    }

    func testFilesMetadataViewModel_HaveDiffDate_FalseWithSingleFile() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])

        XCTAssertFalse(vm.haveDiffDate)
    }

    func testFilesMetadataViewModel_HavePartialTags_FalseInitially() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])

        XCTAssertFalse(vm.havePartialTags)
    }

    // MARK: - MetadataEditFileNamesViewModel Tests

    func testMetadataEditFileNamesViewModel_InitialState() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let vm = MetadataEditFileNamesViewModel(selectedFiles: [FileModel.mockFile()], hasUpdates: binding)

        XCTAssertFalse(vm.isLoading)
        XCTAssertFalse(vm.showAlert)
        XCTAssertFalse(vm.changesWereSaved)
        XCTAssertFalse(vm.showConfirmation)
        XCTAssertFalse(vm.changesConfirmed)
        XCTAssertEqual(vm.selectedFiles.count, 1)
    }

    func testMetadataEditFileNamesViewModel_FileNamePreview() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let vm = MetadataEditFileNamesViewModel(selectedFiles: [FileModel.mockFile()], hasUpdates: binding)

        XCTAssertEqual(vm.fileNamePreview, "Test File.pdf")
    }

    func testMetadataEditFileNamesViewModel_AllPropertiesCanBeSet() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let vm = MetadataEditFileNamesViewModel(selectedFiles: [FileModel.mockFile()], hasUpdates: binding)

        vm.showConfirmation = true
        vm.isLoading = true

        XCTAssertTrue(vm.showConfirmation)
        XCTAssertTrue(vm.isLoading)
    }

    func testMetadataEditFileNamesViewModel_EmptyFiles() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let vm = MetadataEditFileNamesViewModel(selectedFiles: [], hasUpdates: binding)

        XCTAssertTrue(vm.selectedFiles.isEmpty)
        XCTAssertNil(vm.fileNamePreview)
        XCTAssertNil(vm.imagePreviewURL)
        XCTAssertNil(vm.fileSizePreview)
    }

    func testMetadataEditFileNamesViewModel_CurrentViewModelNilByDefault() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let vm = MetadataEditFileNamesViewModel(selectedFiles: [FileModel.mockFile()], hasUpdates: binding)

        XCTAssertNil(vm.currentViewModel)
    }

    // MARK: - MetadataEditView Rendering Tests

    func testMetadataEditView_RendersWithSingleFile() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])
        let view = MetadataEditView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testMetadataEditView_RendersWithMultipleFiles() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile(), FileModel.mockFile()])
        let view = MetadataEditView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testMetadataEditView_RendersWhileLoading() {
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])
        vm.isLoading = true
        let view = MetadataEditView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testMetadataEditView_RendersWithDismissAction() {
        var dismissed = false
        let vm = FilesMetadataViewModel(files: [FileModel.mockFile()])
        let view = MetadataEditView(viewModel: vm, dismissAction: { _ in dismissed = true })
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
        XCTAssertFalse(dismissed)
    }

    func testMetadataEditView_RendersWithEmptyFiles() {
        let vm = FilesMetadataViewModel(files: [])
        let view = MetadataEditView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    // MARK: - MetadataEditFileNamesView Rendering Tests

    func testMetadataEditFileNamesView_RendersWithSingleFile() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let vm = MetadataEditFileNamesViewModel(selectedFiles: [FileModel.mockFile()], hasUpdates: binding)
        let view = MetadataEditFileNamesView(viewModel: vm)
        let host = hostView(view)
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.1))

        XCTAssertNotNil(host.view)
    }

    func testMetadataEditFileNamesView_RendersWithEmptyFiles() {
        var hasUpdates = false
        let binding = Binding(get: { hasUpdates }, set: { hasUpdates = $0 })
        let vm = MetadataEditFileNamesViewModel(selectedFiles: [], hasUpdates: binding)
        let view = MetadataEditFileNamesView(viewModel: vm)
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
