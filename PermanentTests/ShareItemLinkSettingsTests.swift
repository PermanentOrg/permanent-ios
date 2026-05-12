//
//  ShareItemLinkSettingsTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.

import XCTest
@testable import Permanent

@MainActor
final class ShareItemLinkSettingsTests: XCTestCase {

    // MARK: - Helpers

    private func makeViewModel() -> ShareItemViewModel {
        let fileModel = FileModel.mockFile()
        return ShareItemViewModel(
            fileModel: fileModel,
            shareManagementRepository: StubShareManagementRepository()
        )
    }

    private func makeShareVO(expiresDT: String? = nil) -> SharebyURLVOData {
        var fields: [String] = [
            "\"shareby_urlId\": 100",
            "\"urlToken\": \"mock-share-token\"",
            "\"autoApproveToggle\": 1",
            "\"previewToggle\": 1",
            "\"defaultAccessRole\": \"access.role.viewer\"",
            "\"byAccountId\": 1000"
        ]
        if let expiresDT = expiresDT {
            fields.append("\"expiresDT\": \"\(expiresDT)\"")
        }
        let jsonString = "{ \(fields.joined(separator: ", ")) }"
        let jsonData = jsonString.data(using: .utf8)!
        return try! JSONDecoder().decode(SharebyURLVOData.self, from: jsonData)
    }

    private func makeV2Data(
        permissionsLevel: String? = "viewer",
        accessRestrictions: String? = "none"
    ) -> ShareLinkV2Data {
        ShareLinkV2Data(
            id: "v2-id",
            itemId: "1",
            itemType: "file",
            token: "token",
            permissionsLevel: permissionsLevel,
            accessRestrictions: accessRestrictions,
            maxUses: nil,
            usesExpended: 0,
            expirationTimestamp: nil,
            creatorAccount: nil,
            createdAt: "2024-01-01T00:00:00",
            updatedAt: "2024-01-01T00:00:00"
        )
    }

    private func iso8601String(byAdding component: Calendar.Component, value: Int, to date: Date = Date()) -> String {
        let calendar = Calendar.current
        let futureDate = calendar.date(byAdding: component, value: value, to: date)!
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter.string(from: futureDate)
    }

    // MARK: - setSelectedExpirationFromShareVO Tests

