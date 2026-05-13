//
//  SharedFilesViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

final class SharedFilesViewModelTests: XCTestCase {

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

    // MARK: - Notification Name

    func testDidSelectFilesNotifName() {
        XCTAssertEqual(SharedFilesViewModel.didSelectFilesNotifName.rawValue, "SharedFilesViewModel.didSelectFilesNotifName")
    }

    // MARK: - currentFolderIsRoot

    func testCurrentFolderIsRoot_EmptyStack_True() {
        let vm = SharedFilesViewModel()
        XCTAssertTrue(vm.currentFolderIsRoot)
    }

    func testCurrentFolderIsRoot_WithStack_False() {
        let vm = SharedFilesViewModel()
        vm.navigationStack.append(makeFolderFile())
        XCTAssertFalse(vm.currentFolderIsRoot)
    }

    // MARK: - shouldPerformAction

    func testShouldPerformAction_SyncedSection_RootFolder_ReturnsFalse() {
        let vm = SharedFilesViewModel()
        XCTAssertFalse(vm.shouldPerformAction(forSection: FileListType.synced.rawValue))
    }

    func testShouldPerformAction_SyncedSection_NonRoot_ReturnsTrue() {
        let vm = SharedFilesViewModel()
        vm.navigationStack.append(makeFolderFile())
        XCTAssertTrue(vm.shouldPerformAction(forSection: FileListType.synced.rawValue))
    }

    func testShouldPerformAction_DownloadingSection_ReturnsFalse() {
        let vm = SharedFilesViewModel()
        XCTAssertFalse(vm.shouldPerformAction(forSection: FileListType.downloading.rawValue))
    }

    func testShouldPerformAction_UploadingSection_ReturnsFalse() {
        let vm = SharedFilesViewModel()
        XCTAssertFalse(vm.shouldPerformAction(forSection: FileListType.uploading.rawValue))
    }

    // MARK: - title(forSection:)

    func testTitle_DownloadingSection_NotEmpty() {
        let vm = SharedFilesViewModel()
        let title = vm.title(forSection: FileListType.downloading.rawValue)
        XCTAssertFalse(title.isEmpty)
    }

    func testTitle_UploadingSection_NotEmpty() {
        let vm = SharedFilesViewModel()
        let title = vm.title(forSection: FileListType.uploading.rawValue)
        XCTAssertFalse(title.isEmpty)
    }

    func testTitle_SyncedSection_Root_Empty() {
        let vm = SharedFilesViewModel()
        let title = vm.title(forSection: FileListType.synced.rawValue)
        XCTAssertEqual(title, "")
    }

    func testTitle_SyncedSection_NonRoot_MatchesSortOption() {
        let vm = SharedFilesViewModel()
        vm.navigationStack.append(makeFolderFile())
        let title = vm.title(forSection: FileListType.synced.rawValue)
        XCTAssertEqual(title, vm.activeSortOption.title)
    }

    func testTitle_InvalidSection_Empty() {
        let vm = SharedFilesViewModel()
        let title = vm.title(forSection: 99)
        XCTAssertEqual(title, "")
    }

    // MARK: - shareListType

    func testShareListType_Default_SharedByMe() {
        let vm = SharedFilesViewModel()
        XCTAssertEqual(vm.shareListType, .sharedByMe)
    }

    func testShareListType_SetToSharedWithMe() {
        let vm = SharedFilesViewModel()
        vm.shareListType = .sharedWithMe
        XCTAssertEqual(vm.shareListType, .sharedWithMe)
    }

    func testShareListType_DidSet_ClearsNavigationStack() {
        let vm = SharedFilesViewModel()
        vm.navigationStack.append(makeFolderFile())
        vm.shareListType = .sharedWithMe
        XCTAssertTrue(vm.navigationStack.isEmpty)
    }

    func testShareListType_SetToByMe_UsesSharedByMeModels() {
        let vm = SharedFilesViewModel()
        let file = makeRecordFile(name: "byMe.jpg")
        vm.sharedByMeViewModels = [file]
        vm.sharedWithMeViewModels = []
        vm.shareListType = .sharedByMe
        XCTAssertEqual(vm.viewModels.count, 1)
        XCTAssertEqual(vm.viewModels.first?.name, "byMe.jpg")
    }

    func testShareListType_SetToWithMe_UsesSharedWithMeModels() {
        let vm = SharedFilesViewModel()
        let file = makeRecordFile(name: "withMe.jpg")
        vm.sharedByMeViewModels = []
        vm.sharedWithMeViewModels = [file]
        vm.shareListType = .sharedWithMe
        XCTAssertEqual(vm.viewModels.count, 1)
        XCTAssertEqual(vm.viewModels.first?.name, "withMe.jpg")
    }

    // MARK: - sharedByMeViewModels / sharedWithMeViewModels

    func testInit_SharedByMeViewModels_Empty() {
        let vm = SharedFilesViewModel()
        XCTAssertTrue(vm.sharedByMeViewModels.isEmpty)
    }

    func testInit_SharedWithMeViewModels_Empty() {
        let vm = SharedFilesViewModel()
        XCTAssertTrue(vm.sharedWithMeViewModels.isEmpty)
    }

    // MARK: - ShareListType enum

    func testShareListType_RawValues() {
        XCTAssertEqual(ShareListType.sharedByMe.rawValue, 0)
        XCTAssertEqual(ShareListType.sharedWithMe.rawValue, 1)
    }
}
