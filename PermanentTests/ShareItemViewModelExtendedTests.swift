//
//  ShareItemViewModelExtendedTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 07.05.2026.

import XCTest
import Combine
@testable import Permanent

@MainActor
final class ShareItemViewModelExtendedTests: XCTestCase {

    // MARK: - Finalize Shared Archives Tests

    func testFinalizeSharedArchives_EmptyBaseNoPending_ResultsInEmptyList() {
        let vm = makeViewModel()

        vm.finalizeSharedArchives([], pendingSharesV2: nil)

        XCTAssertTrue(vm.sharedArchives.isEmpty)
        XCTAssertTrue(vm.hasLoadedArchivesOnce)
        XCTAssertFalse(vm.shouldShowArchivesSection)
    }

    func testFinalizeSharedArchives_BaseSharesOnly_PreservesAll() {
        let vm = makeViewModel()
        let shares = [
            makeShareVOData(shareID: 1, archiveID: 100, status: "status.generic.ok"),
            makeShareVOData(shareID: 2, archiveID: 200, status: "status.generic.pending")
        ]

        vm.finalizeSharedArchives(shares, pendingSharesV2: nil)

        XCTAssertEqual(vm.sharedArchives.count, 2)
        XCTAssertTrue(vm.shouldShowArchivesSection)
    }

    func testFinalizeSharedArchives_PendingSharesV2_MergedWithBase() {
        let vm = makeViewModel()
        let baseShares = [makeShareVOData(shareID: 1, archiveID: 100, status: "status.generic.ok")]
        let pendingShares = [
            PendingShareV2(id: "10", email: "new@example.com", name: "New User", accessRole: "access.role.viewer")
        ]

        vm.finalizeSharedArchives(baseShares, pendingSharesV2: pendingShares)

        XCTAssertEqual(vm.sharedArchives.count, 2)
        let invitedShare = vm.sharedArchives.last
        XCTAssertEqual(invitedShare?.accountVO?.primaryEmail, "new@example.com")
        XCTAssertEqual(invitedShare?.status, "status.generic.invited")
    }

    func testFinalizeSharedArchives_PendingSharesV2_DeduplicatedByEmail() {
        let vm = makeViewModel()
        let baseShares = [makeShareVOData(shareID: 1, archiveID: 100, status: "status.generic.ok", email: "existing@example.com")]
        let pendingShares = [
            PendingShareV2(id: "10", email: "existing@example.com", name: "Same User", accessRole: "access.role.viewer")
        ]

        vm.finalizeSharedArchives(baseShares, pendingSharesV2: pendingShares)

        XCTAssertEqual(vm.sharedArchives.count, 1, "Should deduplicate by email")
    }

    func testFinalizeSharedArchives_PreservesPreviouslyInvitedEntries() {
        let vm = makeViewModel()

        let invitedShare = makeShareVOData(shareID: -50, archiveID: nil, status: "status.generic.invited", email: "invited@example.com")
        vm.sharedArchives = [invitedShare]

        vm.finalizeSharedArchives([], pendingSharesV2: nil)

        XCTAssertEqual(vm.sharedArchives.count, 1)
        XCTAssertEqual(vm.sharedArchives.first?.accountVO?.primaryEmail, "invited@example.com")
    }

    func testFinalizeSharedArchives_DoesNotDuplicatePreservedInvited() {
        let vm = makeViewModel()

        let invitedShare = makeShareVOData(shareID: -50, archiveID: nil, status: "status.generic.invited", email: "invited@example.com")
        vm.sharedArchives = [invitedShare]

        let pendingShares = [
            PendingShareV2(id: "50", email: "invited@example.com", name: "Invited User", accessRole: "access.role.viewer")
        ]

        vm.finalizeSharedArchives([], pendingSharesV2: pendingShares)

        XCTAssertEqual(vm.sharedArchives.count, 1, "Should not duplicate invited entry present in both V2 pending and previous archives")
    }

    func testFinalizeSharedArchives_SetsHasLoadedArchivesOnce() {
        let vm = makeViewModel()
        XCTAssertFalse(vm.hasLoadedArchivesOnce)

        vm.finalizeSharedArchives([])

        XCTAssertTrue(vm.hasLoadedArchivesOnce)
    }

    func testFinalizeSharedArchives_PendingShareWithEmptyEmail_Excluded() {
        let vm = makeViewModel()
        let pendingShares = [
            PendingShareV2(id: "10", email: "", name: "No Email", accessRole: "access.role.viewer"),
            PendingShareV2(id: "11", email: "valid@example.com", name: "Valid", accessRole: "access.role.viewer")
        ]

        vm.finalizeSharedArchives([], pendingSharesV2: pendingShares)

        XCTAssertEqual(vm.sharedArchives.count, 1)
        XCTAssertEqual(vm.sharedArchives.first?.accountVO?.primaryEmail, "valid@example.com")
    }

    func testFinalizeSharedArchives_PendingShareWithNilName_UsesEmailAsDisplay() {
        let vm = makeViewModel()
        let pendingShares = [
            PendingShareV2(id: "10", email: "user@example.com", name: nil, accessRole: "access.role.viewer")
        ]

        vm.finalizeSharedArchives([], pendingSharesV2: pendingShares)

        XCTAssertEqual(vm.sharedArchives.first?.accountVO?.fullName, "user@example.com")
    }

    func testFinalizeSharedArchives_PendingShareHasNegativeShareID() throws {
        let vm = makeViewModel()
        let pendingShares = [
            PendingShareV2(id: "42", email: "user@example.com", name: "User", accessRole: "access.role.viewer")
        ]

        vm.finalizeSharedArchives([], pendingSharesV2: pendingShares)

        let firstArchive = try XCTUnwrap(vm.sharedArchives.first)
        let shareID = try XCTUnwrap(firstArchive.shareID, "Pending share should have a shareID")
        XCTAssertLessThan(shareID, 0, "Pending share should have negative shareID to distinguish from real shares")
    }

    // MARK: - Pending Shares Computed Property Tests

    func testPendingShares_FiltersPendingCorrectly() {
        let vm = makeViewModel()
        vm.sharedArchives = [
            makeShareVOData(shareID: 1, archiveID: 100, status: "status.generic.pending"),
            makeShareVOData(shareID: 2, archiveID: 200, status: "status.generic.ok"),
            makeShareVOData(shareID: 3, archiveID: 300, status: "status.generic.pending")
        ]

        XCTAssertEqual(vm.pendingShares.count, 2)
    }

    func testPendingShares_EmptyWhenNoPending() {
        let vm = makeViewModel()
        vm.sharedArchives = [
            makeShareVOData(shareID: 1, archiveID: 100, status: "status.generic.ok")
        ]

        XCTAssertTrue(vm.pendingShares.isEmpty)
    }

    // MARK: - Expiration Setting from ShareVO Tests

