//
//  FilePreviewViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class FilePreviewViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeVM(permissions: [Permission] = [.read, .edit, .share]) -> FilePreviewViewModel {
        var file = FileModel.mockFile()
        file.permissions = permissions
        return FilePreviewViewModel(file: file)
    }

    // MARK: - Initialization

    func testInit_SetsNameFromFile() {
        let file = FileModel.mockFile()
        let vm = FilePreviewViewModel(file: file)
        XCTAssertEqual(vm.name, file.name)
    }

    func testInit_RecordVOIsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.recordVO)
    }

    func testInit_PublicURLIsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.publicURL)
    }

    func testInit_DownloaderIsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.downloader)
    }

    func testInit_DelegateIsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.delegate)
    }

    func testInit_TagsRepositoryCreated() {
        let vm = makeVM()
        XCTAssertNotNil(vm.tagsRepository)
    }

    // MARK: - isEditable

    func testIsEditable_WithEditPermission_ReturnsTrue() {
        let vm = makeVM(permissions: [.read, .edit])
        XCTAssertTrue(vm.isEditable)
    }

    func testIsEditable_WithoutEditPermission_ReturnsFalse() {
        let vm = makeVM(permissions: [.read, .share])
        XCTAssertFalse(vm.isEditable)
    }

    func testIsEditable_EmptyPermissions_ReturnsFalse() {
        let vm = makeVM(permissions: [])
        XCTAssertFalse(vm.isEditable)
    }

    func testIsEditable_AllPermissions_ReturnsTrue() {
        let vm = makeVM(permissions: [.read, .edit, .share, .create, .delete, .move])
        XCTAssertTrue(vm.isEditable)
    }

    // MARK: - fileVO()

    func testFileVO_NilRecordVO_ReturnsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.fileVO())
    }

    // MARK: - fileThumbnailURL()

    func testFileThumbnailURL_NilRecordVO_ReturnsNil() {
        let vm = makeVM()
        XCTAssertNil(vm.fileThumbnailURL())
    }

    // MARK: - fileName()

    func testFileName_NilRecordVO_ReturnsEmptyString() {
        let vm = makeVM()
        XCTAssertEqual(vm.fileName(), "")
    }

    // MARK: - getAddressString

    func testGetAddressString_AllValues() {
        let vm = makeVM()
        let result = vm.getAddressString(["123", "Main St", "NYC", "US"])
        XCTAssertEqual(result, "123, Main St, NYC, US")
    }

    func testGetAddressString_WithNils() {
        let vm = makeVM()
        let result = vm.getAddressString([nil, "Main St", nil, "US"])
        XCTAssertEqual(result, "Main St, US")
    }

    func testGetAddressString_AllNil_Editable() {
        let vm = makeVM(permissions: [.read, .edit])
        let result = vm.getAddressString([nil, nil, nil, nil])
        XCTAssertEqual(result, "Tap to set".localized())
    }

    func testGetAddressString_AllNil_NotEditable() {
        let vm = makeVM(permissions: [.read])
        let result = vm.getAddressString([nil, nil, nil, nil])
        XCTAssertEqual(result, "")
    }

    func testGetAddressString_AllNil_NotInMetadataScreen() {
        let vm = makeVM(permissions: [.read, .edit])
        let result = vm.getAddressString([nil, nil, nil, nil], false)
        XCTAssertEqual(result, "")
    }

    func testGetAddressString_SingleValue() {
        let vm = makeVM()
        let result = vm.getAddressString(["New York"])
        XCTAssertEqual(result, "New York")
    }

    func testGetAddressString_EmptyArray() {
        let vm = makeVM(permissions: [.read, .edit])
        let result = vm.getAddressString([])
        XCTAssertEqual(result, "Tap to set".localized())
    }

    func testGetAddressString_EmptyArray_NotEditable() {
        let vm = makeVM(permissions: [.read])
        let result = vm.getAddressString([])
        XCTAssertEqual(result, "")
    }

    func testGetAddressString_MixedNilAndValues() {
        let vm = makeVM()
        let result = vm.getAddressString([nil, "Street", nil, nil, "Country"])
        XCTAssertEqual(result, "Street, Country")
    }

    // MARK: - cancelDownload

    func testCancelDownload_SetsDownloaderToNil() {
        let vm = makeVM()
        vm.cancelDownload()
        XCTAssertNil(vm.downloader)
    }

    // MARK: - File property

    func testFile_IsStoredFromInit() {
        let file = FileModel.mockFile()
        let vm = FilePreviewViewModel(file: file)
        XCTAssertEqual(vm.file.name, file.name)
        XCTAssertEqual(vm.file.recordId, file.recordId)
        XCTAssertEqual(vm.file.folderLinkId, file.folderLinkId)
        XCTAssertEqual(vm.file.archiveNo, file.archiveNo)
    }

    // MARK: - Name mutability

    func testName_CanBeChanged() {
        let vm = makeVM()
        vm.name = "NewName.pdf"
        XCTAssertEqual(vm.name, "NewName.pdf")
    }

    // MARK: - PublicURL

    func testPublicURL_CanBeSet() {
        let vm = makeVM()
        vm.publicURL = URL(string: "https://example.com/file")
        XCTAssertNotNil(vm.publicURL)
        XCTAssertEqual(vm.publicURL?.absoluteString, "https://example.com/file")
    }
}
