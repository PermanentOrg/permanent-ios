//
//  ShareItemGrantAndInviteViewModelTests.swift
//  PermanentTests
//
//  Created by Sergiu Tarnovan on 06.05.2026.

import XCTest
import Combine
@testable import Permanent

// VSP-1688 // REQ-SHARE-001

@MainActor
final class ShareItemGrantAndInviteViewModelTests: XCTestCase {

    // MARK: - Find Archive by Email Flow

    func testOpenFindArchiveByEmail_SetsCorrectNavigationState() {
        let vm = makeViewModel()
        vm.showInviteAndGrantAccess = true
        vm.showGrantArchiveAccess = true
        vm.showSelectArchiveFromPastShares = true

        vm.openFindArchiveByEmail()

        XCTAssertTrue(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.navigationDirection, .forward)
    }

    func testCloseFindArchiveByEmail_ClearsNavigationState() {
        let vm = makeViewModel()
        vm.showFindArchiveByEmail = true
        vm.showSelectArchiveFromPastShares = true

        vm.closeFindArchiveByEmail()

        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    // MARK: - Select Archive from Past Shares Flow

    func testOpenSelectArchiveFromPastShares_SetsCorrectState() {
        let vm = makeViewModel()
        vm.showFindArchiveByEmail = true

        vm.openSelectArchiveFromPastShares()

        XCTAssertTrue(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertEqual(vm.navigationDirection, .forward)
    }

    func testCloseSelectArchiveFromPastShares_ClearsState() {
        let vm = makeViewModel()
        vm.showSelectArchiveFromPastShares = true
        vm.showFindArchiveByEmail = true

        vm.closeSelectArchiveFromPastShares()

        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    // MARK: - Grant Archive Access Flow

    func testOpenGrantArchiveAccess_CreatesPendingGrantAndResetsRoleToViewer() {
        let vm = makeViewModel()
        vm.selectedRoleForGrantAccess = .editor

        vm.openGrantArchiveAccess(
            archiveName: "Test Archive",
            archiveInitials: "TA",
            archiveID: 123,
            thumbnailURL: nil,
            source: .findByEmail
        )

        XCTAssertTrue(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.selectedRoleForGrantAccess, .viewer)
        XCTAssertEqual(vm.navigationDirection, .forward)
        XCTAssertEqual(vm.pendingArchiveGrant?.name, "Test Archive")
        XCTAssertEqual(vm.pendingArchiveGrant?.initials, "TA")
        XCTAssertEqual(vm.pendingArchiveGrant?.archiveID, 123)
    }

    func testCloseGrantArchiveAccess_FromFindByEmail_RestoresFindByEmailScreen() {
        let vm = makeViewModel()
        vm.openGrantArchiveAccess(archiveName: "Archive", archiveInitials: "A", archiveID: nil, thumbnailURL: nil, source: .findByEmail)

        vm.closeGrantArchiveAccess()

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertTrue(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testCloseGrantArchiveAccess_FromPastShares_RestoresPastSharesScreen() {
        let vm = makeViewModel()
        vm.openGrantArchiveAccess(archiveName: "Archive", archiveInitials: "A", archiveID: nil, thumbnailURL: nil, source: .pastShares)

        vm.closeGrantArchiveAccess()

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertTrue(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testCloseGrantArchiveAccess_WithNoPendingGrant_ClearsAllScreens() {
        let vm = makeViewModel()
        vm.showGrantArchiveAccess = true

        vm.closeGrantArchiveAccess()

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
    }

    func testSubmitGrantArchiveAccess_WithNilArchiveID_AppendsNewEntryToSharedArchives() {
        let vm = makeViewModel()
        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "New Archive",
            initials: "NA",
            archiveID: nil,
            thumbnailURL: nil,
            source: .findByEmail
        )
        vm.selectedRoleForGrantAccess = .editor

        vm.submitGrantArchiveAccess()

        XCTAssertEqual(vm.sharedArchives.count, 1)
        XCTAssertEqual(vm.sharedArchives.first?.archiveVO?.fullName, "New Archive")
        XCTAssertEqual(vm.sharedArchives.first?.accessRole, AccessRole.editor.apiValue)
        XCTAssertTrue(vm.shouldShowArchivesSection)
        XCTAssertNil(vm.pendingArchiveGrant)
        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testSubmitGrantArchiveAccess_WithNilArchiveID_UpdatesRoleOfExistingArchiveInstead() {
        let vm = makeViewModel()
        vm.sharedArchives = [makeShareVOWithArchiveName("Existing Archive", role: AccessRole.viewer.apiValue)]
        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Existing Archive",
            initials: "EA",
            archiveID: nil,
            thumbnailURL: nil,
            source: .findByEmail
        )
        vm.selectedRoleForGrantAccess = .editor

        vm.submitGrantArchiveAccess()

        XCTAssertEqual(vm.sharedArchives.count, 1, "Should not duplicate the archive")
        XCTAssertEqual(vm.sharedArchives.first?.accessRole, AccessRole.editor.apiValue)
    }

    func testSubmitGrantArchiveAccess_WithNoPendingGrant_IsNoOp() {
        let vm = makeViewModel()
        vm.pendingArchiveGrant = nil

        vm.submitGrantArchiveAccess()

        XCTAssertEqual(vm.sharedArchives.count, 0)
        XCTAssertFalse(vm.showGrantArchiveAccess)
    }

    // MARK: - Invite and Grant Access Flow

    func testOpenInviteAndGrantAccess_SetsEmailAndDerivesNameFromEmailPrefix() {
        let vm = makeViewModel()

        vm.openInviteAndGrantAccess(recipientEmail: "john@example.com")

        XCTAssertTrue(vm.showInviteAndGrantAccess)
        XCTAssertEqual(vm.invitationRecipientEmail, "john@example.com")
        XCTAssertEqual(vm.invitationRecipientFullName, "john")
        XCTAssertEqual(vm.selectedRoleForInviteAccess, .viewer)
        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertEqual(vm.navigationDirection, .forward)
    }

    func testOpenInviteAndGrantAccess_WithExistingFullName_PreservesName() {
        let vm = makeViewModel()
        vm.invitationRecipientFullName = "Jane Doe"

        vm.openInviteAndGrantAccess(recipientEmail: "jane@example.com")

        XCTAssertEqual(vm.invitationRecipientFullName, "Jane Doe")
        XCTAssertEqual(vm.invitationRecipientEmail, "jane@example.com")
    }

    func testOpenInviteAndGrantAccess_ResetsRoleToViewer() {
        let vm = makeViewModel()
        vm.selectedRoleForInviteAccess = .editor

        vm.openInviteAndGrantAccess(recipientEmail: "user@example.com")

        XCTAssertEqual(vm.selectedRoleForInviteAccess, .viewer)
    }

    func testCloseInviteAndGrantAccess_HidesScreenAndShowsFindByEmail() {
        let vm = makeViewModel()
        vm.openInviteAndGrantAccess(recipientEmail: "test@example.com")

        vm.closeInviteAndGrantAccess()

        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertTrue(vm.showFindArchiveByEmail)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testSubmitInviteAndGrantAccess_WithBlankEmail_IsNoOp() {
        let vm = makeViewModel()
        vm.invitationRecipientEmail = "   "

        vm.submitInviteAndGrantAccess()

        XCTAssertNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    func testSubmitInviteAndGrantAccess_WithNoActiveSession_SetsErrorMessage() {
        let vm = makeViewModel()
        vm.invitationRecipientEmail = "recipient@example.com"

        vm.submitInviteAndGrantAccess()

        XCTAssertNotNil(vm.errorMessage)
        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Archive Access Management

    func testUpdateArchiveAccessRole_WithNilShareID_CallsErrorCompletionImmediately() {
        let vm = makeViewModel()
        let shareVO = makeShareVOWithNilShareID()

        var resultStatus: RequestStatus?
        vm.updateArchiveAccessRole(shareVO: shareVO, newRole: .editor) { status, _ in
            resultStatus = status
        }

        XCTAssertNotNil(resultStatus, "Completion should be called synchronously for nil shareID")
        if case .error = resultStatus! { } else {
            XCTFail("Expected .error for nil shareID, got \(String(describing: resultStatus))")
        }
    }

    func testUpdateArchiveAccessRole_Success_UpdatesRoleInSharedArchives() async {
        let vm = makeViewModel()
        let shareVO = makeShareVO(shareID: 100, archiveID: 1000, accessRole: AccessRole.viewer.apiValue)
        vm.sharedArchives = [shareVO]

        let exp = expectation(description: "completion")
        vm.updateArchiveAccessRole(shareVO: shareVO, newRole: .editor) { _, _ in exp.fulfill() }
        await fulfillment(of: [exp], timeout: 2.0)

        XCTAssertEqual(vm.sharedArchives.first?.accessRole, AccessRole.editor.apiValue)
    }

    func testUpdateArchiveAccessRole_Success_ClearsLoadingState() async {
        let vm = makeViewModel()
        let shareVO = makeShareVO(shareID: 101, archiveID: 1001, accessRole: AccessRole.viewer.apiValue)
        vm.sharedArchives = [shareVO]

        let exp = expectation(description: "completion")
        vm.updateArchiveAccessRole(shareVO: shareVO, newRole: .editor) { _, _ in exp.fulfill() }
        await fulfillment(of: [exp], timeout: 2.0)

        XCTAssertFalse(vm.isLoading)
    }

    func testRevokeArchiveAccess_WithNilShareID_CallsErrorCompletionImmediately() {
        let vm = makeViewModel()
        let shareVO = makeShareVOWithNilShareID()

        var resultStatus: RequestStatus?
        vm.revokeArchiveAccess(shareVO: shareVO) { status, _ in
            resultStatus = status
        }

        XCTAssertNotNil(resultStatus, "Completion should be called synchronously for nil shareID")
        if case .error = resultStatus! { } else {
            XCTFail("Expected .error for nil shareID")
        }
    }

    func testRevokeArchiveAccess_Success_RemovesEntryFromSharedArchives() async {
        let vm = makeViewModel()
        let shareVO = makeShareVO(shareID: 200, archiveID: 2000, accessRole: AccessRole.viewer.apiValue)
        vm.sharedArchives = [shareVO]

        let exp = expectation(description: "completion")
        vm.revokeArchiveAccess(shareVO: shareVO) { _, _ in exp.fulfill() }
        await fulfillment(of: [exp], timeout: 2.0)

        XCTAssertTrue(vm.sharedArchives.isEmpty)
    }

    func testRevokeArchiveAccess_Success_ClearsSelectedArchiveForEdit() async {
        let vm = makeViewModel()
        let shareVO = makeShareVO(shareID: 201, archiveID: 2001, accessRole: AccessRole.viewer.apiValue)
        vm.sharedArchives = [shareVO]
        vm.selectedArchiveForEdit = shareVO

        let exp = expectation(description: "completion")
        vm.revokeArchiveAccess(shareVO: shareVO) { _, _ in exp.fulfill() }
        await fulfillment(of: [exp], timeout: 2.0)

        XCTAssertNil(vm.selectedArchiveForEdit)
    }

    // MARK: - Legacy Email Invitation

    func testSendEmailInvitation_ShowsEmailAddressField() async {
        let vm = makeViewModel()
        XCTAssertFalse(vm.showEmailAddressField)

        vm.sendEmailInvitation()

        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(vm.showEmailAddressField)
    }

    func testSubmitEmailInvitation_WithEmptyEmail_IsNoOp() async {
        let vm = makeViewModel()
        vm.showEmailAddressField = true
        vm.emailAddress = ""

        vm.submitEmailInvitation()

        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertTrue(vm.showEmailAddressField)
        XCTAssertEqual(vm.emailAddress, "")
    }

    func testSubmitEmailInvitation_WithNonEmptyEmail_ClearsEmailAndHidesField() async {
        let vm = makeViewModel()
        vm.showEmailAddressField = true
        vm.emailAddress = "invited@example.com"

        vm.submitEmailInvitation()

        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertFalse(vm.showEmailAddressField)
        XCTAssertEqual(vm.emailAddress, "")
    }

    // MARK: - Helpers

    private func makeViewModel() -> ShareItemViewModel {
        ShareItemViewModel(
            fileModel: FileModel.mockFile(),
            shareManagementRepository: GrantAccessMockRepository()
        )
    }

    private func makeShareVO(shareID: Int, archiveID: Int, accessRole: String) -> ShareVOData {
        ShareVOData(
            shareID: shareID,
            folderLinkID: 1,
            archiveID: archiveID,
            accessRole: accessRole,
            type: "type.share.archive",
            status: "status.generic.ok",
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: nil,
            accountVO: nil,
            createdDT: nil,
            updatedDT: nil
        )
    }

    private func makeShareVOWithNilShareID() -> ShareVOData {
        ShareVOData(
            shareID: nil,
            folderLinkID: nil,
            archiveID: nil,
            accessRole: nil,
            type: nil,
            status: "status.generic.ok",
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: nil,
            accountVO: nil,
            createdDT: nil,
            updatedDT: nil
        )
    }

    private func makeShareVOWithArchiveName(_ name: String, role: String) -> ShareVOData {
        let archiveJSON = """
        {"fullName": "\(name)", "accessRole": "\(role)", "archiveId": 12345}
        """
        let archiveVO = try? JSONDecoder().decode(ArchiveVOData.self, from: Data(archiveJSON.utf8))
        return ShareVOData(
            shareID: 1,
            folderLinkID: 1,
            archiveID: 12345,
            accessRole: role,
            type: "type.share.archive",
            status: "status.generic.ok",
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: archiveVO,
            accountVO: nil,
            createdDT: nil,
            updatedDT: nil
        )
    }
}

// MARK: - Mock Repository

private class GrantAccessMockRepository: ShareManagementRepository {

    override func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            completion(nil, nil)
        }
    }

    override func getShareLinkV2(file: FileModel, then completion: @escaping ShareLinkV2Handler) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            completion(nil, nil)
        }
    }

    override func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus, ShareVOData?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var updated = shareVO
            updated.accessRole = accessRole.apiValue
            handler(.success, updated)
        }
    }

    override func denyButtonAction(shareVO: ShareVOData, then handler: @escaping (RequestStatus) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            handler(.success)
        }
    }
}