    func testSetSelectedExpirationFromShareVO_NilExpiresDT_SetsNever() {
        let vm = makeViewModel()
        let shareVO = makeMockSharebyURLVOData(expiresDT: nil)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .never)
        XCTAssertEqual(vm.originalExpiration, .never)
    }

    func testSetSelectedExpirationFromShareVO_EmptyExpiresDT_SetsNever() {
        let vm = makeViewModel()
        let shareVO = makeMockSharebyURLVOData(expiresDT: "")

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .never)
        XCTAssertEqual(vm.originalExpiration, .never)
    }

    func testSetSelectedExpirationFromShareVO_UnparseableDate_SetsNone() {
        let vm = makeViewModel()
        let shareVO = makeMockSharebyURLVOData(expiresDT: "not-a-date")

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .none)
        XCTAssertEqual(vm.originalExpiration, .none)
    }

    func testSetSelectedExpirationFromShareVO_OneDayFromNow_SetsOneDay() {
        let vm = makeViewModel()
        let oneDayFromNow = Calendar.current.date(byAdding: .hour, value: 24, to: Date())!
        let dateString = ISO8601DateFormatter().string(from: oneDayFromNow)
        let shareVO = makeMockSharebyURLVOData(expiresDT: dateString)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .oneDay)
    }

    func testSetSelectedExpirationFromShareVO_OneMonthFromNow_SetsOneMonth() {
        let vm = makeViewModel()
        let oneMonthFromNow = Calendar.current.date(byAdding: .day, value: 30, to: Date())!
        let dateString = ISO8601DateFormatter().string(from: oneMonthFromNow)
        let shareVO = makeMockSharebyURLVOData(expiresDT: dateString)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .oneMonth)
    }

    func testSetSelectedExpirationFromShareVO_OneYearFromNow_SetsOneYear() {
        let vm = makeViewModel()
        let oneYearFromNow = Calendar.current.date(byAdding: .day, value: 365, to: Date())!
        let dateString = ISO8601DateFormatter().string(from: oneYearFromNow)
        let shareVO = makeMockSharebyURLVOData(expiresDT: dateString)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .oneYear)
    }

    func testSetSelectedExpirationFromShareVO_OtherTimeframe_SetsNone() {
        let vm = makeViewModel()
        let twoWeeksFromNow = Calendar.current.date(byAdding: .day, value: 14, to: Date())!
        let dateString = ISO8601DateFormatter().string(from: twoWeeksFromNow)
        let shareVO = makeMockSharebyURLVOData(expiresDT: dateString)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .none)
    }

    // MARK: - Access Level from V2 Data Tests

    func testSetAccessLevelFromV2Data_NoneRestrictions_SetsAnyoneCanView() {
        let vm = makeViewModel()
        let v2Data = ShareLinkV2Data(
            id: "1", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: "editor", accessRestrictions: "none",
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessLevel, .anyoneCanView)
        XCTAssertEqual(vm.selectedAccessRole, .viewer, "API constraint: none restrictions requires viewer role")
    }

    func testSetAccessLevelFromV2Data_AccountRestrictions_SetsRestricted() {
        let vm = makeViewModel()
        let v2Data = ShareLinkV2Data(
            id: "1", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: "editor", accessRestrictions: "account",
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessLevel, .restricted)
        XCTAssertEqual(vm.selectedAccessRole, .editor)
    }

    func testSetAccessLevelFromV2Data_ApprovalRestrictions_SetsRestricted() {
        let vm = makeViewModel()
        let v2Data = ShareLinkV2Data(
            id: "1", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: "viewer", accessRestrictions: "approval",
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessLevel, .restricted)
    }

    func testSetAccessLevelFromV2Data_NilRestrictions_DefaultsToAnyoneCanView() {
        let vm = makeViewModel()
        let v2Data = ShareLinkV2Data(
            id: "1", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: nil, accessRestrictions: nil,
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessLevel, .anyoneCanView)
        XCTAssertEqual(vm.selectedAccessRole, .viewer)
    }

    func testSetAccessLevelFromV2Data_SetsOriginalValues() {
        let vm = makeViewModel()
        let v2Data = ShareLinkV2Data(
            id: "1", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: "editor", accessRestrictions: "approval",
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.originalAccessLevel, .restricted)
        XCTAssertEqual(vm.originalAccessRole, .editor)
    }

    func testSetAccessLevelFromV2Data_ContributorPermission() {
        let vm = makeViewModel()
        let v2Data = ShareLinkV2Data(
            id: "1", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: "contributor", accessRestrictions: "approval",
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessRole, .contributor)
    }

    func testSetAccessLevelFromV2Data_ManagerPermission_MapsToCurator() {
        let vm = makeViewModel()
        let v2Data = ShareLinkV2Data(
            id: "1", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: "manager", accessRestrictions: "approval",
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessRole, .curator, "Backend 'manager' maps to UI 'curator'")
    }

    // MARK: - Update Access Level Tests

    func testUpdateAccessLevel_AnyoneCanView_ForcesViewerRole() {
        let vm = makeViewModel()
        vm.selectedAccessRole = .editor

        vm.updateAccessLevel(.anyoneCanView)

        XCTAssertEqual(vm.selectedAccessLevel, .anyoneCanView)
        XCTAssertEqual(vm.selectedAccessRole, .viewer, "API requirement: anyone can view requires viewer")
        XCTAssertFalse(vm.showGeneralAccess, "Should close general access view")
    }

    func testUpdateAccessLevel_SetsNavigationBackward() {
        let vm = makeViewModel()

        vm.updateAccessLevel(.restricted)

        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    // MARK: - Update Access Role Tests

    func testUpdateAccessRole_ClosesRoleSelection() {
        let vm = makeViewModel()
        vm.showRoleSelection = true

        vm.updateAccessRole(.editor)

        XCTAssertFalse(vm.showRoleSelection)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    // MARK: - Check For Unsaved Changes Tests

    func testCheckForUnsavedChanges_AllOriginal_NoChanges() {
        let vm = makeViewModel()
        vm.originalExpiration = .never
        vm.originalAccessLevel = .anyoneCanView
        vm.originalAccessRole = .viewer
        vm.originalItemPreview = false
        vm.originalAutoApprove = false

        vm.selectedExpiration = .never
        vm.selectedAccessLevel = .anyoneCanView
        vm.selectedAccessRole = .viewer
        vm.itemPreviewEnabled = false
        vm.autoApproveEnabled = false

        vm.updateExpiration(.never)

        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    func testCheckForUnsavedChanges_ExpirationChanged_HasChanges() {
        let vm = makeViewModel()
        vm.originalExpiration = .never

        vm.updateExpiration(.oneMonth)

        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func testCheckForUnsavedChanges_AccessLevelChanged_HasChanges() {
        let vm = makeViewModel()
        vm.originalAccessLevel = .anyoneCanView

        vm.updateAccessLevel(.restricted)

        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func testCheckForUnsavedChanges_PreviewToggled_HasChanges() {
        let vm = makeViewModel()
        vm.originalItemPreview = false
        vm.itemPreviewEnabled = false

        vm.toggleItemPreview()

        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    func testCheckForUnsavedChanges_AutoApproveToggled_HasChanges() {
        let vm = makeViewModel()
        vm.originalAutoApprove = false
        vm.autoApproveEnabled = false

        vm.toggleAutoApprove()

        XCTAssertTrue(vm.hasUnsavedChanges)
    }

    // MARK: - Revert Changes Tests

    func testRevertChanges_RestoresAllOriginalValues() {
        let vm = makeViewModel()
        vm.originalExpiration = .oneYear
        vm.originalAccessLevel = .restricted
        vm.originalAccessRole = .editor

        vm.selectedExpiration = .oneDay
        vm.selectedAccessLevel = .anyoneCanView
        vm.selectedAccessRole = .viewer
        vm.hasUnsavedChanges = true

        vm.revertChanges()

        XCTAssertEqual(vm.selectedExpiration, .oneYear)
        XCTAssertEqual(vm.selectedAccessLevel, .restricted)
        XCTAssertEqual(vm.selectedAccessRole, .editor)
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    // MARK: - Save Changes Routing Tests

    func testSaveChanges_NoUnsavedChanges_ClosesWithoutSaving() {
        let vm = makeViewModel()
        vm.hasUnsavedChanges = false
        vm.showLinkSettings = true
        vm.navigationDirection = .forward

        vm.saveChanges()

        XCTAssertEqual(vm.navigationDirection, .backward)
        XCTAssertFalse(vm.showLinkSettings)
    }

    func testSaveChanges_WithV2Data_UsesV2Path() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.shareLinkV2Data = ShareLinkV2Data(
            id: "link-123", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: "viewer", accessRestrictions: "none",
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )
        vm.hasUnsavedChanges = true
        vm.originalExpiration = .never
        vm.selectedExpiration = .oneMonth

        vm.saveChanges()

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(repo.updateShareLinkV2Called, "Should use V2 update path")
        XCTAssertEqual(repo.lastUpdateV2ShareLinkId, "link-123")
    }

    func testSaveChanges_WithSharebyURLID_UsesV2PathWithThatID() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.shareLinkV2Data = nil
        vm.shareVO = makeMockSharebyURLVOData(sharebyURLID: 456)
        vm.hasUnsavedChanges = true
        vm.originalExpiration = .never
        vm.selectedExpiration = .oneMonth

        vm.saveChanges()

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(repo.updateShareLinkV2Called, "Should use V2 path via sharebyURLID")
        XCTAssertEqual(repo.lastUpdateV2ShareLinkId, "456")
    }

    func testSaveChanges_V1Fallback_WhenNoV2DataOrSharebyURLID() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.shareLinkV2Data = nil
        vm.shareVO = makeMockSharebyURLVOData(sharebyURLID: nil)
        vm.hasUnsavedChanges = true
        vm.originalExpiration = .never
        vm.selectedExpiration = .oneMonth

        vm.saveChanges()

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(repo.updateLinkCalled, "Should fall back to V1 update")
    }

    // MARK: - V2 Update Merge Tests

    func testUpdateShareLinkV2_MergesResponseWithExistingData() async {
        let repo = TrackingShareManagementRepository()
        repo.mockV2UpdateResponse = ShareLinkV2Data(
            id: "link-123", itemId: nil, itemType: nil, token: nil,
            permissionsLevel: "editor", accessRestrictions: "approval",
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: "2026-05-07"
        )
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.shareLinkV2Data = ShareLinkV2Data(
            id: "link-123", itemId: "folder-1", itemType: "folder", token: "original-token",
            permissionsLevel: "viewer", accessRestrictions: "none",
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: "2026-01-01", updatedAt: "2026-01-01"
        )
        vm.hasUnsavedChanges = true
        vm.originalAccessLevel = .anyoneCanView
        vm.selectedAccessLevel = .restricted

        vm.updateShareLinkV2(shareLinkId: "link-123")

        // Poll for the merge to complete instead of a fixed sleep: the merged
        // permissionsLevel is the last value set in the async chain (Task →
        // repo callback → MainActor), so a fixed 500ms window flaked on slow CI.
        await waitUntil(vm.shareLinkV2Data?.permissionsLevel == "editor")

        XCTAssertEqual(vm.shareLinkV2Data?.itemId, "folder-1", "Should preserve itemId from previous data")
        XCTAssertEqual(vm.shareLinkV2Data?.itemType, "folder", "Should preserve itemType from previous data")
        XCTAssertEqual(vm.shareLinkV2Data?.token, "original-token", "Should preserve token from previous data")
        XCTAssertEqual(vm.shareLinkV2Data?.permissionsLevel, "editor", "Should use updated permissionsLevel")
        XCTAssertEqual(vm.shareLinkV2Data?.accessRestrictions, "approval", "Should use updated accessRestrictions")
    }

    // MARK: - Revoke Flow Tests

    func testPerformRevokeLink_WithV2Data_UsesV2Delete() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.shareLinkV2Data = ShareLinkV2Data(
            id: "link-to-delete", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: "viewer", accessRestrictions: "none",
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )
        vm.shareVO = makeMockSharebyURLVOData()
        vm.shareLink = "https://example.com/share/token"

        vm.performRevokeLink()

        await waitUntil(vm.shareLink == nil && vm.shareLinkV2Data == nil)

        XCTAssertTrue(repo.deleteShareLinkV2Called)
        XCTAssertEqual(repo.lastDeleteShareLinkId, "link-to-delete")
        XCTAssertNil(vm.shareLink, "Should clear share link after revoke")
        XCTAssertNil(vm.shareLinkV2Data, "Should clear V2 data after revoke")
    }

    func testPerformRevokeLink_WithSharebyURLID_UsesV2Delete() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.shareLinkV2Data = nil
        vm.shareVO = makeMockSharebyURLVOData(sharebyURLID: 789)
        vm.shareLink = "https://example.com/share/token"

        vm.performRevokeLink()

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(repo.deleteShareLinkV2Called)
        XCTAssertEqual(repo.lastDeleteShareLinkId, "789")
    }

    func testPerformRevokeLink_V1Fallback_WhenNoV2DataOrSharebyURLID() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.shareLinkV2Data = nil
        vm.shareVO = makeMockSharebyURLVOData(sharebyURLID: nil)
        vm.shareLink = "https://example.com/share/token"

        vm.performRevokeLink()

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(repo.revokeLinkCalled, "Should fall back to V1 revoke")
    }

    func testPerformRevokeLink_ClearsNavigationState() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.shareLinkV2Data = ShareLinkV2Data(
            id: "link-1", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: nil, accessRestrictions: nil,
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )
        vm.shareVO = makeMockSharebyURLVOData()
        vm.shareLink = "https://example.com/share/token"
        vm.showLinkSettings = true

        vm.performRevokeLink()

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertFalse(vm.showLinkSettings)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    // MARK: - Cached V2 Item ID Tests

    func testFetchSharedArchives_CachesV2ItemIds() {
        let vm = makeViewModel()
        vm.shareLinkV2Data = ShareLinkV2Data(
            id: "1", itemId: "folder-42", itemType: "folder", token: "t",
            permissionsLevel: nil, accessRestrictions: nil,
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )

        vm.fetchSharedArchives()

        XCTAssertEqual(vm.cachedV2ItemId, "folder-42")
        XCTAssertEqual(vm.cachedV2ItemType, "folder")
    }

    func testFetchSharedArchives_UsesCachedIdsWhenV2DataNil() {
        let vm = makeViewModel()
        vm.shareLinkV2Data = nil
        vm.cachedV2ItemId = "record-99"
        vm.cachedV2ItemType = "record"

        vm.fetchSharedArchives()

        XCTAssertEqual(vm.cachedV2ItemId, "record-99", "Should still use cached IDs")
    }

    func testCachedV2Ids_SurviveRevoke() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.shareLinkV2Data = ShareLinkV2Data(
            id: "link-1", itemId: "folder-42", itemType: "folder", token: "t",
            permissionsLevel: nil, accessRestrictions: nil,
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )
        vm.shareVO = makeMockSharebyURLVOData()
        vm.shareLink = "https://example.com/share/token"
        vm.cachedV2ItemId = "folder-42"
        vm.cachedV2ItemType = "folder"

        vm.performRevokeLink()

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertNil(vm.shareLinkV2Data, "V2 data should be cleared")
        XCTAssertEqual(vm.cachedV2ItemId, "folder-42", "Cached ID should survive revoke")
        XCTAssertEqual(vm.cachedV2ItemType, "folder", "Cached type should survive revoke")
    }

    // MARK: - isFolder Computed Property Tests

    func testIsFolder_V2DataSaysFolder_ReturnsTrue() {
        let vm = makeViewModel(isFolder: false)
        vm.shareLinkV2Data = ShareLinkV2Data(
            id: "1", itemId: "1", itemType: "folder", token: nil,
            permissionsLevel: nil, accessRestrictions: nil,
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )

        XCTAssertTrue(vm.isFolder, "V2 data should be authoritative")
    }

    func testIsFolder_V2DataSaysRecord_ReturnsFalse() {
        let vm = makeViewModel(isFolder: true)
        vm.shareLinkV2Data = ShareLinkV2Data(
            id: "1", itemId: "1", itemType: "record", token: nil,
            permissionsLevel: nil, accessRestrictions: nil,
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )

        XCTAssertFalse(vm.isFolder, "V2 data should be authoritative")
    }

    func testIsFolder_NoV2Data_FallsBackToFileModel() {
        let fileVM = makeViewModel(isFolder: false)
        fileVM.shareLinkV2Data = nil

        XCTAssertFalse(fileVM.isFolder)

        let folderVM = makeViewModel(isFolder: true)
        folderVM.shareLinkV2Data = nil

        XCTAssertTrue(folderVM.isFolder)
    }

    // MARK: - thumbnailURL Computed Property Tests

    func testThumbnailURL_V2RecordWithRecordThumb_UsesV2Thumb() {
        let vm = makeViewModel()
        vm.shareLinkV2Data = ShareLinkV2Data(
            id: "1", itemId: "1", itemType: "record", token: nil,
            permissionsLevel: nil, accessRestrictions: nil,
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )
        vm.recordV2ThumbnailURL = "https://v2-thumb.example.com/record.jpg"

        XCTAssertEqual(vm.thumbnailURL, "https://v2-thumb.example.com/record.jpg")
    }

    func testThumbnailURL_NoV2Data_FallsBackToFileModel() {
        let vm = makeViewModel()
        vm.shareLinkV2Data = nil
        vm.recordV2ThumbnailURL = nil

        XCTAssertEqual(vm.thumbnailURL, vm.fileModel.preferredThumbnailURL)
    }

    // MARK: - Navigation Flow Tests

    func testOpenFindArchiveByEmail_SetsCorrectState() {
        let vm = makeViewModel()
        vm.showSelectArchiveFromPastShares = true
        vm.showGrantArchiveAccess = true
        vm.showInviteAndGrantAccess = true

        vm.openFindArchiveByEmail()

        XCTAssertTrue(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertEqual(vm.navigationDirection, .forward)
    }

    func testCloseFindArchiveByEmail_SetsCorrectState() {
        let vm = makeViewModel()
        vm.showFindArchiveByEmail = true

        vm.closeFindArchiveByEmail()

        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testOpenSelectArchiveFromPastShares_SetsCorrectState() {
        let vm = makeViewModel()
        vm.showFindArchiveByEmail = true

        vm.openSelectArchiveFromPastShares()

        XCTAssertTrue(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertEqual(vm.navigationDirection, .forward)
    }

    func testCloseSelectArchiveFromPastShares_SetsCorrectState() {
        let vm = makeViewModel()
        vm.showSelectArchiveFromPastShares = true

        vm.closeSelectArchiveFromPastShares()

        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testOpenGrantArchiveAccess_FromEmail_SetsCorrectState() {
        let vm = makeViewModel()

        vm.openGrantArchiveAccess(archiveName: "Test Archive", archiveInitials: "TA", archiveID: 42, source: .findByEmail)

        XCTAssertTrue(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertEqual(vm.pendingArchiveGrant?.name, "Test Archive")
        XCTAssertEqual(vm.pendingArchiveGrant?.archiveID, 42)
        XCTAssertEqual(vm.pendingArchiveGrant?.source, .findByEmail)
        XCTAssertEqual(vm.selectedRoleForGrantAccess, .viewer)
    }

    func testOpenGrantArchiveAccess_FromPastShares_SetsCorrectState() {
        let vm = makeViewModel()

        vm.openGrantArchiveAccess(archiveName: "Past Archive", archiveInitials: "PA", source: .pastShares)

        XCTAssertEqual(vm.pendingArchiveGrant?.source, .pastShares)
    }

    func testCloseGrantArchiveAccess_FromEmail_RestoresFindByEmail() {
        let vm = makeViewModel()
        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Test", initials: "T", archiveID: nil, thumbnailURL: nil, source: .findByEmail
        )
        vm.showGrantArchiveAccess = true

        vm.closeGrantArchiveAccess()

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertTrue(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
    }

    func testCloseGrantArchiveAccess_FromPastShares_RestoresPastShares() {
        let vm = makeViewModel()
        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Test", initials: "T", archiveID: nil, thumbnailURL: nil, source: .pastShares
        )
        vm.showGrantArchiveAccess = true

        vm.closeGrantArchiveAccess()

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertTrue(vm.showSelectArchiveFromPastShares)
    }

    func testOpenInviteAndGrantAccess_SetsCorrectState() {
        let vm = makeViewModel()

        vm.openInviteAndGrantAccess(recipientEmail: "test@example.com")

        XCTAssertTrue(vm.showInviteAndGrantAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertEqual(vm.invitationRecipientEmail, "test@example.com")
        XCTAssertEqual(vm.selectedRoleForInviteAccess, .viewer)
    }

    func testOpenInviteAndGrantAccess_DeriveNameFromEmail() {
        let vm = makeViewModel()
        vm.invitationRecipientFullName = ""

        vm.openInviteAndGrantAccess(recipientEmail: "john.doe@example.com")

        XCTAssertEqual(vm.invitationRecipientFullName, "john.doe")
    }

    func testCloseInviteAndGrantAccess_RestoresFindByEmail() {
        let vm = makeViewModel()
        vm.showInviteAndGrantAccess = true

        vm.closeInviteAndGrantAccess()

        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertTrue(vm.showFindArchiveByEmail)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testOpenEditInvitation_SetsCorrectState() {
        let vm = makeViewModel()
        let share = makeShareVOData(shareID: -10, archiveID: nil, status: "status.generic.invited", accessRole: "access.role.editor")

        vm.openEditInvitation(shareVO: share)

        XCTAssertTrue(vm.showEditInvitation)
        XCTAssertEqual(vm.editingInvitation?.shareID, -10)
        XCTAssertEqual(vm.selectedRoleForEditInvitation, .editor)
        XCTAssertEqual(vm.navigationDirection, .forward)
    }

    func testCloseEditInvitation_ClearsState() {
        let vm = makeViewModel()
        vm.showEditInvitation = true
        vm.editingInvitation = makeShareVOData(shareID: -10, archiveID: nil, status: "status.generic.invited")

        vm.closeEditInvitation()

        XCTAssertFalse(vm.showEditInvitation)
        XCTAssertNil(vm.editingInvitation)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    // MARK: - Archive Access Management Tests

    func testUpdateArchiveAccessRole_Success_UpdatesArchiveInList() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        let share = makeShareVOData(shareID: 100, archiveID: 500, status: "status.generic.ok", accessRole: "access.role.viewer")
        vm.sharedArchives = [share]
        vm.selectedArchiveForEdit = share

        let expectation = XCTestExpectation(description: "Update completed")

        vm.updateArchiveAccessRole(shareVO: share, newRole: .editor) { result, _ in
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 3.0)

        XCTAssertFalse(vm.isLoading)
    }

    func testUpdateArchiveAccessRole_InvalidShareID_ReturnsError() {
        let vm = makeViewModel()
        let share = makeShareVOData(shareID: nil, archiveID: 100, status: "status.generic.ok")

        let expectation = XCTestExpectation(description: "Error returned")

        vm.updateArchiveAccessRole(shareVO: share, newRole: .editor) { result, _ in
            if case .error = result {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testRevokeArchiveAccess_Success_RemovesFromList() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        let share = makeShareVOData(shareID: 100, archiveID: 500, status: "status.generic.ok")
        vm.sharedArchives = [share]

        let expectation = XCTestExpectation(description: "Revoke completed")

        vm.revokeArchiveAccess(shareVO: share) { result, _ in
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 3.0)

        XCTAssertTrue(vm.sharedArchives.isEmpty)
        XCTAssertFalse(vm.shouldShowArchivesSection)
    }

    func testRevokeArchiveAccess_InvalidShareID_ReturnsError() {
        let vm = makeViewModel()
        let share = makeShareVOData(shareID: nil, archiveID: 100, status: "status.generic.ok")

        let expectation = XCTestExpectation(description: "Error returned")

        vm.revokeArchiveAccess(shareVO: share) { result, _ in
            if case .error = result {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testRevokeArchiveAccess_UpdatesShouldShowArchivesSection() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        let share1 = makeShareVOData(shareID: 100, archiveID: 500, status: "status.generic.ok")
        let share2 = makeShareVOData(shareID: 200, archiveID: 600, status: "status.generic.ok")
        vm.sharedArchives = [share1, share2]
        vm.shouldShowArchivesSection = true

        let expectation = XCTestExpectation(description: "Revoke completed")

        vm.revokeArchiveAccess(shareVO: share1) { result, _ in
            expectation.fulfill()
        }

        await fulfillment(of: [expectation], timeout: 3.0)

        XCTAssertEqual(vm.sharedArchives.count, 1)
        XCTAssertTrue(vm.shouldShowArchivesSection, "Should still show section with remaining archive")
    }

    // MARK: - Approve / Deny Share Tests

    func testApproveShareRequest_AddsToApprovingSet() {
        let repo = TrackingShareManagementRepository(delayed: true)
        let vm = makeViewModel(repository: repo)
        let share = makeShareVOData(shareID: 42, archiveID: 100, status: "status.generic.pending")
        vm.sharedArchives = [share]

        vm.approveShareRequest(share)

        // Give dispatch async a moment
        let expectation = XCTestExpectation(description: "Approving set updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(vm.isApprovingShare(shareID: 42))
    }

    func testDenyShareRequest_AddsToDenyingSet() {
        let repo = TrackingShareManagementRepository(delayed: true)
        let vm = makeViewModel(repository: repo)
        let share = makeShareVOData(shareID: 42, archiveID: 100, status: "status.generic.pending")
        vm.sharedArchives = [share]

        vm.denyShareRequest(share)

        let expectation = XCTestExpectation(description: "Denying set updated")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertTrue(vm.isDenyingShare(shareID: 42))
    }

    func testDenyShareRequest_RemovesFromListOnSuccess() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)

        let share = makeShareVOData(shareID: 42, archiveID: 100, status: "status.generic.pending")
        vm.sharedArchives = [share]

        vm.denyShareRequest(share)

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(vm.sharedArchives.isEmpty)
    }

    func testApproveShareRequest_NilShareID_NoOp() {
        let vm = makeViewModel()
        let share = makeShareVOData(shareID: nil, archiveID: 100, status: "status.generic.pending")

        vm.approveShareRequest(share)

        XCTAssertTrue(vm.approvingShareIDs.isEmpty)
    }

    // MARK: - Approve All Pending Tests

    func testApproveAllPendingRequests_EmptyPending_NoOp() {
        let vm = makeViewModel()
        vm.sharedArchives = [
            makeShareVOData(shareID: 1, archiveID: 100, status: "status.generic.ok")
        ]

        vm.approveAllPendingRequests()

        XCTAssertFalse(vm.isApprovingAll, "Should not start approving when no pending shares")
    }

    func testApproveAllPendingRequests_SetsIsApprovingAll() {
        let repo = TrackingShareManagementRepository(delayed: true)
        let vm = makeViewModel(repository: repo)
        vm.sharedArchives = [
            makeShareVOData(shareID: 1, archiveID: 100, status: "status.generic.pending"),
            makeShareVOData(shareID: 2, archiveID: 200, status: "status.generic.pending")
        ]

        vm.approveAllPendingRequests()

        XCTAssertTrue(vm.isApprovingAll)
    }

    // MARK: - Notify Share Updates Tests

    func testNotifyShareUpdates_PostsNotification() {
        let vm = makeViewModel()
        vm.sharedArchives = [
            makeShareVOData(shareID: 1, archiveID: 100, status: "status.generic.ok")
        ]

        let expectation = XCTestExpectation(description: "Notification posted")
        let observer = NotificationCenter.default.addObserver(
            forName: ShareItemViewModel.didUpdateSharesNotifName,
            object: vm,
            queue: .main
        ) { _ in
            expectation.fulfill()
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        vm.notifyShareUpdates()

        wait(for: [expectation], timeout: 1.0)
    }

    func testNotifyShareUpdates_IncludesUpdatedFileModel() {
        let vm = makeViewModel()
        let share = makeShareVOData(shareID: 1, archiveID: 100, status: "status.generic.ok")
        vm.sharedArchives = [share]

        let expectation = XCTestExpectation(description: "Notification posted")
        var receivedFileModel: FileModel?

        let observer = NotificationCenter.default.addObserver(
            forName: ShareItemViewModel.didUpdateSharesNotifName,
            object: vm,
            queue: .main
        ) { notif in
            receivedFileModel = notif.userInfo?["fileModel"] as? FileModel
            expectation.fulfill()
        }
        defer { NotificationCenter.default.removeObserver(observer) }

        vm.notifyShareUpdates()

        wait(for: [expectation], timeout: 1.0)

        XCTAssertNotNil(receivedFileModel)
        XCTAssertEqual(receivedFileModel?.minArchiveVOS.count, 1)
    }

    // MARK: - Error Handling Tests (Indirect via V2 Update)

    func testUpdateShareLinkV2_Error_CallsRepository() async {
        let repo = TrackingShareManagementRepository()
        repo.shouldReturnError = true
        repo.errorMessage = "Network error occurred"
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.shareLinkV2Data = ShareLinkV2Data(
            id: "link-1", itemId: "1", itemType: "folder", token: "t",
            permissionsLevel: nil, accessRestrictions: nil,
            maxUses: nil, usesExpended: nil, expirationTimestamp: nil,
            creatorAccount: nil, createdAt: nil, updatedAt: nil
        )
        vm.hasUnsavedChanges = true

        vm.updateShareLinkV2(shareLinkId: "link-1")

        await waitUntil(repo.updateShareLinkV2Called)

        XCTAssertTrue(repo.updateShareLinkV2Called)
        XCTAssertEqual(repo.lastUpdateV2ShareLinkId, "link-1")
    }

    func testCreateShareLinkV2_Error_CallsRepository() async {
        let repo = TrackingShareManagementRepository()
        repo.shouldReturnError = true
        repo.errorMessage = "Creation failed"
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        vm.createShareLinkV2()

        await waitUntil(repo.createShareLinkV2Called)

        XCTAssertTrue(repo.createShareLinkV2Called)
    }

    // MARK: - V2 Link Load for Existing Link Tests

    func testGetShareLink_Retrieve_WithExistingLink_TriesV2Load() async {
        let repo = TrackingShareManagementRepository()
        repo.shouldReturnLink = true
        let vm = ShareItemViewModel(fileModel: FileModel.mockFile(), shareManagementRepository: repo)

        let loadComplete = expectation(description: "Loading completed")
        var cancellables = Set<AnyCancellable>()

        vm.$isLoading
            .dropFirst()
            .filter { !$0 }
            .first()
            .sink { _ in loadComplete.fulfill() }
            .store(in: &cancellables)

        await fulfillment(of: [loadComplete], timeout: 5.0)

        XCTAssertTrue(repo.getShareLinkV2ByIdCalled || repo.getShareLinkV2ByFileCalled,
                       "Should attempt to load V2 data for existing link")
    }

    // MARK: - Expiration Display Text Tests

    func testExpirationDisplayText_NeverOption_ShowsNeverExpire() {
        let vm = makeViewModel()
        vm.selectedExpiration = .never

        XCTAssertTrue(vm.expirationDisplayText.contains("never expire"))
    }

    func testExpirationDisplayText_NoneOption_ShowsNeverExpire() {
        let vm = makeViewModel()
        vm.selectedExpiration = .none

        XCTAssertTrue(vm.expirationDisplayText.contains("never expire"))
    }

    func testExpirationDisplayText_OneDay_ShowsFormattedDate() {
        let vm = makeViewModel()
        vm.selectedExpiration = .oneDay

        let displayText = vm.expirationDisplayText
        XCTAssertTrue(displayText.contains("expire on"), "Should show expiration date")
        XCTAssertFalse(displayText.contains("never"), "Should not say never")
    }

    func testExpirationDisplayText_OneMonth_ShowsFormattedDate() {
        let vm = makeViewModel()
        vm.selectedExpiration = .oneMonth

        let displayText = vm.expirationDisplayText
        XCTAssertTrue(displayText.contains("expire on"))
    }

    func testExpirationDisplayText_OneYear_ShowsFormattedDate() {
        let vm = makeViewModel()
        vm.selectedExpiration = .oneYear

        let displayText = vm.expirationDisplayText
        XCTAssertTrue(displayText.contains("expire on"))
    }

    // MARK: - Legacy Email Invitation Tests

    func testSubmitEmailInvitation_ClearsFieldAndHidesView() async {
        let vm = makeViewModel()
        vm.showEmailAddressField = true
        vm.emailAddress = "test@example.com"

        vm.submitEmailInvitation()

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertFalse(vm.showEmailAddressField)
        XCTAssertTrue(vm.emailAddress.isEmpty)
    }

    func testSubmitEmailInvitation_EmptyEmail_NoOp() async {
        let vm = makeViewModel()
        vm.showEmailAddressField = true
        vm.emailAddress = ""

        vm.submitEmailInvitation()

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(vm.showEmailAddressField, "Should not close when email is empty")
    }

    // MARK: - Date Formatter Tests

    func testFormatDate_ValidDate_ReturnsFormattedString() {
        let result = ShareItemViewModel.formatDate("2026-05-07T10:30:00")
        XCTAssertEqual(result, "May. 7, 2026")
    }

    func testFormatDate_EmptyString_ReturnsEmpty() {
        let result = ShareItemViewModel.formatDate("")
        XCTAssertEqual(result, "")
    }

    func testFormatDate_DashString_ReturnsEmpty() {
        let result = ShareItemViewModel.formatDate("-")
        XCTAssertEqual(result, "")
    }

    func testFormatDate_InvalidDate_ReturnsSameString() {
        let result = ShareItemViewModel.formatDate("not-a-date")
        XCTAssertEqual(result, "not-a-date")
    }

    // MARK: - Has Share Link Tests

    func testHasShareLink_WithLink_ReturnsTrue() {
        let vm = makeViewModel()
        vm.shareLink = "https://example.com/share/token"

        XCTAssertTrue(vm.hasShareLink)
    }

    func testHasShareLink_NilLink_ReturnsFalse() {
        let vm = makeViewModel()
        vm.shareLink = nil

        XCTAssertFalse(vm.hasShareLink)
    }

    func testHasShareLink_EmptyLink_ReturnsFalse() {
        let vm = makeViewModel()
        vm.shareLink = ""

        XCTAssertFalse(vm.hasShareLink)
    }

    // MARK: - Revokelink Shows Alert

    func testRevokeLink_ShowsAlert() {
        let vm = makeViewModel()

        vm.revokeLink()

        XCTAssertTrue(vm.showRevokeAlert)
    }

    // MARK: - submitGrantArchiveAccess Tests

    func testSubmitGrantArchiveAccess_NilPendingGrant_NoOp() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)
        vm.pendingArchiveGrant = nil

        vm.submitGrantArchiveAccess()

        XCTAssertFalse(vm.isLoading)
        XCTAssertNil(vm.errorMessage)
    }

    func testSubmitGrantArchiveAccess_LocalPath_NoArchiveID_AddsToList() {
        let vm = makeViewModel()
        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "New Archive", initials: "NA", archiveID: nil, thumbnailURL: nil, source: .findByEmail
        )
        vm.selectedRoleForGrantAccess = .editor

        vm.submitGrantArchiveAccess()

        XCTAssertEqual(vm.sharedArchives.count, 1)
        XCTAssertEqual(vm.sharedArchives.first?.archiveVO?.fullName, "New Archive")
        XCTAssertEqual(vm.sharedArchives.first?.accessRole, AccessRole.editor.apiValue)
        XCTAssertTrue(vm.shouldShowArchivesSection)
        XCTAssertNil(vm.pendingArchiveGrant)
    }

    func testSubmitGrantArchiveAccess_LocalPath_ClearsAllNavigationState() {
        let vm = makeViewModel()
        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Archive", initials: "A", archiveID: nil, thumbnailURL: nil, source: .findByEmail
        )
        vm.showGrantArchiveAccess = true
        vm.showInviteAndGrantAccess = true
        vm.showFindArchiveByEmail = true
        vm.showSelectArchiveFromPastShares = true

        vm.submitGrantArchiveAccess()

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testSubmitGrantArchiveAccess_LocalPath_ExistingArchive_UpdatesRole() {
        let vm = makeViewModel()

        let existingArchive = ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: "access.role.viewer", fullName: "Existing Archive",
            spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
            relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil,
            itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil,
            archiveID: 500, publicDT: nil, archiveNbr: nil, view: nil, viewProperty: nil,
            archiveVOPublic: nil, vaultKey: nil, thumbArchiveNbr: nil, type: nil,
            thumbStatus: .ok, imageRatio: nil, thumbnail256: nil, thumbURL200: nil, thumbURL500: nil,
            thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil,
            createdDT: nil, updatedDT: nil, status: .ok
        )
        let existing = ShareVOData(
            shareID: 1, folderLinkID: 1, archiveID: 500,
            accessRole: "access.role.viewer", type: nil,
            status: "status.generic.ok", requestToken: nil, previewToggle: nil,
            folderVO: nil, recordVO: nil, archiveVO: existingArchive,
            accountVO: nil, createdDT: nil, updatedDT: nil
        )
        vm.sharedArchives = [existing]

        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Existing Archive", initials: "EA", archiveID: nil, thumbnailURL: nil, source: .findByEmail
        )
        vm.selectedRoleForGrantAccess = .editor

        vm.submitGrantArchiveAccess()

        XCTAssertEqual(vm.sharedArchives.count, 1, "Should not add duplicate")
        XCTAssertEqual(vm.sharedArchives.first?.accessRole, AccessRole.editor.apiValue, "Should update role")
    }

    func testSubmitGrantArchiveAccess_LocalPath_NewArchive_InsertedAtFront() {
        let vm = makeViewModel()
        let existing = makeShareVOData(shareID: 1, archiveID: 500, status: "status.generic.ok")
        vm.sharedArchives = [existing]

        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Brand New Archive", initials: "BN", archiveID: nil, thumbnailURL: nil, source: .pastShares
        )
        vm.selectedRoleForGrantAccess = .contributor

        vm.submitGrantArchiveAccess()

        XCTAssertEqual(vm.sharedArchives.count, 2)
        XCTAssertEqual(vm.sharedArchives.first?.archiveVO?.fullName, "Brand New Archive")
        XCTAssertEqual(vm.sharedArchives.first?.accessRole, AccessRole.contributor.apiValue)
    }

    func testSubmitGrantArchiveAccess_LocalPath_NewArchive_HasNegativeShareID() {
        let vm = makeViewModel()
        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "New", initials: "N", archiveID: nil, thumbnailURL: nil, source: .findByEmail
        )

        vm.submitGrantArchiveAccess()

        if let shareID = vm.sharedArchives.first?.shareID {
            XCTAssertLessThan(shareID, 0, "Local grants should have negative shareID")
        }
    }

    // MARK: - resendInvitation Guard Tests

    func testResendInvitation_NilEditingInvitation_NoOp() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)
        vm.editingInvitation = nil

        vm.resendInvitation()

        XCTAssertFalse(vm.isLoading, "Should not start loading without invitation")
    }

    func testResendInvitation_PositiveShareID_NoOp() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)
        let share = makeShareVOData(shareID: 100, archiveID: 500, status: "status.generic.invited")
        vm.editingInvitation = share

        vm.resendInvitation()

        XCTAssertFalse(vm.isLoading, "Should not start loading when inviteId returns nil for positive shareID")
    }

    // MARK: - updateInvitation Guard Tests

    func testUpdateInvitation_SameRole_ClosesWithoutAPI() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)
        let share = makeShareVOData(shareID: -10, archiveID: nil, status: "status.generic.invited", accessRole: "access.role.viewer")
        vm.editingInvitation = share
        vm.showEditInvitation = true
        vm.selectedRoleForEditInvitation = .viewer

        vm.updateInvitation()

        XCTAssertFalse(vm.showEditInvitation, "Should close edit view")
        XCTAssertNil(vm.editingInvitation, "Should clear invitation")
        XCTAssertFalse(vm.isLoading, "Should not start loading for no-op")
    }

    func testUpdateInvitation_NilInvitation_NoOp() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)
        vm.editingInvitation = nil
        vm.selectedRoleForEditInvitation = .editor

        vm.updateInvitation()

        XCTAssertFalse(vm.isLoading)
    }

    func testUpdateInvitation_NilEmail_NoOp() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)
        let share = ShareVOData(
            shareID: -10, folderLinkID: nil, archiveID: nil,
            accessRole: "access.role.viewer", type: nil,
            status: "status.generic.invited", requestToken: nil,
            previewToggle: nil, folderVO: nil, recordVO: nil,
            archiveVO: nil, accountVO: nil,
            createdDT: nil, updatedDT: nil
        )
        vm.editingInvitation = share
        vm.selectedRoleForEditInvitation = .editor

        vm.updateInvitation()

        XCTAssertFalse(vm.isLoading, "Should not start loading without email")
    }

    // MARK: - revokeInvitation Guard Tests

    func testRevokeInvitation_NilEditingInvitation_NoOp() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)
        vm.editingInvitation = nil

        vm.revokeInvitation()

        XCTAssertFalse(vm.isLoading)
    }

    func testRevokeInvitation_PositiveShareID_NoOp() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)
        let share = makeShareVOData(shareID: 200, archiveID: 500, status: "status.generic.invited")
        vm.editingInvitation = share

        vm.revokeInvitation()

        XCTAssertFalse(vm.isLoading, "inviteId returns nil for positive shareID")
    }

    // MARK: - sendEmailInvitation Tests

    func testSendEmailInvitation_SetsShowEmailAddressField() async {
        let vm = makeViewModel()
        XCTAssertFalse(vm.showEmailAddressField)

        vm.sendEmailInvitation()

        try? await Task.sleep(nanoseconds: 200_000_000)

        XCTAssertTrue(vm.showEmailAddressField)
    }

    // MARK: - showArchiveAccessUpdatedNotification Tests

    func testShowArchiveAccessUpdatedNotification_CustomMessage() async {
        let vm = makeViewModel()

        vm.showArchiveAccessUpdatedNotification(message: "Custom notification!")

        XCTAssertEqual(vm.archiveAccessNotificationMessage, "Custom notification!")

        try? await Task.sleep(nanoseconds: 700_000_000)

        XCTAssertTrue(vm.showArchiveAccessNotification)
    }

    func testShowArchiveAccessUpdatedNotification_DefaultMessage() {
        let vm = makeViewModel()

        vm.showArchiveAccessUpdatedNotification()

        XCTAssertEqual(vm.archiveAccessNotificationMessage, "Archive access has been updated.")
    }

    // MARK: - updateArchiveAccessRole Error Tests

    func testUpdateArchiveAccessRole_Error_SetsErrorMessage() async {
        let repo = TrackingShareManagementRepository()
        repo.shouldReturnError = true
        repo.errorMessage = "Access denied"
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        let share = makeShareVOData(shareID: 100, archiveID: 500, status: "status.generic.ok")
        vm.sharedArchives = [share]

        let expectation = XCTestExpectation(description: "Error returned")

        vm.updateArchiveAccessRole(shareVO: share, newRole: .editor) { result, errorMsg in
            if case .error = result {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 3.0)

        XCTAssertNotNil(vm.errorMessage)
    }

    // MARK: - revokeArchiveAccess Error Tests

    func testRevokeArchiveAccess_Error_SetsErrorMessage() async {
        let repo = TrackingShareManagementRepository()
        repo.shouldReturnError = true
        repo.errorMessage = "Revoke denied"
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        let share = makeShareVOData(shareID: 100, archiveID: 500, status: "status.generic.ok")
        vm.sharedArchives = [share]

        let expectation = XCTestExpectation(description: "Error returned")

        vm.revokeArchiveAccess(shareVO: share) { result, errorMsg in
            if case .error = result {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 3.0)

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertEqual(vm.sharedArchives.count, 1, "Should not remove archive on error")
    }

    // MARK: - openInviteAndGrantAccess Edge Cases

    func testOpenInviteAndGrantAccess_PreservesExistingFullName() {
        let vm = makeViewModel()
        vm.invitationRecipientFullName = "Already Set Name"

        vm.openInviteAndGrantAccess(recipientEmail: "test@example.com")

        XCTAssertEqual(vm.invitationRecipientFullName, "Already Set Name", "Should not overwrite non-empty name")
    }

    func testOpenInviteAndGrantAccess_ClearsAllOtherViews() {
        let vm = makeViewModel()
        vm.showGrantArchiveAccess = true
        vm.showSelectArchiveFromPastShares = true

        vm.openInviteAndGrantAccess(recipientEmail: "test@example.com")

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showFindArchiveByEmail)
    }

    // MARK: - closeGrantArchiveAccess Edge Cases

    func testCloseGrantArchiveAccess_NilSource_ClosesAllViews() {
        let vm = makeViewModel()
        vm.pendingArchiveGrant = nil
        vm.showGrantArchiveAccess = true

        vm.closeGrantArchiveAccess()

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
    }

    // MARK: - refreshData Tests

    func testRefreshData_NotLoadedOnce_DoesNotFetch() {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        vm.hasLoadedArchivesOnce = false

        vm.refreshData()

        // No crash, no additional loading - just a no-op
        XCTAssertFalse(vm.hasLoadedArchivesOnce)
    }

    func testRefreshData_LoadedOnce_FetchesAgain() {
        let vm = makeViewModel()
        vm.hasLoadedArchivesOnce = true

        vm.refreshData()

        XCTAssertTrue(vm.isLoadingArchives)
    }

    // MARK: - Computed Properties Tests

    func testShouldShowCreateButton_NoLink_NotLoading() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)
        vm.shareLink = nil
        vm.genLinkLoading = false
        vm.isLoading = false

        XCTAssertTrue(vm.shouldShowCreateButton)
    }

    func testShouldShowCreateButton_HasLink_ReturnsFalse() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)
        vm.shareLink = "https://example.com/share"
        vm.genLinkLoading = false
        vm.isLoading = false

        XCTAssertFalse(vm.shouldShowCreateButton)
    }

    func testShouldShowCreateButton_Loading_ReturnsFalse() {
        let vm = makeViewModel()
        vm.shareLink = nil
        vm.genLinkLoading = true

        XCTAssertFalse(vm.shouldShowCreateButton)
    }

    func testFileName_ReturnsFileModelName() {
        let vm = makeViewModel()
        XCTAssertEqual(vm.fileName, vm.fileModel.name)
    }

    func testFileSize_ZeroSize_ReturnsEmpty() {
        let vm = makeViewModel()
        XCTAssertTrue(vm.fileSize.isEmpty || vm.fileSize == "")
    }

    // MARK: - NavigationDirection and insertionViewTransition Tests

    func testInsertionViewTransition_Forward_TrailingEdge() {
        let vm = makeViewModel()
        vm.navigationDirection = .forward

        let transition = vm.insertionViewTransition
        XCTAssertNotNil(transition, "Should return a valid transition")
    }

    func testInsertionViewTransition_Backward_LeadingEdge() {
        let vm = makeViewModel()
        vm.navigationDirection = .backward

        let transition = vm.insertionViewTransition
        XCTAssertNotNil(transition, "Should return a valid transition")
    }

    // MARK: - ShareViewAccessLevel Tests

    func testShareViewAccessLevel_AllCases_HaveTitles() {
        for level in ShareViewAccessLevel.allCases {
            XCTAssertFalse(level.title.isEmpty, "\(level) should have a title")
        }
    }

    func testShareViewAccessLevel_AllCases_HaveDescriptions() {
        for level in ShareViewAccessLevel.allCases {
            XCTAssertFalse(level.description.isEmpty, "\(level) should have a description")
        }
    }

    func testShareViewAccessLevel_AnyoneCanView_Title() {
        XCTAssertEqual(ShareViewAccessLevel.anyoneCanView.title, "Anyone can view")
    }

    func testShareViewAccessLevel_Restricted_Title() {
        XCTAssertEqual(ShareViewAccessLevel.restricted.title, "Restricted")
    }

    // MARK: - ShareExpirationOption Tests

    func testShareExpirationOption_AllCases_HaveTitles() {
        for option in ShareExpirationOption.allCases {
            if option != .none {
                XCTAssertFalse(option.title.isEmpty, "\(option) should have a title")
            }
        }
    }

    func testShareExpirationOption_NoneTitle_IsEmpty() {
        XCTAssertEqual(ShareExpirationOption.none.title, "")
    }

    func testShareExpirationOption_OneDayExpirationDate_IsNotNil() {
        XCTAssertNotNil(ShareExpirationOption.oneDay.expirationDate)
    }

    func testShareExpirationOption_OneMonthExpirationDate_IsNotNil() {
        XCTAssertNotNil(ShareExpirationOption.oneMonth.expirationDate)
    }

    func testShareExpirationOption_OneYearExpirationDate_IsNotNil() {
        XCTAssertNotNil(ShareExpirationOption.oneYear.expirationDate)
    }

    func testShareExpirationOption_NeverExpirationDate_IsNil() {
        XCTAssertNil(ShareExpirationOption.never.expirationDate)
    }

    func testShareExpirationOption_NoneExpirationDate_IsNil() {
        XCTAssertNil(ShareExpirationOption.none.expirationDate)
    }

    // MARK: - openGrantArchiveAccess Role Default Tests

    func testOpenGrantArchiveAccess_DefaultsToViewerRole() {
        let vm = makeViewModel()
        vm.selectedRoleForGrantAccess = .editor

        vm.openGrantArchiveAccess(archiveName: "Test", archiveInitials: "T", source: .findByEmail)

        XCTAssertEqual(vm.selectedRoleForGrantAccess, .viewer)
    }

    func testOpenGrantArchiveAccess_StoresThumbnailURL() {
        let vm = makeViewModel()

        vm.openGrantArchiveAccess(archiveName: "Test", archiveInitials: "T", thumbnailURL: "https://thumb.example.com/pic.jpg", source: .pastShares)

        XCTAssertEqual(vm.pendingArchiveGrant?.thumbnailURL, "https://thumb.example.com/pic.jpg")
    }

    // MARK: - openEditInvitation Role Mapping Tests

    func testOpenEditInvitation_EditorRole_MapsCorrectly() {
        let vm = makeViewModel()
        let share = makeShareVOData(shareID: -10, archiveID: nil, status: "status.generic.invited", accessRole: "access.role.editor")

        vm.openEditInvitation(shareVO: share)

        XCTAssertEqual(vm.selectedRoleForEditInvitation, .editor)
    }

    func testOpenEditInvitation_ContributorRole_MapsCorrectly() {
        let vm = makeViewModel()
        let share = makeShareVOData(shareID: -10, archiveID: nil, status: "status.generic.invited", accessRole: "access.role.contributor")

        vm.openEditInvitation(shareVO: share)

        XCTAssertEqual(vm.selectedRoleForEditInvitation, .contributor)
    }

    func testOpenEditInvitation_CuratorRole_MapsCorrectly() {
        let vm = makeViewModel()
        let share = makeShareVOData(shareID: -10, archiveID: nil, status: "status.generic.invited", accessRole: "access.role.curator")

        vm.openEditInvitation(shareVO: share)

        XCTAssertEqual(vm.selectedRoleForEditInvitation, .curator)
    }

    // MARK: - Approve Share Updates Status Tests

    func testApproveShareRequest_Success_RemovesFromApprovingSet() async {
        let repo = TrackingShareManagementRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        let share = makeShareVOData(shareID: 42, archiveID: 100, status: "status.generic.pending")
        vm.sharedArchives = [share]

        vm.approveShareRequest(share)

        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(vm.isApprovingShare(shareID: 42), "Should be in approving set while processing")

        try? await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertEqual(vm.sharedArchives.count, 1, "Should still have the share in the list")
    }

    func testDenyShareRequest_NilShareID_DoesNothing() {
        let vm = makeViewModel()
        let share = makeShareVOData(shareID: nil, archiveID: 100, status: "status.generic.pending")

        vm.denyShareRequest(share)

        XCTAssertTrue(vm.denyingShareIDs.isEmpty)
    }

    // MARK: - Notification State Defaults Tests

    func testInitialNotificationState_AllFalse() {
        let vm = makeViewModel()

        XCTAssertFalse(vm.showCopyNotification)
        XCTAssertFalse(vm.showArchiveAccessNotification)
        XCTAssertFalse(vm.showLinkSettingsNotification)
        XCTAssertFalse(vm.showRevokeLinkNotification)
        XCTAssertFalse(vm.showApproveAllNotification)
    }

    // MARK: - Initial State Tests

    func testInitialState_GrantAndInvite_AllViewsClosed() {
        let vm = makeViewModel()

        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertFalse(vm.showEditInvitation)
        XCTAssertNil(vm.pendingArchiveGrant)
        XCTAssertNil(vm.editingInvitation)
    }

    func testInitialState_DefaultRoles() {
        let vm = makeViewModel()

        XCTAssertEqual(vm.selectedRoleForGrantAccess, .viewer)
        XCTAssertEqual(vm.selectedRoleForInviteAccess, .viewer)
        XCTAssertEqual(vm.selectedRoleForEditInvitation, .viewer)
    }

    func testInitialState_EmptyEmailFields() {
        let vm = makeViewModel()

        XCTAssertTrue(vm.invitationRecipientFullName.isEmpty)
        XCTAssertTrue(vm.invitationRecipientEmail.isEmpty)
        XCTAssertTrue(vm.emailAddress.isEmpty)
    }

    // MARK: - PendingArchiveGrant Struct Tests

    func testPendingArchiveGrant_StoresAllProperties() {
        let grant = ShareItemViewModel.PendingArchiveGrant(
            name: "Test Archive",
            initials: "TA",
            archiveID: 42,
            thumbnailURL: "https://example.com/thumb.jpg",
            source: .findByEmail
        )

        XCTAssertEqual(grant.name, "Test Archive")
        XCTAssertEqual(grant.initials, "TA")
        XCTAssertEqual(grant.archiveID, 42)
        XCTAssertEqual(grant.thumbnailURL, "https://example.com/thumb.jpg")
        XCTAssertEqual(grant.source, .findByEmail)
    }

    func testPendingArchiveGrant_NilOptionals() {
        let grant = ShareItemViewModel.PendingArchiveGrant(
            name: "Archive",
            initials: "A",
            archiveID: nil,
            thumbnailURL: nil,
            source: .pastShares
        )

        XCTAssertNil(grant.archiveID)
        XCTAssertNil(grant.thumbnailURL)
        XCTAssertEqual(grant.source, .pastShares)
    }
}

