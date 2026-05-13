//
//  ShareManagementViewRenderingTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 08.05.2026.
//

import XCTest
import SwiftUI
import UIKit
@testable import Permanent

@MainActor
final class ShareManagementViewRenderingTests: XCTestCase {

    // MARK: - ShareGrantArchiveAccessView

    func testGrantArchiveAccess_RendersInDefaultState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Test Archive", initials: "TA", archiveID: 1, thumbnailURL: nil, source: .findByEmail
        )

        let host = hostView(ShareGrantArchiveAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testGrantArchiveAccess_RendersWithThumbnail() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Photo Archive", initials: "PA", archiveID: 2, thumbnailURL: "https://example.com/thumb.jpg", source: .pastShares
        )

        let host = hostView(ShareGrantArchiveAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.selectedRoleForGrantAccess, .viewer)
    }

    func testGrantArchiveAccess_RendersWhileLoading() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Loading Archive", initials: "LA", archiveID: 3, thumbnailURL: nil, source: .findByEmail
        )
        vm.isLoading = true

        let host = hostView(ShareGrantArchiveAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testGrantArchiveAccess_RendersWithErrorMessage() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Error Archive", initials: "EA", archiveID: 4, thumbnailURL: nil, source: .findByEmail
        )
        vm.errorMessage = "Test error"

        let host = hostView(ShareGrantArchiveAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testGrantArchiveAccess_RendersWithNilPendingGrant() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.pendingArchiveGrant = nil

        let host = hostView(ShareGrantArchiveAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testGrantArchiveAccess_RendersWithEditorRole() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.pendingArchiveGrant = ShareItemViewModel.PendingArchiveGrant(
            name: "Editor Archive", initials: "EA", archiveID: 5, thumbnailURL: nil, source: .pastShares
        )
        vm.selectedRoleForGrantAccess = .editor

        let host = hostView(ShareGrantArchiveAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.selectedRoleForGrantAccess, .editor)
    }

    // MARK: - ShareInviteAndGrantAccessView

    func testInviteAndGrantAccess_RendersInDefaultState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        let host = hostView(ShareInviteAndGrantAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testInviteAndGrantAccess_RendersWithPrefilledFields() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.invitationRecipientFullName = "John Doe"
        vm.invitationRecipientEmail = "john@example.com"
        vm.selectedRoleForInviteAccess = .contributor

        let host = hostView(ShareInviteAndGrantAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.invitationRecipientFullName, "John Doe")
        XCTAssertEqual(vm.invitationRecipientEmail, "john@example.com")
    }

    func testInviteAndGrantAccess_RendersWhileLoading() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.isLoading = true

        let host = hostView(ShareInviteAndGrantAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testInviteAndGrantAccess_RendersWithErrorMessage() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.errorMessage = "Invalid email address"

        let host = hostView(ShareInviteAndGrantAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testInviteAndGrantAccess_RendersWithAllRoles() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        let roles: [AccessRole] = [.viewer, .contributor, .editor, .curator, .owner]
        for role in roles {
            vm.selectedRoleForInviteAccess = role
            let host = hostView(ShareInviteAndGrantAccessView(viewModel: vm))
            try? await Task.sleep(nanoseconds: 50_000_000)
            XCTAssertNotNil(host.view, "Should render with role \(role.title)")
        }
    }

    // MARK: - ShareEditInvitationView

    func testEditInvitation_RendersInDefaultState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.editingInvitation = makeInvitationShareVO()
        vm.selectedRoleForEditInvitation = .viewer

        let host = hostView(ShareEditInvitationView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testEditInvitation_RendersWithNilInvitation() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.editingInvitation = nil

        let host = hostView(ShareEditInvitationView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testEditInvitation_RendersWhileLoading() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.editingInvitation = makeInvitationShareVO()
        vm.isLoading = true

        let host = hostView(ShareEditInvitationView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testEditInvitation_RendersWithRevokeAlert() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.editingInvitation = makeInvitationShareVO()
        vm.showRevokeInvitationAlert = true

        let host = hostView(ShareEditInvitationView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testEditInvitation_RendersWithEditorRole() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.editingInvitation = makeInvitationShareVO()
        vm.selectedRoleForEditInvitation = .editor

        let host = hostView(ShareEditInvitationView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.selectedRoleForEditInvitation, .editor)
    }

    // MARK: - GeneralAccessView

    func testGeneralAccess_RendersInDefaultState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        let host = hostView(GeneralAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testGeneralAccess_RendersWithRestrictedLevel() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.selectedAccessLevel = .restricted

        let host = hostView(GeneralAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testGeneralAccess_RendersWhileLoading() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.isLoading = true

        let host = hostView(GeneralAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testGeneralAccess_RendersWithErrorMessage() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.errorMessage = "Access update failed"

        let host = hostView(GeneralAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    // MARK: - RoleSelectionView

    func testRoleSelection_RendersInDefaultState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        let host = hostView(RoleSelectionView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testRoleSelection_RendersForEditInvitationContext() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.showEditInvitation = true
        vm.selectedRoleForEditInvitation = .editor

        let host = hostView(RoleSelectionView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testRoleSelection_RendersForArchiveAccessContext() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.showArchiveAccessManagement = true
        vm.selectedRoleForArchive = .curator

        let host = hostView(RoleSelectionView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testRoleSelection_RendersForInviteAccessContext() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.showInviteAndGrantAccess = true
        vm.selectedRoleForInviteAccess = .contributor

        let host = hostView(RoleSelectionView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testRoleSelection_RendersForGrantAccessContext() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.showGrantArchiveAccess = true
        vm.selectedRoleForGrantAccess = .viewer

        let host = hostView(RoleSelectionView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testRoleSelection_RendersWhileLoading() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.isLoading = true

        let host = hostView(RoleSelectionView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    // MARK: - ArchiveAccessManagementView

    func testArchiveAccessManagement_RendersInDefaultState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.selectedArchiveForEdit = makeSharedArchiveVO()

        let host = hostView(ArchiveAccessManagementView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testArchiveAccessManagement_RendersWithNilArchive() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.selectedArchiveForEdit = nil

        let host = hostView(ArchiveAccessManagementView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testArchiveAccessManagement_RendersWithSelectedRole() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.selectedArchiveForEdit = makeSharedArchiveVO()
        vm.selectedRoleForArchive = .editor

        let host = hostView(ArchiveAccessManagementView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testArchiveAccessManagement_RendersWhileLoading() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.selectedArchiveForEdit = makeSharedArchiveVO()
        vm.isLoading = true

        let host = hostView(ArchiveAccessManagementView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testArchiveAccessManagement_RendersWithRevokeAlert() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.selectedArchiveForEdit = makeSharedArchiveVO()
        vm.showRevokeArchiveAccessAlert = true

        let host = hostView(ArchiveAccessManagementView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    // MARK: - ShareArchivesFromPastSharesView

    func testArchivesFromPastShares_RendersInDefaultState() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        let host = hostView(ShareArchivesFromPastSharesView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testArchivesFromPastShares_RendersWithSearchText() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.pastSharesViewModel.searchText = "test"

        let host = hostView(ShareArchivesFromPastSharesView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    func testArchivesFromPastShares_RendersAfterClearingSearch() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.pastSharesViewModel.searchText = "query"
        vm.pastSharesViewModel.searchText = ""

        let host = hostView(ShareArchivesFromPastSharesView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
    }

    // MARK: - ShareFindArchiveByEmailView (additional states)

    func testFindArchiveByEmail_RendersWithSearchInProgress() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.findArchiveByEmailViewModel.searchText = "test@example.com"
        vm.findArchiveByEmailViewModel.performSearch()

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertTrue(vm.findArchiveByEmailViewModel.isSearching)
    }

    func testFindArchiveByEmail_RendersAfterClearSearch() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        vm.findArchiveByEmailViewModel.searchText = "test@example.com"
        vm.findArchiveByEmailViewModel.performSearch()
        vm.findArchiveByEmailViewModel.clearSearch()

        let host = hostView(ShareFindArchiveByEmailView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertNotNil(host.view)
        XCTAssertEqual(vm.findArchiveByEmailViewModel.searchText, "")
    }

    // MARK: - Multiple State Transitions

    func testMultipleViewStates_DoNotCrash() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        let host1 = hostView(GeneralAccessView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNotNil(host1.view)

        vm.selectedAccessLevel = .restricted
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNotNil(host1.view)

        vm.selectedAccessLevel = .anyoneCanView
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNotNil(host1.view)
    }

    func testRoleSelection_StateTransitions_DoNotCrash() async {
        let vm = makeViewModel()
        await waitForInitialLoad(of: vm)

        let host = hostView(RoleSelectionView(viewModel: vm))
        try? await Task.sleep(nanoseconds: 50_000_000)
        XCTAssertNotNil(host.view)

        vm.showEditInvitation = true
        vm.selectedRoleForEditInvitation = .viewer
        try? await Task.sleep(nanoseconds: 50_000_000)

        vm.showEditInvitation = false
        vm.showInviteAndGrantAccess = true
        vm.selectedRoleForInviteAccess = .editor
        try? await Task.sleep(nanoseconds: 50_000_000)

        XCTAssertNotNil(host.view)
    }

    // MARK: - Helpers

    private func makeViewModel() -> ShareItemViewModel {
        ShareItemViewModel(
            fileModel: FileModel.mockFile(),
            shareManagementRepository: ViewRenderTestRepository()
        )
    }

    private func hostView<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = host
        window.makeKeyAndVisible()
        return host
    }

    private func waitForInitialLoad(of viewModel: ShareItemViewModel) async {
        let deadline = Date().addingTimeInterval(2.0)
        while Date() < deadline {
            if !viewModel.isLoading {
                return
            }
            try? await Task.sleep(nanoseconds: 50_000_000)
        }
    }

    private func makeInvitationShareVO() -> ShareVOData {
        let account = AccountVOData(
            accountID: 100,
            primaryEmail: "invited@example.com",
            fullName: "Invited User",
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
            shareID: -500,
            folderLinkID: 1,
            archiveID: nil,
            accessRole: "access.role.viewer",
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

    private func makeSharedArchiveVO() -> ShareVOData {
        let archiveVO = ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: "access.role.viewer",
            fullName: "Test User",
            spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
            relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil,
            itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil,
            archiveID: 999,
            publicDT: nil, archiveNbr: nil, view: nil, viewProperty: nil,
            archiveVOPublic: nil, vaultKey: nil, thumbArchiveNbr: nil,
            type: nil, thumbStatus: .ok, imageRatio: nil,
            thumbURL200: nil, thumbURL500: nil, thumbURL1000: nil, thumbURL2000: nil,
            thumbDT: nil, createdDT: nil, updatedDT: nil, status: .ok
        )

        return ShareVOData(
            shareID: 300,
            folderLinkID: 1,
            archiveID: 999,
            accessRole: "access.role.viewer",
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

private final class ViewRenderTestRepository: ShareManagementRepository {
    override func getShareLink(file: FileModel, option: ShareLinkOption, then completion: @escaping ShareLinkResponse) {
        completion(nil, nil)
    }

    override func getShareLinkV2ByToken(token: String, then completion: @escaping ShareLinkV2Handler) {
        completion(nil, nil)
    }

    override func getShareLinkV2(shareLinkId: String, then completion: @escaping ShareLinkV2Handler) {
        completion(nil, nil)
    }
}
