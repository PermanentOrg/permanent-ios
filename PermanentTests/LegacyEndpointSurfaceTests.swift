//
//  LegacyEndpointSurfaceTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 24.08.2026.
//

import Foundation
import Testing
@testable import Permanent

/// Pins the V1/V2 boundary per endpoint case so the surface cannot drift unnoticed. A case that
/// gains, loses or changes its Stela V2 route reddens a test here instead of a hand audit.
@Suite
struct LegacyEndpointSurfaceTests {

    /// `customURL` wins over `path` when it is non-nil, so a V1 `path` string with a V2
    /// `customURL` beside it never reaches the network.
    private func sendsV2(_ endpoint: RequestProtocol, _ route: String) -> Bool {
        guard let url = endpoint.customURL else { return false }
        return url.contains("api/v2/\(route)")
    }

    // MARK: - Stays on V1 — no Stela route exists

    @Test("Root discovery stays on V1")
    func rootDiscoveryIsV1() {
        #expect(FilesEndpoint.getRoot.path == "/folder/getRoot")
        #expect(FilesEndpoint.getRoot.customURL == nil)
        #expect(FilesEndpoint.getPublicRoot(archiveNbr: "0001-0000").path == "/folder/getPublicRoot")
        #expect(FilesEndpoint.getPublicRoot(archiveNbr: "0001-0000").customURL == nil)
    }

    @Test("The legacy Get-link quick action stays on V1")
    func getLinkIsV1() {
        // V2 looks a share link up by id or token only, so there is no way to ask whether a
        // record has one.
        let endpoint = ShareEndpoint.getLink(file: FileModel.mockFile())
        #expect(endpoint.path == "/share/getLink")
        #expect(endpoint.customURL == nil)
    }

    @Test("Share listing and access requests stay on V1")
    func shareListingIsV1() {
        #expect(ShareEndpoint.getShares.path == "/share/getShares")
        #expect(ShareEndpoint.getShares.customURL == nil)
        #expect(ShareEndpoint.requestShareAccess(token: "t").path == "/share/requestShareAccess")
        #expect(ShareEndpoint.getShareForPreview(shareId: 1, folder_linkId: 2).path == "/share/getShareForPreview")
    }

    @Test("Every archive tag route stays on V1")
    func archiveTagsAreV1() {
        #expect(TagEndpoint.post(params: TagParams(names: [], refID: 1)).path == "/tag/post")
        #expect(TagEndpoint.delete(params: []).path == "/tag/delete")
        #expect(TagEndpoint.getByArchive(params: 1).path == "/tag/getTagsByArchive")
        #expect(TagEndpoint.unlink(params: DeleteTagParams(tagVO: [], refID: 1)).path == "/tag/DeleteTagLink")
        #expect(TagEndpoint.post(params: TagParams(names: [], refID: 1)).customURL == nil)
    }

    @Test("Search stays on V1")
    func searchIsV1() {
        #expect(SearchEndpoint.folderAndRecord(text: "x", tagVOs: []).path == "/search/folderAndRecord")
        #expect(SearchEndpoint.archiveByEmail(email: "a@b.c").path == "/search/archiveByEmail")
        #expect(SearchEndpoint.archiveByEmail(email: "a@b.c").customURL == nil)
    }

    @Test("Members and invites stay on V1")
    func membersAndInvitesAreV1() {
        #expect(MembersEndpoint.members(archiveNbr: "0001-0000").path == "/archive/getShares")
        #expect(MembersEndpoint.members(archiveNbr: "0001-0000").customURL == nil)
        #expect(InviteEndpoint.getMyInvites.path == "/invite/getMyInvites")
        #expect(InviteEndpoint.getMyInvites.customURL == nil)
    }