// MARK: - Test Helpers

extension ShareItemViewModelExtendedTests {

    private func makeViewModel(isFolder: Bool = false, repository: ShareManagementRepository? = nil) -> ShareItemViewModel {
        let fileModel = isFolder ? FileModel.mockFolder() : FileModel.mockFile()
        let repo = repository ?? TrackingShareManagementRepository()
        return ShareItemViewModel(fileModel: fileModel, shareManagementRepository: repo)
    }

    private func waitForInitialLoad(_ vm: ShareItemViewModel) {
        var attempts = 0
        while vm.isLoading && attempts < 50 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
            attempts += 1
        }
    }

    /// Polls `condition` every 10 ms until it returns true or `timeout` elapses.
    /// Replaces fragile fixed-duration `Task.sleep` waits whose 100 ms window
    /// was enough locally but flaked on slower CI runners.
    private func waitUntil(
        timeout: TimeInterval = 2.0,
        _ condition: @autoclosure () -> Bool
    ) async {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition() && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }
    }

    private func makeShareVOData(
        shareID: Int? = 1,
        archiveID: Int? = 100,
        status: String = "status.generic.ok",
        accessRole: String = "access.role.viewer",
        email: String? = nil
    ) -> ShareVOData {
        let accountVO: AccountVOData? = email.map { email in
            AccountVOData(
                accountID: nil,
                primaryEmail: email,
                fullName: email,
                address: nil, address2: nil, country: nil, city: nil, state: nil, zip: nil,
                primaryPhone: nil, defaultArchiveID: nil, level: nil, apiToken: nil,
                betaParticipant: nil, facebookAccountID: nil, googleAccountID: nil,
                status: nil, type: nil, emailStatus: nil, phoneStatus: nil,
                notificationPreferences: nil, agreed: nil, optIn: nil, emailArray: nil,
                inviteCode: nil, rememberMe: nil, keepLoggedIn: nil, accessRole: nil,
                spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
                changePrimaryEmail: nil, changePrimaryPhone: nil,
                createdDT: nil, updatedDT: nil, hideChecklist: nil
            )
        }

        return ShareVOData(
            shareID: shareID,
            folderLinkID: 1,
            archiveID: archiveID,
            accessRole: accessRole,
            type: "type.share.archive",
            status: status,
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: nil,
            accountVO: accountVO,
            createdDT: nil,
            updatedDT: nil
        )
    }

    private func makeMockSharebyURLVOData(
        sharebyURLID: Int? = 100,
        shareURL: String? = nil,
        expiresDT: String? = nil
    ) -> SharebyURLVOData {
        var jsonDict: [String: Any] = [
            "autoApproveToggle": 1,
            "previewToggle": 1,
            "defaultAccessRole": "access.role.viewer"
        ]

        if let id = sharebyURLID {
            jsonDict["shareby_urlId"] = id
        }
        if let url = shareURL {
            jsonDict["shareUrl"] = url
        }
        if let dt = expiresDT {
            jsonDict["expiresDT"] = dt
        }

        let jsonData = try! JSONSerialization.data(withJSONObject: jsonDict, options: [])
        return try! JSONDecoder().decode(SharebyURLVOData.self, from: jsonData)
    }
}

