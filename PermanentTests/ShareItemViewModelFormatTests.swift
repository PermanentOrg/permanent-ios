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
        // Unparseable input now yields "" instead of echoing the raw string into the UI.
        let result = ShareItemViewModel.formatDate("not-a-date")
        XCTAssertEqual(result, "")
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

    // MARK: - expirationDisplayText shows the real stored expiry (not a now-relative preset)

    private var expiryDisplayFormatter: DateFormatter {
        let f = DateFormatter(); f.dateFormat = "MMMM d, yyyy"; return f
    }

    func testExpirationDisplayText_ShowsStoredExpiry_WhenPresetMatchesButDateDiffers() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        // Loaded link mapped to the "1 month" preset, but whose real server expiry is 45 days
        // out (e.g. set on the web). The display must show the REAL date, not now()+30d.
        let realExpiry = Date().addingTimeInterval(45 * 24 * 60 * 60)
        vm.selectedExpiration = .oneMonth
        vm.originalExpiration = .oneMonth
        vm.actualExpiryDate = realExpiry
        XCTAssertEqual(vm.expirationDisplayText,
                       "The link will expire on \(expiryDisplayFormatter.string(from: realExpiry)).")
    }

    func testExpirationDisplayText_ShowsStoredExpiry_WhenOutsidePresetRanges_NotNever() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        // Real expiry outside any preset range → mapped to .none, but the true date still exists
        // and must be shown (previously this read "never expire").
        let realExpiry = Date(timeIntervalSince1970: 1_760_000_000)
        vm.selectedExpiration = .none
        vm.originalExpiration = .none
        vm.actualExpiryDate = realExpiry
        XCTAssertEqual(vm.expirationDisplayText,
                       "The link will expire on \(expiryDisplayFormatter.string(from: realExpiry)).")
    }

    func testExpirationDisplayText_NeverWhenNoStoredExpiryAndNoPreset() {
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile())
        vm.selectedExpiration = .none
        vm.originalExpiration = .none
        vm.actualExpiryDate = nil
        XCTAssertEqual(vm.expirationDisplayText, "The link will never expire.")
    }

    // MARK: - DateUtils.displayDate (shared record-date formatter — Figma "MMM. d, yyyy")

    func testDisplayDate_FullISOWithMillisAndZone_Formats() {
        // The exact F2 bug: a full ISO timestamp used to fail parsing and render raw.
        XCTAssertEqual(DateUtils.displayDate(from: "2018-03-30T19:14:18.000Z"), "Mar. 30, 2018")
    }

    func testDisplayDate_DateOnlyInput_Formats() {
        XCTAssertEqual(DateUtils.displayDate(from: "2023-08-15"), "Aug. 15, 2023")
    }

    func testDisplayDate_September_UsesAbbreviatedMonthAndYear() {
        // Figma shows "Sept. 16, 2023"; asserted loosely so it stays stable across the OS's
        // month abbreviation ("Sep." vs "Sept.").
        let result = DateUtils.displayDate(from: "2023-09-16T00:00:00.000Z")
        XCTAssertTrue(result.hasPrefix("Sep"), "Expected abbreviated September, got: \(result)")
        XCTAssertTrue(result.hasSuffix("16, 2023"), "Expected '16, 2023', got: \(result)")
    }

    func testDisplayDate_NilEmptyDash_ReturnEmpty() {
        XCTAssertEqual(DateUtils.displayDate(from: nil), "")
        XCTAssertEqual(DateUtils.displayDate(from: ""), "")
        XCTAssertEqual(DateUtils.displayDate(from: "-"), "")
    }

    func testDisplayDate_Unparseable_ReturnsEmpty() {
        XCTAssertEqual(DateUtils.displayDate(from: "not-a-date"), "")
    }

    func testDisplayDate_PostgresTimestamptz_Formats() {
        // Stela also emits the Postgres space-separated shape on some endpoints.
        XCTAssertEqual(DateUtils.displayDate(from: "2023-08-15 12:34:56+00"), "Aug. 15, 2023")
    }

    // MARK: - DateUtils.date(fromISO:) (metadata Date field parse)

    func testDateFromISO_WithMillisAndZone_Parses() {
        XCTAssertNotNil(DateUtils.date(fromISO: "2018-03-30T19:14:18.000Z"))
    }

    func testDateFromISO_WithoutMillis_Parses() {
        XCTAssertNotNil(DateUtils.date(fromISO: "2018-03-30T19:14:18Z"))
    }

    func testDateFromISO_PostgresTimestamptz_Parses() {
        // Postgres timestamptz shape ("…+00") — the metadata Date cell must not go blank.
        XCTAssertNotNil(DateUtils.date(fromISO: "2023-01-01 00:00:00+00"))
    }

    func testDateFromISO_InvalidInputs_ReturnNil() {
        XCTAssertNil(DateUtils.date(fromISO: nil))
        XCTAssertNil(DateUtils.date(fromISO: ""))
        XCTAssertNil(DateUtils.date(fromISO: "-"))
        XCTAssertNil(DateUtils.date(fromISO: "not-a-date"))
    }
}
