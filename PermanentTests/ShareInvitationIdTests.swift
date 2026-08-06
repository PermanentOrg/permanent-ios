//
//  ShareInvitationIdTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 05.08.2026.
//

import Foundation
import Testing
@testable import Permanent

/// VSP-1800: "Send again" and "Revoke" post the invite id recovered from a pending
/// invitation's `shareID`. These cover the id surviving the round trip from `/invite/share`
/// into the stored row and back out, and staying recoverable across a refetch.
///
/// Serialized because `ShareItemViewModel.init` calls `loadInitialData()`, which issues a
/// network request against process-global auth state. Running these concurrently lets one
/// test's late completion land in another's `sharedArchives`.
@MainActor
@Suite(.serialized)
struct ShareInvitationIdTests {

    // MARK: - Round trip: captured id -> stored row -> recovered id

    @Test("An invite id from /invite/share round-trips through the stored row")
    func inviteIdRoundTripsThroughStoredRow() async throws {
        let vm = await makeViewModel()

        vm.addInvitedRecipientToCurrentAccessList(
            fullName: "Test User",
            email: "invitee@example.com",
            role: .viewer,
            inviteId: 4242
        )

        let row = try #require(vm.sharedArchives.first { $0.accountVO?.primaryEmail == "invitee@example.com" })
        #expect(row.shareID == -4242, "The row must carry the real invite id, negated")
        #expect(vm.inviteId(from: row) == 4242, "resend/revoke must recover the id /invite/share issued")
    }

    @Test("Re-inviting the same address replaces the superseded id")
    func reInvitingSameAddressRefreshesId() async throws {
        let vm = await makeViewModel()

        vm.addInvitedRecipientToCurrentAccessList(
            fullName: "Test User", email: "invitee@example.com", role: .viewer, inviteId: 100
        )
        vm.addInvitedRecipientToCurrentAccessList(
            fullName: "Test User", email: "invitee@example.com", role: .editor, inviteId: 200
        )

        let invited = vm.sharedArchives.filter { $0.accountVO?.primaryEmail == "invitee@example.com" }
        #expect(invited.count == 1, "Re-inviting must not duplicate the row")
        let row = try #require(invited.first)
        #expect(vm.inviteId(from: row) == 200, "The fresh id supersedes the previous one")
        #expect(row.accessRole == AccessRole.editor.apiValue)
    }

    @Test("A non-positive invite id is stored as no id rather than a fabricated one")
    func nonPositiveInviteIdStoresNoId() async {
        let vm = await makeViewModel()

        let row = vm.makeInvitedShareRow(fullName: "N", email: "zero@example.com", role: .viewer, inviteId: 0)

        #expect(row.shareID == nil)
        #expect(vm.inviteId(from: row) == nil)
    }

    // MARK: - V2 pending shares

    @Test("A V2 pending share encodes its id exactly")
    func pendingShareEncodesIdExactly() async throws {
        let vm = await makeViewModel()

        vm.finalizeSharedArchives([], pendingSharesV2: [
            PendingShareV2(id: "42", email: "user@example.com", name: "User", accessRole: "access.role.viewer")
        ])

        let row = try #require(vm.sharedArchives.first)
        #expect(row.shareID == -42)
        #expect(vm.inviteId(from: row) == 42)
    }

    @Test("A V2 pending share with an unusable id yields no id", arguments: ["", "not-a-number", "0", "-5"])
    func pendingShareWithUnusableIdYieldsNoId(rawId: String) async throws {
        let vm = await makeViewModel()

        vm.finalizeSharedArchives([], pendingSharesV2: [
            PendingShareV2(id: rawId, email: "user@example.com", name: "User", accessRole: "access.role.viewer")
        ])

        let row = try #require(vm.sharedArchives.first, "The row still renders — only the id is missing")
        #expect(row.shareID == nil, "Must not fall back to -1, which addresses invite id 1")
        #expect(vm.inviteId(from: row) == nil)
    }

    // MARK: - Missing id is reported, not silently swallowed

