//
//  SearchFilesViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

final class SearchFilesViewModelTests: XCTestCase {

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

    func testCurrentFolderIsRoot_EmptyStack_True() {
        let vm = SearchFilesViewModel()
        XCTAssertTrue(vm.currentFolderIsRoot)
    }

    func testCurrentFolderIsRoot_WithStack_False() {
        let vm = SearchFilesViewModel()
        vm.navigationStack.append(makeFolderFile())
        XCTAssertFalse(vm.currentFolderIsRoot)
    }

    // MARK: - numberOfSections

    func testNumberOfSections_IsTwo() {
        let vm = SearchFilesViewModel()
        XCTAssertEqual(vm.numberOfSections, 2)
    }

    // MARK: - numberOfRowsInSection

    func testNumberOfRows_Section0_ReturnsOne() {
        let vm = SearchFilesViewModel()
        XCTAssertEqual(vm.numberOfRowsInSection(0), 1)
    }

    func testNumberOfRows_Section1_MatchesSyncedViewModels() {
        let vm = SearchFilesViewModel()
        vm.viewModels.append(makeRecordFile())
        vm.viewModels.append(makeRecordFile())
        XCTAssertEqual(vm.numberOfRowsInSection(1), 2)
    }

    func testNumberOfRows_Section1_Empty() {
        let vm = SearchFilesViewModel()
        XCTAssertEqual(vm.numberOfRowsInSection(1), 0)
    }

    func testNumberOfRows_InvalidSection_ReturnsZero() {
        let vm = SearchFilesViewModel()
        XCTAssertEqual(vm.numberOfRowsInSection(5), 0)
    }

    // MARK: - heightForSection

    func testHeightForSection_0_Returns40() {
        let vm = SearchFilesViewModel()
        XCTAssertEqual(vm.heightForSection(0), 40)
    }

    func testHeightForSection_1_Returns40() {
        let vm = SearchFilesViewModel()
        XCTAssertEqual(vm.heightForSection(1), 40)
    }

    func testHeightForSection_Invalid_ReturnsZero() {
        let vm = SearchFilesViewModel()
        XCTAssertEqual(vm.heightForSection(5), 0)
    }

    // MARK: - title(forSection:)

    func testTitle_Section0_NoSelectedTags_ReturnsTags() {
        let vm = SearchFilesViewModel()
        let title = vm.title(forSection: 0)
        XCTAssertFalse(title.isEmpty)
        XCTAssertFalse(title.contains("("))
    }

    func testTitle_Section1_Root_ReturnsResults() {
        let vm = SearchFilesViewModel()
        let title = vm.title(forSection: 1)
        XCTAssertFalse(title.isEmpty)
    }

    func testTitle_Section1_NonRoot_ReturnsSortTitle() {
        let vm = SearchFilesViewModel()
        vm.navigationStack.append(makeFolderFile())
        let title = vm.title(forSection: 1)
        XCTAssertEqual(title, vm.activeSortOption.title)
    }

    func testTitle_InvalidSection_Empty() {
        let vm = SearchFilesViewModel()
        let title = vm.title(forSection: 99)
        XCTAssertEqual(title, "")
    }

    // MARK: - shouldPerformAction

    func testShouldPerformAction_SyncedSection_Root_ReturnsFalse() {
        let vm = SearchFilesViewModel()
        XCTAssertFalse(vm.shouldPerformAction(forSection: FileListType.synced.rawValue))
    }

    func testShouldPerformAction_SyncedSection_NonRoot_ReturnsTrue() {
        let vm = SearchFilesViewModel()
        vm.navigationStack.append(makeFolderFile())
        XCTAssertTrue(vm.shouldPerformAction(forSection: FileListType.synced.rawValue))
    }

    func testShouldPerformAction_OtherSection_ReturnsFalse() {
        let vm = SearchFilesViewModel()
        XCTAssertFalse(vm.shouldPerformAction(forSection: 0))
    }

    // MARK: - hasCancelButton

    func testHasCancelButton_AnySection_ReturnsFalse() {
        let vm = SearchFilesViewModel()
        XCTAssertFalse(vm.hasCancelButton(forSection: 0))
        XCTAssertFalse(vm.hasCancelButton(forSection: 1))
        XCTAssertFalse(vm.hasCancelButton(forSection: 2))
    }

    // MARK: - shouldDisplayBackgroundView

    func testShouldDisplayBackgroundView_Empty_ReturnsTrue() {
        let vm = SearchFilesViewModel()
        XCTAssertTrue(vm.shouldDisplayBackgroundView)
    }

    func testShouldDisplayBackgroundView_HasViewModels_ReturnsFalse() {
        let vm = SearchFilesViewModel()
        vm.viewModels.append(makeRecordFile())
        XCTAssertFalse(vm.shouldDisplayBackgroundView)
    }

    // MARK: - fileForRowAt

    func testFileForRowAt_Section1_ReturnsCorrectFile() {
        let vm = SearchFilesViewModel()
        let file = makeRecordFile(name: "search_result.jpg")
        vm.viewModels.append(file)
        let indexPath = IndexPath(row: 0, section: 1)
        let result = vm.fileForRowAt(indexPath: indexPath)
        XCTAssertEqual(result.name, "search_result.jpg")
    }

    // MARK: - filteredTags

    func testFilteredTags_EmptyTagVOs_ReturnsEmpty() {
        let vm = SearchFilesViewModel()
        XCTAssertTrue(vm.filteredTags.isEmpty)
    }

    // MARK: - searchQuery

    func testSearchQuery_InitiallyNil() {
        let vm = SearchFilesViewModel()
        XCTAssertNil(vm.searchQuery)
    }

    // MARK: - searchTimer

    func testSearchTimer_InitiallyNil() {
        let vm = SearchFilesViewModel()
        XCTAssertNil(vm.searchTimer)
    }

    // MARK: - Init state

    func testInit_TagVOsEmpty() {
        let vm = SearchFilesViewModel()
        XCTAssertTrue(vm.tagVOs.isEmpty)
    }

    func testInit_SelectedTagVOsEmpty() {
        let vm = SearchFilesViewModel()
        XCTAssertTrue(vm.selectedTagVOs.isEmpty)
    }
}
