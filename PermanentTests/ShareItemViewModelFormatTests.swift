//
//  ShareItemViewModelFormatTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class ShareItemViewModelFormatTests: XCTestCase {

    // MARK: - ShareItemViewModel.formatDate

    func testFormatDate_ValidDate() {
        let result = ShareItemViewModel.formatDate("2023-08-15T10:30:00")
        XCTAssertEqual(result, "Aug. 15, 2023")
    }

    func testFormatDate_EmptyString() {
        let result = ShareItemViewModel.formatDate("")
        XCTAssertEqual(result, "")
    }

    func testFormatDate_DashString() {
        let result = ShareItemViewModel.formatDate("-")
        XCTAssertEqual(result, "")
    }

    func testFormatDate_InvalidFormat() {
        let result = ShareItemViewModel.formatDate("not-a-date")
        XCTAssertEqual(result, "not-a-date")
    }

    func testFormatDate_JanuaryFirst() {
        let result = ShareItemViewModel.formatDate("2024-01-01T00:00:00")
        XCTAssertEqual(result, "Jan. 1, 2024")
    }

    func testFormatDate_DecemberThirtyFirst() {
        let result = ShareItemViewModel.formatDate("2023-12-31T23:59:59")
        XCTAssertEqual(result, "Dec. 31, 2023")
    }

    // MARK: - ShareItemViewModel Computed Properties

    func testViewModel_FileName() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        XCTAssertFalse(vm.fileName.isEmpty)
    }

    func testViewModel_HasShareLink_NoLink() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        XCTAssertFalse(vm.hasShareLink)
    }

    func testViewModel_HasShareLink_EmptyLink() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        vm.shareLink = ""
        XCTAssertFalse(vm.hasShareLink)
    }

    func testViewModel_HasShareLink_WithLink() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        vm.shareLink = "https://permanent.org/share/abc"
        XCTAssertTrue(vm.hasShareLink)
    }

    func testViewModel_InitialState() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())

        XCTAssertFalse(vm.genLinkLoading)
        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.showLinkSettings)
        XCTAssertFalse(vm.isCreatingLink)
        XCTAssertFalse(vm.showRevokeAlert)
        XCTAssertEqual(vm.selectedExpiration, .none)
        XCTAssertEqual(vm.selectedAccessLevel, .anyoneCanView)
        XCTAssertFalse(vm.showGeneralAccess)
        XCTAssertFalse(vm.showRoleSelection)
        XCTAssertFalse(vm.itemPreviewEnabled)
        XCTAssertFalse(vm.autoApproveEnabled)
        XCTAssertEqual(vm.selectedAccessRole, .viewer)
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func testViewModel_SharedArchivesInitiallyEmpty() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        XCTAssertTrue(vm.sharedArchives.isEmpty)
    }

    func testViewModel_IsApprovingShare() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        vm.approvingShareIDs.insert(42)

        XCTAssertTrue(vm.isApprovingShare(shareID: 42))
        XCTAssertFalse(vm.isApprovingShare(shareID: 99))
    }

    func testViewModel_IsDenyingShare() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        vm.denyingShareIDs.insert(42)

        XCTAssertTrue(vm.isDenyingShare(shareID: 42))
        XCTAssertFalse(vm.isDenyingShare(shareID: 99))
    }

    func testViewModel_PendingShares() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        XCTAssertTrue(vm.pendingShares.isEmpty)
    }

    // MARK: - Notification Name

    func testViewModel_DidUpdateSharesNotifName() {
        XCTAssertEqual(
            ShareItemViewModel.didUpdateSharesNotifName.rawValue,
            "ShareItemViewModel.didUpdateSharesNotifName"
        )
    }

    // MARK: - ShouldShowCreateButton

    func testViewModel_ShouldShowCreateButton_InitialLoading() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        // isLoading is set to true in init by loadInitialData()
        XCTAssertFalse(vm.shouldShowCreateButton)
    }

    // MARK: - Navigation direction

    func testViewModel_InsertionViewTransition_Forward() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        vm.navigationDirection = .forward
        XCTAssertNotNil(vm.insertionViewTransition)
    }

    func testViewModel_InsertionViewTransition_Backward() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        vm.navigationDirection = .backward
        XCTAssertNotNil(vm.insertionViewTransition)
    }
}