    func testSetSelectedExpirationFromShareVO_NilExpiresDT_SetsNever() {
        let vm = makeViewModel()
        let shareVO = makeShareVO(expiresDT: nil)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .never, "Nil expiresDT should map to .never")
        XCTAssertEqual(vm.originalExpiration, .never, "Original expiration should also be .never")
    }

    func testSetSelectedExpirationFromShareVO_EmptyExpiresDT_SetsNever() {
        let vm = makeViewModel()

        let jsonString = """
        {
            "shareby_urlId": 100,
            "urlToken": "mock-share-token",
            "expiresDT": "",
            "autoApproveToggle": 1,
            "previewToggle": 1,
            "defaultAccessRole": "access.role.viewer",
            "byAccountId": 1000
        }
        """
        let jsonData = jsonString.data(using: .utf8)!
        let shareVO = try! JSONDecoder().decode(SharebyURLVOData.self, from: jsonData)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .never, "Empty expiresDT should map to .never")
        XCTAssertEqual(vm.originalExpiration, .never, "Original expiration should also be .never")
    }

    func testSetSelectedExpirationFromShareVO_OneDayFromNow_SetsOneDay() {
        let vm = makeViewModel()
        let expirationString = iso8601String(byAdding: .hour, value: 24)
        let shareVO = makeShareVO(expiresDT: expirationString)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .oneDay, "~24 hours from now should map to .oneDay")
        XCTAssertEqual(vm.originalExpiration, .oneDay)
    }

    func testSetSelectedExpirationFromShareVO_OneMonthFromNow_SetsOneMonth() {
        let vm = makeViewModel()
        let expirationString = iso8601String(byAdding: .day, value: 30)
        let shareVO = makeShareVO(expiresDT: expirationString)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .oneMonth, "~30 days from now should map to .oneMonth")
        XCTAssertEqual(vm.originalExpiration, .oneMonth)
    }

    func testSetSelectedExpirationFromShareVO_OneYearFromNow_SetsOneYear() {
        let vm = makeViewModel()
        let expirationString = iso8601String(byAdding: .day, value: 365)
        let shareVO = makeShareVO(expiresDT: expirationString)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .oneYear, "~365 days from now should map to .oneYear")
        XCTAssertEqual(vm.originalExpiration, .oneYear)
    }

    func testSetSelectedExpirationFromShareVO_NonMatchingInterval_SetsNone() {
        let vm = makeViewModel()
        // 90 days does not fall in any bucket (1 day, 1 month, 1 year)
        let expirationString = iso8601String(byAdding: .day, value: 90)
        let shareVO = makeShareVO(expiresDT: expirationString)

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .none, "Non-matching interval should map to .none")
        XCTAssertEqual(vm.originalExpiration, .none)
    }

    func testSetSelectedExpirationFromShareVO_UnparseableDate_SetsNone() {
        let vm = makeViewModel()
        let shareVO = makeShareVO(expiresDT: "not-a-date")

        vm.setSelectedExpirationFromShareVO(shareVO)

        XCTAssertEqual(vm.selectedExpiration, .none, "Unparseable date should map to .none")
        XCTAssertEqual(vm.originalExpiration, .none)
    }

    // MARK: - setAccessLevelFromV2Data Tests

    func testSetAccessLevelFromV2Data_AccessRestrictionsNone_SetsAnyoneCanViewAndViewer() {
        let vm = makeViewModel()
        let v2Data = makeV2Data(permissionsLevel: "editor", accessRestrictions: "none")

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessLevel, .anyoneCanView, "accessRestrictions 'none' should map to anyoneCanView")
        XCTAssertEqual(vm.selectedAccessRole, .viewer, "accessRestrictions 'none' forces viewer role regardless of permissionsLevel")
        XCTAssertEqual(vm.originalAccessLevel, .anyoneCanView)
        XCTAssertEqual(vm.originalAccessRole, .viewer)
    }

    func testSetAccessLevelFromV2Data_AccessRestrictionsApproval_SetsRestricted() {
        let vm = makeViewModel()
        let v2Data = makeV2Data(permissionsLevel: "editor", accessRestrictions: "approval")

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessLevel, .restricted, "accessRestrictions 'approval' should map to restricted")
        XCTAssertEqual(vm.originalAccessLevel, .restricted)
        XCTAssertEqual(vm.selectedAccessRole, .editor, "Should use the permissionsLevel for non-none accessRestrictions")
        XCTAssertEqual(vm.originalAccessRole, .editor)
    }

    func testSetAccessLevelFromV2Data_AccessRestrictionsAccount_SetsRestricted() {
        let vm = makeViewModel()
        let v2Data = makeV2Data(permissionsLevel: "viewer", accessRestrictions: "account")

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessLevel, .restricted, "accessRestrictions 'account' should map to restricted")
        XCTAssertEqual(vm.originalAccessLevel, .restricted)
    }

    func testSetAccessLevelFromV2Data_NilAccessRestrictions_DefaultsToAnyoneCanViewAndViewer() {
        let vm = makeViewModel()
        let v2Data = makeV2Data(permissionsLevel: "editor", accessRestrictions: nil)

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessLevel, .anyoneCanView, "nil accessRestrictions should default to anyoneCanView")
        XCTAssertEqual(vm.selectedAccessRole, .viewer, "nil accessRestrictions should default to viewer role")
        XCTAssertEqual(vm.originalAccessLevel, .anyoneCanView)
        XCTAssertEqual(vm.originalAccessRole, .viewer)
    }

    func testSetAccessLevelFromV2Data_PermissionsLevelEditor_SetsEditorRole() {
        let vm = makeViewModel()
        let v2Data = makeV2Data(permissionsLevel: "editor", accessRestrictions: "approval")

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessRole, .editor, "permissionsLevel 'editor' should map to .editor role")
    }

    func testSetAccessLevelFromV2Data_PermissionsLevelManager_SetsCuratorRole() {
        let vm = makeViewModel()
        let v2Data = makeV2Data(permissionsLevel: "manager", accessRestrictions: "approval")

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessRole, .curator, "Backend 'manager' permissionsLevel should map to .curator role in the UI")
        XCTAssertEqual(vm.originalAccessRole, .curator)
    }

    func testSetAccessLevelFromV2Data_PermissionsLevelContributor_SetsContributorRole() {
        let vm = makeViewModel()
        let v2Data = makeV2Data(permissionsLevel: "contributor", accessRestrictions: "approval")

        vm.setAccessLevelFromV2Data(v2Data)

        XCTAssertEqual(vm.selectedAccessRole, .contributor, "permissionsLevel 'contributor' should map to .contributor role")
    }

    // MARK: - updateAccessLevel Tests

    func testUpdateAccessLevel_AnyoneCanView_AutoSetsViewerRole() {
        let vm = makeViewModel()

        // First set to restricted with editor role
        vm.selectedAccessRole = .editor
        vm.updateAccessLevel(.restricted)
        XCTAssertEqual(vm.selectedAccessRole, .editor, "Restricted should keep editor role")

        // Switch to anyoneCanView - should auto-set viewer role
        vm.updateAccessLevel(.anyoneCanView)

        XCTAssertEqual(vm.selectedAccessLevel, .anyoneCanView)
        XCTAssertEqual(vm.selectedAccessRole, .viewer, "Switching to anyoneCanView should auto-set viewer role")
    }

    func testUpdateAccessLevel_Restricted_KeepsCurrentRole() {
        let vm = makeViewModel()

        vm.selectedAccessRole = .editor
        vm.updateAccessLevel(.restricted)

        XCTAssertEqual(vm.selectedAccessLevel, .restricted)
        XCTAssertEqual(vm.selectedAccessRole, .editor, "Restricted should not change the current role")
    }

    func testUpdateAccessLevel_SetsNavigationBackward() {
        let vm = makeViewModel()

        vm.navigationDirection = .forward
        vm.updateAccessLevel(.restricted)

        XCTAssertEqual(vm.navigationDirection, .backward, "updateAccessLevel should set navigation to backward")
        XCTAssertFalse(vm.showGeneralAccess, "updateAccessLevel should dismiss general access view")
    }

    // MARK: - revertChanges Tests

    func testRevertChanges_RestoresAllOriginalValues() {
        let vm = makeViewModel()

        // Set original values via V2 data
        let v2Data = makeV2Data(permissionsLevel: "editor", accessRestrictions: "approval")
        vm.setAccessLevelFromV2Data(v2Data)
        vm.originalExpiration = .oneMonth
        vm.selectedExpiration = .oneMonth

        // Capture originals
        let origExpiration = vm.originalExpiration
        let origAccessLevel = vm.originalAccessLevel
        let origAccessRole = vm.originalAccessRole

        // Make changes
        vm.updateExpiration(.oneYear)
        vm.updateAccessLevel(.anyoneCanView)
        XCTAssertTrue(vm.hasUnsavedChanges, "Should have unsaved changes after modifications")

        // Revert
        vm.revertChanges()

        XCTAssertEqual(vm.selectedExpiration, origExpiration, "Expiration should revert to original")
        XCTAssertEqual(vm.selectedAccessLevel, origAccessLevel, "Access level should revert to original")
        XCTAssertEqual(vm.selectedAccessRole, origAccessRole, "Access role should revert to original")
        XCTAssertFalse(vm.hasUnsavedChanges, "hasUnsavedChanges should be false after revert")
    }

    func testRevertChanges_WithNoChanges_RemainsUnchanged() {
        let vm = makeViewModel()
        let v2Data = makeV2Data(permissionsLevel: "viewer", accessRestrictions: "none")
        vm.setAccessLevelFromV2Data(v2Data)

        // Revert without making changes
        vm.revertChanges()

        XCTAssertEqual(vm.selectedAccessLevel, .anyoneCanView)
        XCTAssertEqual(vm.selectedAccessRole, .viewer)
        XCTAssertFalse(vm.hasUnsavedChanges)
    }

    // MARK: - expirationDisplayText Tests

    func testExpirationDisplayText_Never_ShowsNeverExpire() {
        let vm = makeViewModel()
        vm.selectedExpiration = .never

        XCTAssertEqual(vm.expirationDisplayText, "The link will never expire.", "Should show never expire text for .never")
    }

    func testExpirationDisplayText_None_ShowsNeverExpire() {
        let vm = makeViewModel()
        vm.selectedExpiration = .none

        XCTAssertEqual(vm.expirationDisplayText, "The link will never expire.", "Should show never expire text for .none")
    }

    func testExpirationDisplayText_OneMonth_ShowsFormattedDate() {
        let vm = makeViewModel()
        vm.selectedExpiration = .oneMonth

        let displayText = vm.expirationDisplayText
        XCTAssertTrue(displayText.hasPrefix("The link will expire on "), "Should start with expected prefix")
        XCTAssertTrue(displayText.hasSuffix("."), "Should end with a period")
        XCTAssertFalse(displayText.contains("never"), "Should not contain 'never' for a set expiration")
    }

    func testExpirationDisplayText_OneDay_ContainsFormattedDate() {
        let vm = makeViewModel()
        vm.selectedExpiration = .oneDay

        let displayText = vm.expirationDisplayText
        XCTAssertTrue(displayText.contains("expire on"), "Should contain formatted expiration date")
    }

    func testExpirationDisplayText_OneYear_ContainsFormattedDate() {
        let vm = makeViewModel()
        vm.selectedExpiration = .oneYear

        let displayText = vm.expirationDisplayText

        // Verify the year portion includes next year
        let calendar = Calendar.current
        let nextYear = calendar.component(.year, from: calendar.date(byAdding: .year, value: 1, to: Date())!)
        XCTAssertTrue(displayText.contains(String(nextYear)), "One year expiration display should reference next year")
    }

    // MARK: - checkForUnsavedChanges (via update methods) Tests

    func testUpdateExpiration_MarksUnsavedChanges() {
        let vm = makeViewModel()
        vm.originalExpiration = .never
        vm.selectedExpiration = .never

        vm.updateExpiration(.oneDay)

        XCTAssertTrue(vm.hasUnsavedChanges, "Changing expiration from original should mark unsaved changes")
    }

    func testUpdateExpiration_BackToOriginal_ClearsUnsavedChanges() {
        let vm = makeViewModel()
        vm.originalExpiration = .never
        vm.selectedExpiration = .never

        vm.updateExpiration(.oneDay)
        XCTAssertTrue(vm.hasUnsavedChanges)

        vm.updateExpiration(.never)
        XCTAssertFalse(vm.hasUnsavedChanges, "Returning to original value should clear unsaved changes")
    }

    func testToggleItemPreview_MarksUnsavedChanges() {
        let vm = makeViewModel()
        vm.originalItemPreview = false
        vm.itemPreviewEnabled = false

        vm.toggleItemPreview()

        XCTAssertTrue(vm.hasUnsavedChanges, "Toggling preview should mark unsaved changes")
    }

    func testToggleAutoApprove_MarksUnsavedChanges() {
        let vm = makeViewModel()
        vm.originalAutoApprove = false
        vm.autoApproveEnabled = false

        vm.toggleAutoApprove()

        XCTAssertTrue(vm.hasUnsavedChanges, "Toggling auto approve should mark unsaved changes")
    }
}

// MARK: - Stub Repository

private class StubShareManagementRepository: ShareManagementRepository {
    override func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        completion(nil, nil)
    }
}