    @Test("Resend reports an error when the row carries no invite id")
    func resendWithoutIdReportsError() async {
        let vm = await makeViewModel()
        vm.editingInvitation = vm.makeInvitedShareRow(
            fullName: "N", email: "noid@example.com", role: .viewer, inviteId: 0
        )

        vm.resendInvitation()

        #expect(vm.errorMessage != nil, "A missing id must surface, not fail silently")
        #expect(vm.isLoading == false)
    }

    @Test("Revoke reports an error when the row carries no invite id")
    func revokeWithoutIdReportsError() async {
        let vm = await makeViewModel()
        vm.editingInvitation = vm.makeInvitedShareRow(
            fullName: "N", email: "noid@example.com", role: .viewer, inviteId: 0
        )

        vm.revokeInvitation()

        #expect(vm.errorMessage != nil, "A missing id must surface, not fail silently")
        #expect(vm.isLoading == false)
    }

    // MARK: - A granted archive is not an invitation

    @Test("A locally granted archive row is never read as an invitation")
    func grantedArchiveRowIsNotAnInvitation() async {
        let vm = await makeViewModel()
        // Local grants also get a synthetic negative shareID, but status is `ok`, not `invited`.
        let grantedRow = ShareVOData(
            shareID: -654_321,
            folderLinkID: nil,
            archiveID: 123,
            accessRole: AccessRole.viewer.apiValue,
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

        #expect(vm.inviteId(from: grantedRow) == nil, "Revoking this id would hit an unrelated invitation")
    }

    // MARK: - The id survives a refetch

    @Test("A refetch keeps the locally captured id when the V2 row has none")
    func refetchPreservesLocallyCapturedId() async throws {
        let vm = await makeViewModel()

        // The invite has just been sent: the row holds the id from /invite/share.
        vm.addInvitedRecipientToCurrentAccessList(
            fullName: "Test User", email: "invitee@example.com", role: .viewer, inviteId: 4242
        )

        // A refetch returns the same invitation over V2, but without a usable id.
        vm.finalizeSharedArchives([], pendingSharesV2: [
            PendingShareV2(id: nil, email: "invitee@example.com", name: "Test User", accessRole: "access.role.viewer")
        ])

        let invited = vm.sharedArchives.filter { $0.accountVO?.primaryEmail?.lowercased() == "invitee@example.com" }
        #expect(invited.count == 1, "The two rows describe one invitation")
        let row = try #require(invited.first)
        #expect(vm.inviteId(from: row) == 4242, "Send again must still work after a refresh")
    }

    @Test("A refetch takes the V2 id when the V2 row has one")
    func refetchPrefersV2IdWhenPresent() async throws {
        let vm = await makeViewModel()

        vm.addInvitedRecipientToCurrentAccessList(
            fullName: "Test User", email: "invitee@example.com", role: .viewer, inviteId: 4242
        )

        vm.finalizeSharedArchives([], pendingSharesV2: [
            PendingShareV2(id: "77", email: "invitee@example.com", name: "Test User", accessRole: "access.role.viewer")
        ])

        let invited = vm.sharedArchives.filter { $0.accountVO?.primaryEmail?.lowercased() == "invitee@example.com" }
        #expect(invited.count == 1)
        let row = try #require(invited.first)
        #expect(vm.inviteId(from: row) == 77)
    }

    // MARK: - Helpers

    /// Builds the view model and lets its `init`-triggered load settle, so a late completion
    /// cannot overwrite `sharedArchives` mid-assertion.
    private func makeViewModel() async -> ShareItemViewModel {
        let vm = ShareItemViewModel(
            fileModel: FileModel.mockFile(),
            shareManagementRepository: ShareManagementRepository()
        )

        let deadline = Date().addingTimeInterval(2.0)
        while vm.isLoading && Date() < deadline {
            try? await Task.sleep(nanoseconds: 10_000_000)
        }

        vm.sharedArchives = []
        vm.errorMessage = nil
        return vm
    }
}