    @Test("Sign-in and sign-out stay on V1")
    func authIsV1() {
        #expect(AuthenticationEndpoint.verifyAuth.path == "/auth/loggedin")
        #expect(AuthenticationEndpoint.verifyAuth.customURL == nil)
        #expect(AuthenticationEndpoint.logout.path == "/auth/logout")
        #expect(AuthenticationEndpoint.logout.customURL == nil)
        #expect(AuthenticationEndpoint.forgotPassword(email: "a@b.c").path == "/auth/sendEmailForgotPassword")
    }

    @Test("Notifications and relations stay on V1")
    func notificationsAndRelationsAreV1() {
        #expect(NotificationsEndpoint.getMyNotifications.path == "/notification/getMyNotifications")
        #expect(NotificationsEndpoint.getMyNotifications.customURL == nil)
        #expect(RelationEndpoint.getAll(archiveId: 1).path == "/relation/getAll")
        #expect(RelationEndpoint.getAll(archiveId: 1).customURL == nil)
    }

    // MARK: - V1 path text is dead — customURL sends V2

    @Test("Account tags carries a dead V1 path")
    func accountTagsSendsV2() {
        let endpoint = AccountEndpoint.addRemoveTags(archiveType: "type.archive.person",
                                                     addGoalTags: nil,
                                                     addWhyTags: nil,
                                                     removeGoalTags: nil,
                                                     removeWhyTags: nil)
        #expect(endpoint.path == "/account/tags")
        #expect(sendsV2(endpoint, "account/tags"))
    }

    @Test("Gift storage carries a dead V1 path")
    func giftStorageSendsV2() {
        let gift = GiftingModel(storageAmount: 1, recipientEmails: ["a@b.c"], note: nil)
        let endpoint = BillingEndpoint.giftStorage(gift: gift)
        #expect(endpoint.path == "/billing/giftStorage")
        #expect(sendsV2(endpoint, "billing/gift"))
    }

    // MARK: - Live on Stela V2

    @Test("Folder reads go to V2")
    func folderReadsAreV2() {
        #expect(sendsV2(FolderV2Endpoint.getFolderById(folderId: "7", shareToken: ""), "folders?folderIds[]=7"))
        #expect(sendsV2(FolderV2Endpoint.getFolderChildren(folderId: "7", shareToken: "", pageSize: 50),
                        "folders/7/children"))
    }

    @Test("Record read, update and copy go to V2")
    func recordCallsAreV2() {
        #expect(sendsV2(RecordV2Endpoint.getRecordById(recordId: "9", shareToken: nil), "records/9"))
        #expect(sendsV2(RecordV2Endpoint.patchRecord(recordId: "9", fields: [:]), "records/9"))
        #expect(sendsV2(RecordV2Endpoint.copyRecord(recordId: "9", destinationFolderId: "7"), "records/9/copies"))
    }

    @Test("Archive discovery goes to V2")
    func archiveDiscoveryIsV2() {
        let endpoint = ArchiveV2Endpoint.searchArchives(callerMembershipRoles: ArchiveV2Endpoint.allMembershipRoles,
                                                        pageSize: ArchiveV2Endpoint.defaultPageSize)
        #expect(sendsV2(endpoint, "archives"))
    }

    @Test("Every share-link call goes to V2")
    func shareLinkCallsAreV2() {
        #expect(sendsV2(ShareLinksV2Endpoint.createShareLink(file: FileModel.mockFile()), "share-links"))
        #expect(sendsV2(ShareLinksV2Endpoint.getShareLink(shareLinkId: "5"), "share-links?shareLinkIds[]=5"))
        #expect(sendsV2(ShareLinksV2Endpoint.getShareLinkByToken(token: "tok"), "share-links?shareTokens[]=tok"))
        #expect(sendsV2(ShareLinksV2Endpoint.updateShareLink(shareLinkId: "5"), "share-links/5"))
        #expect(sendsV2(ShareLinksV2Endpoint.deleteShareLink(shareLinkId: "5"), "share-links/5"))
    }
}
