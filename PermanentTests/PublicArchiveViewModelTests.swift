//
//  PublicArchiveViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

final class PublicArchiveViewModelTests: XCTestCase {

    private func makeRecordFile(name: String = "photo.jpg") -> FileModel {
        return FileModel(
            name: name,
            recordId: 100,
            folderLinkId: 1,
            archiveNbr: "0001-0000",
            type: "type.record.image",
            permissions: [.read]
        )
    }

    private func makeFolderFile(name: String = "My Folder") -> FileModel {
        return FileModel(
            name: name,
            recordId: 0,
            folderLinkId: 2,
            archiveNbr: "0001-0000",
            type: "type.folder.public",
            permissions: [.read]
        )
    }

    // MARK: - currentFolderIsRoot

    func testCurrentFolderIsRoot_EmptyStack_False() {
        let vm = PublicArchiveViewModel()
        XCTAssertFalse(vm.currentFolderIsRoot)
    }

    func testCurrentFolderIsRoot_OneItem_True() {
        let vm = PublicArchiveViewModel()
        vm.navigationStack.append(makeFolderFile())
        XCTAssertTrue(vm.currentFolderIsRoot)
    }

    func testCurrentFolderIsRoot_TwoItems_False() {
        let vm = PublicArchiveViewModel()
        vm.navigationStack.append(makeFolderFile())
        vm.navigationStack.append(makeFolderFile())
        XCTAssertFalse(vm.currentFolderIsRoot)
    }

    // MARK: - numberOfSections

    func testNumberOfSections_IsOne() {
        let vm = PublicArchiveViewModel()
        XCTAssertEqual(vm.numberOfSections, 1)
    }

    // MARK: - numberOfRowsInSection

    func testNumberOfRows_MatchesSyncedViewModels() {
        let vm = PublicArchiveViewModel()
        vm.viewModels.append(makeRecordFile())
        vm.viewModels.append(makeRecordFile())
        XCTAssertEqual(vm.numberOfRowsInSection(0), 2)
    }

    func testNumberOfRows_Empty_ReturnsZero() {
        let vm = PublicArchiveViewModel()
        XCTAssertEqual(vm.numberOfRowsInSection(0), 0)
    }

    // MARK: - heightForSection

    func testHeightForSection_ReturnsZero() {
        let vm = PublicArchiveViewModel()
        XCTAssertEqual(vm.heightForSection(0), 0)
        XCTAssertEqual(vm.heightForSection(1), 0)
    }

    // MARK: - fileForRowAt

    func testFileForRowAt_Section0_ReturnsCorrectFile() {
        let vm = PublicArchiveViewModel()
        let file = makeRecordFile(name: "public_file.jpg")
        vm.viewModels.append(file)
        let indexPath = IndexPath(row: 0, section: 0)
        let result = vm.fileForRowAt(indexPath: indexPath)
        XCTAssertEqual(result.name, "public_file.jpg")
    }

    // MARK: - currentArchive property

    func testCurrentArchive_InitiallyNil() {
        let vm = PublicArchiveViewModel()
        XCTAssertNil(vm.currentArchive)
    }

    func testCurrentArchive_CanBeSet() {
        let vm = PublicArchiveViewModel()
        let archive = ArchiveVOData.mock()
        vm.currentArchive = archive
        XCTAssertEqual(vm.currentArchive?.archiveID, 1)
    }

    // MARK: - publicURL

    func testPublicURL_NilCurrentArchive_ReturnsNil() {
        let vm = PublicArchiveViewModel()
        let file = makeRecordFile()
        XCTAssertNil(vm.publicURL(forFile: file))
    }

    func testPublicURL_NilCurrentFolder_ReturnsNil() {
        let vm = PublicArchiveViewModel()
        vm.currentArchive = ArchiveVOData.mock()
        let file = makeRecordFile()
        XCTAssertNil(vm.publicURL(forFile: file))
    }

    func testPublicURL_FolderFile_ContainsArchiveInURL() {
        let vm = PublicArchiveViewModel()
        vm.currentArchive = ArchiveVOData.mock()
        vm.navigationStack.append(makeFolderFile())
        let folder = makeFolderFile(name: "Public Folder")
        let url = vm.publicURL(forFile: folder)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("archive"))
    }

    func testPublicURL_RecordFile_ContainsRecordInURL() {
        let vm = PublicArchiveViewModel()
        vm.currentArchive = ArchiveVOData.mock()
        vm.navigationStack.append(makeFolderFile())
        let record = makeRecordFile()
        let url = vm.publicURL(forFile: record)
        XCTAssertNotNil(url)
        XCTAssertTrue(url!.absoluteString.contains("record"))
    }
}
