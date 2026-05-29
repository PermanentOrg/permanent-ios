//
//  FilesViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

final class FilesViewModelTests: XCTestCase {

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

    // MARK: - Initial State

    func testInit_ViewModelsEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.viewModels.isEmpty)
    }

    func testInit_NavigationStackEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.navigationStack.isEmpty)
    }

    func testInit_UploadQueueEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.uploadQueue.isEmpty)
    }

    func testInit_DownloadQueueEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.downloadQueue.isEmpty)
    }

    func testInit_UploadInProgressFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.uploadInProgress)
    }

    func testInit_DownloadInProgressFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.downloadInProgress)
    }

    func testInit_FileActionIsNone() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.fileAction, .none)
    }

    func testInit_SelectedFilesEmpty() {
        let vm = FilesViewModel()
        XCTAssertNotNil(vm.selectedFiles)
        XCTAssertTrue(vm.selectedFiles?.isEmpty ?? false)
    }

    func testInit_IsSelectingFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.isSelecting)
    }

    func testInit_IsSelectingDestinationFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.isSelectingDestination)
    }

    func testInit_CheckboxStateNone() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.checkboxState, .none)
    }

    func testInit_ActiveSortOptionDefault() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.activeSortOption, .nameAscending)
    }

    func testInit_TimerRunCountZero() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.timerRunCount, 0)
    }

    func testInit_TimerNil() {
        let vm = FilesViewModel()
        XCTAssertNil(vm.timer)
    }

    // MARK: - currentFolder

    func testCurrentFolder_EmptyStack_ReturnsNil() {
        let vm = FilesViewModel()
        XCTAssertNil(vm.currentFolder)
    }

    func testCurrentFolder_WithStack_ReturnsLast() {
        let vm = FilesViewModel()
        let folder = makeFolderFile(name: "Current")
        vm.navigationStack.append(folder)
        XCTAssertEqual(vm.currentFolder?.name, "Current")
    }

    func testCurrentFolder_MultipleInStack_ReturnsLast() {
        let vm = FilesViewModel()
        vm.navigationStack.append(makeFolderFile(name: "First"))
        vm.navigationStack.append(makeFolderFile(name: "Second"))
        XCTAssertEqual(vm.currentFolder?.name, "Second")
    }

    // MARK: - currentFolderIsRoot

    func testCurrentFolderIsRoot_AlwaysTrue() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.currentFolderIsRoot)
    }

    // MARK: - removeCurrentFolderFromHierarchy

    func testRemoveCurrentFolder_EmptyStack_ReturnsNil() {
        let vm = FilesViewModel()
        let result = vm.removeCurrentFolderFromHierarchy()
        XCTAssertNil(result)
    }

    func testRemoveCurrentFolder_WithItems_ReturnsLast() {
        let vm = FilesViewModel()
        let folder = makeFolderFile(name: "ToRemove")
        vm.navigationStack.append(folder)
        let result = vm.removeCurrentFolderFromHierarchy()
        XCTAssertEqual(result?.name, "ToRemove")
        XCTAssertTrue(vm.navigationStack.isEmpty)
    }

    func testRemoveCurrentFolder_LeavesRestOfStack() {
        let vm = FilesViewModel()
        vm.navigationStack.append(makeFolderFile(name: "First"))
        vm.navigationStack.append(makeFolderFile(name: "Second"))
        _ = vm.removeCurrentFolderFromHierarchy()
        XCTAssertEqual(vm.navigationStack.count, 1)
        XCTAssertEqual(vm.navigationStack.first?.name, "First")
    }

    // MARK: - shouldPerformAction

    func testShouldPerformAction_SyncedSection_ReturnsTrue() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.shouldPerformAction(forSection: FileListType.synced.rawValue))
    }

    func testShouldPerformAction_DownloadingSection_ReturnsFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.shouldPerformAction(forSection: FileListType.downloading.rawValue))
    }

    func testShouldPerformAction_UploadingSection_ReturnsFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.shouldPerformAction(forSection: FileListType.uploading.rawValue))
    }

    // MARK: - hasCancelButton

    func testHasCancelButton_UploadingSection_ReturnsTrue() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.hasCancelButton(forSection: FileListType.uploading.rawValue))
    }

    func testHasCancelButton_DownloadingSection_ReturnsFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.hasCancelButton(forSection: FileListType.downloading.rawValue))
    }

    func testHasCancelButton_SyncedSection_ReturnsFalse() {
        let vm = FilesViewModel()
        XCTAssertFalse(vm.hasCancelButton(forSection: FileListType.synced.rawValue))
    }

    // MARK: - title(forSection:)

    func testTitle_DownloadingSection() {
        let vm = FilesViewModel()
        let title = vm.title(forSection: FileListType.downloading.rawValue)
        XCTAssertFalse(title.isEmpty)
    }

    func testTitle_UploadingSection() {
        let vm = FilesViewModel()
        let title = vm.title(forSection: FileListType.uploading.rawValue)
        XCTAssertFalse(title.isEmpty)
    }

    func testTitle_SyncedSection_MatchesSortOptionTitle() {
        let vm = FilesViewModel()
        let title = vm.title(forSection: FileListType.synced.rawValue)
        XCTAssertEqual(title, vm.activeSortOption.title)
    }

    func testTitle_InvalidSection_ReturnsEmpty() {
        let vm = FilesViewModel()
        let title = vm.title(forSection: 99)
        XCTAssertEqual(title, "")
    }

    // MARK: - shouldDisplayBackgroundView

    func testShouldDisplayBackgroundView_EmptyBoth_ReturnsTrue() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.shouldDisplayBackgroundView)
    }

    func testShouldDisplayBackgroundView_HasViewModels_ReturnsFalse() {
        let vm = FilesViewModel()
        vm.viewModels.append(makeRecordFile())
        XCTAssertFalse(vm.shouldDisplayBackgroundView)
    }

    // MARK: - numberOfSections

    func testNumberOfSections_IsThree() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.numberOfSections, 3)
    }

    // MARK: - numberOfRowsInSection

    func testNumberOfRows_DownloadingSection_MatchesDownloadQueue() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.numberOfRowsInSection(FileListType.downloading.rawValue), 0)
    }

    func testNumberOfRows_DownloadingSection_WithItems() {
        let vm = FilesViewModel()
        vm.downloadQueue.append(makeRecordFile())
        vm.downloadQueue.append(makeRecordFile())
        XCTAssertEqual(vm.numberOfRowsInSection(FileListType.downloading.rawValue), 2)
    }

    func testNumberOfRows_SyncedSection_MatchesViewModels() {
        let vm = FilesViewModel()
        vm.viewModels.append(makeRecordFile())
        XCTAssertEqual(vm.numberOfRowsInSection(FileListType.synced.rawValue), 1)
    }

    // MARK: - syncedViewModels

    func testSyncedViewModels_EqualsViewModels() {
        let vm = FilesViewModel()
        vm.viewModels.append(makeRecordFile())
        vm.viewModels.append(makeFolderFile())
        XCTAssertEqual(vm.syncedViewModels.count, 2)
    }

    // MARK: - fileForRowAt (synced section)

    func testFileForRowAt_SyncedSection_ReturnsCorrectFile() {
        let vm = FilesViewModel()
        let file = makeRecordFile(name: "test.jpg")
        vm.viewModels.append(file)
        let indexPath = IndexPath(row: 0, section: FileListType.synced.rawValue)
        let result = vm.fileForRowAt(indexPath: indexPath)
        XCTAssertEqual(result.name, "test.jpg")
    }

    func testFileForRowAt_DownloadingSection_ReturnsFromDownloadQueue() {
        let vm = FilesViewModel()
        let file = makeRecordFile(name: "download.jpg")
        vm.downloadQueue.append(file)
        let indexPath = IndexPath(row: 0, section: FileListType.downloading.rawValue)
        let result = vm.fileForRowAt(indexPath: indexPath)
        XCTAssertEqual(result.name, "download.jpg")
    }

    // MARK: - clearDownloadQueue

    func testClearDownloadQueue_RemovesAll() {
        let vm = FilesViewModel()
        vm.downloadQueue.append(makeRecordFile())
        vm.downloadQueue.append(makeRecordFile())
        vm.clearDownloadQueue()
        XCTAssertTrue(vm.downloadQueue.isEmpty)
    }

    // MARK: - removeSyncedFiles

    func testRemoveSyncedFiles_NilFiles_NoChange() {
        let vm = FilesViewModel()
        vm.viewModels.append(makeRecordFile())
        vm.removeSyncedFiles(nil)
        XCTAssertEqual(vm.viewModels.count, 1)
    }

    func testRemoveSyncedFiles_RemovesMatchingFiles() {
        let vm = FilesViewModel()
        let file = makeRecordFile(name: "toRemove.jpg")
        vm.viewModels.append(file)
        vm.removeSyncedFiles([file])
        XCTAssertTrue(vm.viewModels.isEmpty)
    }

    func testRemoveSyncedFiles_EmptyArray_NoChange() {
        let vm = FilesViewModel()
        vm.viewModels.append(makeRecordFile())
        vm.removeSyncedFiles([])
        XCTAssertEqual(vm.viewModels.count, 1)
    }

    // MARK: - updateTimerCount

    func testUpdateTimerCount_IncrementsAcrossBackoffChain() {
        // The thumbnail-poll chain uses exponential-backoff intervals; each
        // fire bumps timerRunCount, and invalidateTimer is only triggered once
        // the chain is exhausted. Confirm increments and the final reset.
        let vm = FilesViewModel()
        XCTAssertEqual(vm.timerRunCount, 0)

        let totalSteps = FilesViewModel.thumbnailPollIntervals.count
        for step in 1..<totalSteps {
            vm.updateTimerCount()
            XCTAssertEqual(vm.timerRunCount, step)
        }

        // Final fire — exhausts the chain and invalidateTimer resets to 0.
        vm.updateTimerCount()
        XCTAssertEqual(vm.timerRunCount, 0)
    }

    // MARK: - invalidateTimer

    func testInvalidateTimer_NilTimer_NoOp() {
        let vm = FilesViewModel()
        vm.invalidateTimer()
        XCTAssertNil(vm.timer)
        XCTAssertEqual(vm.timerRunCount, 0)
    }

    func testInvalidateTimer_WithTimer_SetsNil() {
        let vm = FilesViewModel()
        vm.timer = Timer(timeInterval: 100, repeats: false) { _ in }
        vm.timerRunCount = 5
        vm.invalidateTimer()
        XCTAssertEqual(vm.timerRunCount, 0)
    }

    // MARK: - updateCheckboxState

    func testUpdateCheckboxState_NoSelectedFiles_None() {
        let vm = FilesViewModel()
        vm.selectedFiles = []
        vm.updateCheckboxState()
        XCTAssertEqual(vm.checkboxState, .none)
    }

    func testUpdateCheckboxState_AllSelected_Selected() {
        let vm = FilesViewModel()
        let file = makeRecordFile()
        vm.viewModels = [file]
        vm.selectedFiles = [file]
        vm.updateCheckboxState()
        XCTAssertEqual(vm.checkboxState, .selected)
    }

    func testUpdateCheckboxState_SomeSelected_Partial() {
        let vm = FilesViewModel()
        let file1 = makeRecordFile(name: "a.jpg")
        let file2 = makeRecordFile(name: "b.jpg")
        vm.viewModels = [file1, file2]
        vm.selectedFiles = [file1]
        vm.updateCheckboxState()
        XCTAssertEqual(vm.checkboxState, .partial)
    }

    // MARK: - archivePermissions (no session)

    func testArchivePermissions_NoSession_DefaultsToRead() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.archivePermissions, [.read])
    }

    // MARK: - archiveAccessRole (no session)

    func testArchiveAccessRole_NoSession_DefaultsToViewer() {
        let vm = FilesViewModel()
        XCTAssertEqual(vm.archiveAccessRole, .viewer)
    }

    // MARK: - relocate edge case

    func testRelocate_NilFiles_ReturnsError() {
        let vm = FilesViewModel()
        let destination = makeFolderFile()
        let expectation = expectation(description: "completion")

        vm.relocate(files: nil, to: destination) { response in
            if case .error = response {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - delete edge case

    func testDelete_NilFiles_ReturnsError() {
        let vm = FilesViewModel()
        let expectation = expectation(description: "completion")

        vm.delete(nil) { response in
            if case .error = response {
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - showMemberChecklist without session

    func testShowMemberChecklist_NoSession_ReturnsNil() {
        let vm = FilesViewModel()
        let expectation = expectation(description: "completion")

        vm.showMemberChecklist { result in
            XCTAssertNil(result)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - queueItemsForCurrentFolder

    func testQueueItemsForCurrentFolder_EmptyQueue_ReturnsEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.queueItemsForCurrentFolder.isEmpty)
    }

    // MARK: - PublicRootRequestStatus

    func testPublicRootRequestStatus_Equatable() {
        let a = PublicRootRequestStatus.success(folder: nil)
        let b = PublicRootRequestStatus.error(message: "fail")
        XCTAssertEqual(a, b)
    }

    // MARK: - CheckboxState

    func testCheckboxState_AllCases() {
        let none = CheckboxState.none
        let partial = CheckboxState.partial
        let selected = CheckboxState.selected
        XCTAssertNotNil(none)
        XCTAssertNotNil(partial)
        XCTAssertNotNil(selected)
    }

    // MARK: - FileListType

    func testFileListType_RawValues() {
        XCTAssertEqual(FileListType.downloading.rawValue, 0)
        XCTAssertEqual(FileListType.uploading.rawValue, 1)
        XCTAssertEqual(FileListType.synced.rawValue, 2)
    }

    // MARK: - searchViewModels

    func testSearchViewModels_InitiallyEmpty() {
        let vm = FilesViewModel()
        XCTAssertTrue(vm.searchViewModels.isEmpty)
    }

    // MARK: - Multiple state changes

    func testNavigationStack_PushAndPop() {
        let vm = FilesViewModel()
        vm.navigationStack.append(makeFolderFile(name: "A"))
        vm.navigationStack.append(makeFolderFile(name: "B"))
        XCTAssertEqual(vm.currentFolder?.name, "B")
        _ = vm.removeCurrentFolderFromHierarchy()
        XCTAssertEqual(vm.currentFolder?.name, "A")
        _ = vm.removeCurrentFolderFromHierarchy()
        XCTAssertNil(vm.currentFolder)
    }

    func testViewModelsManipulation() {
        let vm = FilesViewModel()
        let file1 = makeRecordFile(name: "a")
        let file2 = makeRecordFile(name: "b")
        vm.viewModels = [file1, file2]
        XCTAssertEqual(vm.numberOfRowsInSection(FileListType.synced.rawValue), 2)
        XCTAssertFalse(vm.shouldDisplayBackgroundView)
        vm.viewModels.removeAll()
        XCTAssertTrue(vm.shouldDisplayBackgroundView)
    }
}