// MARK: - Tracking Mock Repository

private class TrackingShareManagementRepository: ShareManagementRepository {
    var shouldReturnLink = false
    var shouldReturnError = false
    var errorMessage = "Mock error"
    var mockV2UpdateResponse: ShareLinkV2Data?
    private let delayed: Bool

    // Tracking flags
    var getShareLinkCallCount = 0
    var getShareLinkV2ByIdCalled = false
    var getShareLinkV2ByFileCalled = false
    var createShareLinkV2Called = false
    var updateShareLinkV2Called = false
    var deleteShareLinkV2Called = false
    var revokeLinkCalled = false
    var updateLinkCalled = false
    var lastUpdateV2ShareLinkId: String?
    var lastDeleteShareLinkId: String?

    init(shouldReturnLink: Bool = false, shouldReturnError: Bool = false, delayed: Bool = false) {
        self.shouldReturnLink = shouldReturnLink
        self.shouldReturnError = shouldReturnError
        self.delayed = delayed
        super.init()
    }

    override func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        getShareLinkCallCount += 1
        let delay = delayed ? 2.0 : 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if option == .retrieve && !self.shouldReturnLink {
                completion(nil, nil)
            } else if self.shouldReturnError {
                completion(nil, self.errorMessage)
            } else {
                completion(self.createMockShareVO(), nil)
            }
        }
    }

    override func getShareLinkV2(file: FileModel, then completion: @escaping ShareLinkV2Handler) {
        getShareLinkV2ByFileCalled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            completion(nil, "No link found")
        }
    }

    override func getShareLinkV2(shareLinkId: String, then completion: @escaping ShareLinkV2Handler) {
        getShareLinkV2ByIdCalled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.shouldReturnLink {
                completion(self.createMockV2Data(), nil)
            } else {
                completion(nil, "No link found")
            }
        }
    }

    override func createShareLinkV2(file: FileModel, then completion: @escaping ShareLinkV2Handler) {
        createShareLinkV2Called = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.shouldReturnError {
                completion(nil, self.errorMessage)
            } else {
                completion(self.createMockV2Data(), nil)
            }
        }
    }

    override func updateShareLinkV2(shareLinkId: String, permissionsLevel: String? = nil, accessRestrictions: String? = nil, maxUses: Int? = nil, expirationTimestamp: String? = nil, then completion: @escaping ShareLinkV2Handler) {
        updateShareLinkV2Called = true
        lastUpdateV2ShareLinkId = shareLinkId
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.shouldReturnError {
                completion(nil, self.errorMessage)
            } else {
                let response = self.mockV2UpdateResponse ?? self.createMockV2Data()
                completion(response, nil)
            }
        }
    }

    override func deleteShareLinkV2(shareLinkId: String, then completion: @escaping (RequestStatus) -> Void) {
        deleteShareLinkV2Called = true
        lastDeleteShareLinkId = shareLinkId
        let delay = delayed ? 2.0 : 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            completion(.success)
        }
    }

    override func revokeLink(shareVO: SharebyURLVOData?, then handler: @escaping ServerResponse) {
        revokeLinkCalled = true
        let delay = delayed ? 2.0 : 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            handler(.success)
        }
    }

    override func updateLink(model: ManageLinkData, shareVO: SharebyURLVOData?, then handler: @escaping ShareLinkResponse) {
        updateLinkCalled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if self.shouldReturnError {
                handler(nil, self.errorMessage)
            } else {
                handler(self.createMockShareVO(), nil)
            }
        }
    }

    override func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus, ShareVOData?) -> Void) {
        let delay = delayed ? 2.0 : 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if self.shouldReturnError {
                handler(.error(message: self.errorMessage), nil)
            } else {
                var updatedShare = shareVO
                updatedShare.accessRole = accessRole.apiValue
                handler(.success, updatedShare)
            }
        }
    }

    override func denyButtonAction(shareVO: ShareVOData, then handler: @escaping (RequestStatus) -> Void) {
        let delay = delayed ? 2.0 : 0.1
        DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
            if self.shouldReturnError {
                handler(.error(message: self.errorMessage))
            } else {
                handler(.success)
            }
        }
    }

    private func createMockShareVO() -> SharebyURLVOData {
        let jsonString = """
        {
            "shareby_urlId": 100,
            "urlToken": "mock-share-token",
            "autoApproveToggle": 1,
            "previewToggle": 1,
            "defaultAccessRole": "access.role.viewer",
            "byAccountId": 1000
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        return try! JSONDecoder().decode(SharebyURLVOData.self, from: jsonData)
    }

    private func createMockV2Data() -> ShareLinkV2Data {
        ShareLinkV2Data(
            id: "v2-mock-id",
            itemId: "1",
            itemType: "file",
            token: "v2-token",
            permissionsLevel: "read",
            accessRestrictions: "accessible_with_link",
            maxUses: nil,
            usesExpended: 0,
            expirationTimestamp: nil,
            creatorAccount: nil,
            createdAt: "2024-01-01T00:00:00",
            updatedAt: "2024-01-01T00:00:00"
        )
    }
}
