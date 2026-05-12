//
//  ShareItemGrantAndInviteViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 08.05.2026.
//

import XCTest
import Combine
@testable import Permanent

@MainActor
final class ShareItemGrantAndInviteViewModelTests: XCTestCase {

    // MARK: - Find Archive by Email Flow

    func testOpenFindArchiveByEmail_SetsCorrectState() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openFindArchiveByEmail()

        XCTAssertTrue(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertEqual(vm.navigationDirection, .forward)
    }

    func testOpenFindArchiveByEmail_ResetsEmailViewModel() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.findArchiveByEmailViewModel.searchText = "test@example.com"
        vm.findArchiveByEmailViewModel.performSearch()

        vm.openFindArchiveByEmail()

        XCTAssertEqual(vm.findArchiveByEmailViewModel.searchText, "")
        XCTAssertNil(vm.findArchiveByEmailViewModel.submittedSearchEmail)
    }

    func testCloseFindArchiveByEmail_SetsCorrectState() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.showFindArchiveByEmail = true
        vm.closeFindArchiveByEmail()

        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    // MARK: - Select Archive from Past Shares Flow

    func testOpenSelectArchiveFromPastShares_SetsCorrectState() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openSelectArchiveFromPastShares()

        XCTAssertTrue(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertEqual(vm.navigationDirection, .forward)
    }

    func testCloseSelectArchiveFromPastShares_SetsCorrectState() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.showSelectArchiveFromPastShares = true
        vm.closeSelectArchiveFromPastShares()

        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    // MARK: - Grant Archive Access Flow

    func testOpenGrantArchiveAccess_FromFindByEmail_SetsCorrectState() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openGrantArchiveAccess(
            archiveName: "Test Archive",
            archiveInitials: "TA",
            archiveID: 42,
            thumbnailURL: "https://example.com/thumb.jpg",
            source: .findByEmail
        )

        XCTAssertTrue(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertEqual(vm.navigationDirection, .forward)
        XCTAssertEqual(vm.selectedRoleForGrantAccess, .viewer)
        XCTAssertNotNil(vm.pendingArchiveGrant)
        XCTAssertEqual(vm.pendingArchiveGrant?.name, "Test Archive")
        XCTAssertEqual(vm.pendingArchiveGrant?.initials, "TA")
        XCTAssertEqual(vm.pendingArchiveGrant?.archiveID, 42)
        XCTAssertEqual(vm.pendingArchiveGrant?.thumbnailURL, "https://example.com/thumb.jpg")
    }

    func testOpenGrantArchiveAccess_FromPastShares_SetsCorrectSource() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openGrantArchiveAccess(
            archiveName: "Past Share",
            archiveInitials: "PS",
            archiveID: 10,
            source: .pastShares
        )

        XCTAssertNotNil(vm.pendingArchiveGrant)
        if case .pastShares = vm.pendingArchiveGrant?.source {} else {
            XCTFail("Expected .pastShares source")
        }
    }

    func testOpenGrantArchiveAccess_WithNilArchiveID() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openGrantArchiveAccess(
            archiveName: "No ID",
            archiveInitials: "NI",
            archiveID: nil,
            source: .findByEmail
        )

        XCTAssertNil(vm.pendingArchiveGrant?.archiveID)
        XCTAssertTrue(vm.showGrantArchiveAccess)
    }

    func testCloseGrantArchiveAccess_FromFindByEmail_ReturnsToEmail() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openGrantArchiveAccess(
            archiveName: "Test",
            archiveInitials: "T",
            archiveID: 1,
            source: .findByEmail
        )

        vm.closeGrantArchiveAccess()

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertTrue(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testCloseGrantArchiveAccess_FromPastShares_ReturnsToPastShares() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openGrantArchiveAccess(
            archiveName: "Test",
            archiveInitials: "T",
            archiveID: 1,
            source: .pastShares
        )

        vm.closeGrantArchiveAccess()

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertTrue(vm.showSelectArchiveFromPastShares)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testSubmitGrantArchiveAccess_WithNilPending_DoesNothing() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.pendingArchiveGrant = nil
        vm.submitGrantArchiveAccess()

        XCTAssertFalse(vm.isLoading)
    }

    func testSubmitGrantArchiveAccess_WithNilArchiveID_AddsLocalArchive() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Local Only",
            initials: "LO",
            archiveID: nil,
            thumbnailURL: nil,
            source: .findByEmail
        )
        vm.selectedRoleForGrantAccess = .editor
        vm.showGrantArchiveAccess = true

        vm.submitGrantArchiveAccess()

        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertNil(vm.pendingArchiveGrant)
        XCTAssertTrue(vm.sharedArchives.count >= 1)
    }

    // MARK: - Invite and Grant Access Flow

    func testOpenInviteAndGrantAccess_SetsCorrectState() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openInviteAndGrantAccess(recipientEmail: "user@test.com")

        XCTAssertTrue(vm.showInviteAndGrantAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertEqual(vm.navigationDirection, .forward)
        XCTAssertEqual(vm.invitationRecipientEmail, "user@test.com")
        XCTAssertEqual(vm.selectedRoleForInviteAccess, .viewer)
    }

    func testOpenInviteAndGrantAccess_SetsDefaultFullNameFromEmail() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.invitationRecipientFullName = ""
        vm.openInviteAndGrantAccess(recipientEmail: "john.doe@example.com")

        XCTAssertEqual(vm.invitationRecipientFullName, "john.doe")
    }

    func testOpenInviteAndGrantAccess_PreservesExistingFullName() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.invitationRecipientFullName = "Existing Name"
        vm.openInviteAndGrantAccess(recipientEmail: "user@test.com")

        XCTAssertEqual(vm.invitationRecipientFullName, "Existing Name")
    }

    func testCloseInviteAndGrantAccess_ReturnsToFindByEmail() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.showInviteAndGrantAccess = true
        vm.closeInviteAndGrantAccess()

        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertTrue(vm.showFindArchiveByEmail)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    func testSubmitInviteAndGrantAccess_EmptyEmail_DoesNothing() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.invitationRecipientEmail = ""
        vm.submitInviteAndGrantAccess()

        XCTAssertFalse(vm.isLoading)
    }

    func testSubmitInviteAndGrantAccess_WhitespaceEmail_DoesNothing() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.invitationRecipientEmail = "   "
        vm.submitInviteAndGrantAccess()

        XCTAssertFalse(vm.isLoading)
    }

    // MARK: - Edit Invitation Flow

    func testOpenEditInvitation_SetsCorrectState() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        let shareVO = makeShareVO(accessRole: "access.role.editor")

        vm.openEditInvitation(shareVO: shareVO)

        XCTAssertTrue(vm.showEditInvitation)
        XCTAssertEqual(vm.navigationDirection, .forward)
        XCTAssertNotNil(vm.editingInvitation)
        XCTAssertEqual(vm.editingInvitation?.shareID, shareVO.shareID)
        XCTAssertEqual(vm.selectedRoleForEditInvitation, .editor)
    }

    func testOpenEditInvitation_WithViewerRole() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        let shareVO = makeShareVO(accessRole: "access.role.viewer")

        vm.openEditInvitation(shareVO: shareVO)

        XCTAssertEqual(vm.selectedRoleForEditInvitation, .viewer)
    }

    func testCloseEditInvitation_SetsCorrectState() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.showEditInvitation = true
        vm.editingInvitation = makeShareVO()

        vm.closeEditInvitation()

        XCTAssertFalse(vm.showEditInvitation)
        XCTAssertNil(vm.editingInvitation)
        XCTAssertEqual(vm.navigationDirection, .backward)
    }

    // MARK: - Legacy Email Invitation

    func testSendEmailInvitation_ShowsField() async {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.sendEmailInvitation()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(vm.showEmailAddressField)
    }

    func testSubmitEmailInvitation_ClearsAndHidesField() async {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.showEmailAddressField = true
        vm.emailAddress = "test@test.com"

        vm.submitEmailInvitation()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertFalse(vm.showEmailAddressField)
        XCTAssertEqual(vm.emailAddress, "")
    }

    func testSubmitEmailInvitation_EmptyEmail_DoesNothing() async {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.showEmailAddressField = true
        vm.emailAddress = ""

        vm.submitEmailInvitation()
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(vm.showEmailAddressField)
    }

    // MARK: - Archive Access Management

    func testUpdateArchiveAccessRole_NilShareID_ReturnsError() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        let shareVO = ShareVOData(
            shareID: nil,
            folderLinkID: 1,
            archiveID: 100,
            accessRole: "access.role.viewer",
            type: nil, status: "status.generic.ok",
            requestToken: nil, previewToggle: nil,
            folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil,
            createdDT: nil, updatedDT: nil
        )

        let expectation = XCTestExpectation(description: "Completion called")
        vm.updateArchiveAccessRole(shareVO: shareVO, newRole: .editor) { result, _ in
            if case .error = result {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testRevokeArchiveAccess_NilShareID_ReturnsError() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        let shareVO = ShareVOData(
            shareID: nil,
            folderLinkID: 1,
            archiveID: 100,
            accessRole: "access.role.viewer",
            type: nil, status: "status.generic.ok",
            requestToken: nil, previewToggle: nil,
            folderVO: nil, recordVO: nil, archiveVO: nil, accountVO: nil,
            createdDT: nil, updatedDT: nil
        )

        let expectation = XCTestExpectation(description: "Completion called")
        vm.revokeArchiveAccess(shareVO: shareVO) { result, _ in
            if case .error = result {
                expectation.fulfill()
            }
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateArchiveAccessRole_ValidShare_CallsRepository() async {
        let repo = GrantInviteTestRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        let shareVO = makeShareVO(shareID: 100, accessRole: "access.role.viewer")
        vm.sharedArchives = [shareVO]

        let expectation = XCTestExpectation(description: "Completion called")
        vm.updateArchiveAccessRole(shareVO: shareVO, newRole: .editor) { result, _ in
            if case .success = result {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 3.0)
        XCTAssertFalse(vm.isLoading)
    }

    func testRevokeArchiveAccess_ValidShare_RemovesFromList() async {
        let repo = GrantInviteTestRepository()
        let vm = makeViewModel(repository: repo)
        waitForInitialLoad(vm)

        let shareVO = makeShareVO(shareID: 200, accessRole: "access.role.viewer")
        vm.sharedArchives = [shareVO]

        let expectation = XCTestExpectation(description: "Completion called")
        vm.revokeArchiveAccess(shareVO: shareVO) { result, _ in
            if case .success = result {
                expectation.fulfill()
            }
        }

        await fulfillment(of: [expectation], timeout: 3.0)
        XCTAssertTrue(vm.sharedArchives.isEmpty)
        XCTAssertFalse(vm.shouldShowArchivesSection)
    }

    // MARK: - Notification

    func testShowArchiveAccessUpdatedNotification_SetsMessage() async {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.showArchiveAccessUpdatedNotification(message: "Custom message")

        try? await Task.sleep(nanoseconds: 1_000_000_000)
        XCTAssertEqual(vm.archiveAccessNotificationMessage, "Custom message")
        XCTAssertTrue(vm.showArchiveAccessNotification)
    }

    func testShowArchiveAccessUpdatedNotification_DefaultMessage() async {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.showArchiveAccessUpdatedNotification()

        try? await Task.sleep(nanoseconds: 600_000_000)
        XCTAssertEqual(vm.archiveAccessNotificationMessage, "Archive access has been updated.")
    }

    // MARK: - Navigation Flow Integration

    func testFullGrantFlow_FindByEmail_NavigationSequence() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openFindArchiveByEmail()
        XCTAssertTrue(vm.showFindArchiveByEmail)

        vm.openGrantArchiveAccess(
            archiveName: "Found Archive",
            archiveInitials: "FA",
            archiveID: 50,
            source: .findByEmail
        )
        XCTAssertTrue(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)

        vm.closeGrantArchiveAccess()
        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertTrue(vm.showFindArchiveByEmail)

        vm.closeFindArchiveByEmail()
        XCTAssertFalse(vm.showFindArchiveByEmail)
    }

    func testFullGrantFlow_PastShares_NavigationSequence() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openSelectArchiveFromPastShares()
        XCTAssertTrue(vm.showSelectArchiveFromPastShares)

        vm.openGrantArchiveAccess(
            archiveName: "Past Archive",
            archiveInitials: "PA",
            archiveID: 60,
            source: .pastShares
        )
        XCTAssertTrue(vm.showGrantArchiveAccess)
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)

        vm.closeGrantArchiveAccess()
        XCTAssertFalse(vm.showGrantArchiveAccess)
        XCTAssertTrue(vm.showSelectArchiveFromPastShares)

        vm.closeSelectArchiveFromPastShares()
        XCTAssertFalse(vm.showSelectArchiveFromPastShares)
    }

    func testFullInviteFlow_NavigationSequence() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        vm.openFindArchiveByEmail()
        XCTAssertTrue(vm.showFindArchiveByEmail)

        vm.openInviteAndGrantAccess(recipientEmail: "new@example.com")
        XCTAssertTrue(vm.showInviteAndGrantAccess)
        XCTAssertFalse(vm.showFindArchiveByEmail)

        vm.closeInviteAndGrantAccess()
        XCTAssertFalse(vm.showInviteAndGrantAccess)
        XCTAssertTrue(vm.showFindArchiveByEmail)
    }

    func testEditInvitationFlow_OpenAndClose() {
        let vm = makeViewModel()
        waitForInitialLoad(vm)

        let shareVO = makeShareVO(accessRole: "access.role.contributor")
        vm.openEditInvitation(shareVO: shareVO)

        XCTAssertTrue(vm.showEditInvitation)
        XCTAssertEqual(vm.selectedRoleForEditInvitation, .contributor)

        vm.closeEditInvitation()

        XCTAssertFalse(vm.showEditInvitation)
        XCTAssertNil(vm.editingInvitation)
    }

    // MARK: - Helpers

    private func makeViewModel(repository: ShareManagementRepository? = nil) -> ShareItemViewModel {
        ShareItemViewModel(
            fileModel: FileModel.mockFile(),
            shareManagementRepository: repository ?? GrantInviteTestRepository()
        )
    }

    private func waitForInitialLoad(_ vm: ShareItemViewModel) {
        var attempts = 0
        while vm.isLoading && attempts < 50 {
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
            attempts += 1
        }
    }

    private func makeShareVO(shareID: Int = -500, accessRole: String = "access.role.viewer") -> ShareVOData {
        let account = AccountVOData(
            accountID: 100,
            primaryEmail: "user@example.com",
            fullName: "Test User",
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

        return ShareVOData(
            shareID: shareID,
            folderLinkID: 1,
            archiveID: nil,
            accessRole: accessRole,
            type: "type.share.archive",
            status: "status.generic.invited",
            requestToken: nil,
            previewToggle: nil,
            folderVO: nil,
            recordVO: nil,
            archiveVO: nil,
            accountVO: account,
            createdDT: nil,
            updatedDT: nil
        )
    }
}

// MARK: - Mock Repository

private final class GrantInviteTestRepository: ShareManagementRepository {
    override func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        completion(nil, nil)
    }

    override func getShareLinkV2ByToken(token: String, then completion: @escaping ShareLinkV2Handler) {
        completion(nil, nil)
    }

    override func getShareLinkV2(shareLinkId: String, then completion: @escaping ShareLinkV2Handler) {
        completion(nil, nil)
    }

    override func approveButtonAction(shareVO: ShareVOData, accessRole: AccessRole = .viewer, then handler: @escaping (RequestStatus, ShareVOData?) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            var updatedShare = shareVO
            updatedShare.accessRole = accessRole.apiValue
            handler(.success, updatedShare)
        }
    }

    override func denyButtonAction(shareVO: ShareVOData, then handler: @escaping (RequestStatus) -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            handler(.success)
        }
    }
}
