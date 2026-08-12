//
//  InviteEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 05.08.2026.
//

import Foundation
import Testing
@testable import Permanent

/// `InviteEndpoint` is shared by the share-invitation flow and the legacy account-invites screen,
/// so its paths must not drift. Asserts the id handed in is the id that goes out.
@Suite
struct InviteEndpointTests {

    /// `RequestParameters` is `Any`, so the optional cannot be compared against nil directly.
    private func isNil(_ value: Any?) -> Bool {
        if case .none = value { return true }
        return false
    }

    /// Decodes the encoded body back into the payload the API receives.
    private func decodedPayload(_ endpoint: InviteEndpoint) throws -> InviteVOPayloadData {
        let body = try #require(endpoint.bodyData, "Endpoint must encode a body")
        let payload = try APIPayload<InviteVOPayload>.decoder.decode(APIPayload<InviteVOPayload>.self, from: body)
        let first = try #require(payload.requestVO.data.first)
        return first.inviteVO
    }

    // MARK: - Paths

    @Test("Resend posts to /invite/inviteResend")
    func resendPath() {
        #expect(InviteEndpoint.resendInvite(id: 1).path == "/invite/inviteResend")
    }

    @Test("Revoke posts to /invite/revoke")
    func revokePath() {
        #expect(InviteEndpoint.revokeInvite(id: 1).path == "/invite/revoke")
    }

    @Test("The sibling cases keep their paths")
    func siblingPaths() {
        #expect(InviteEndpoint.getMyInvites.path == "/invite/getMyInvites")
        #expect(InviteEndpoint.sendInvite(name: "N", email: "a@b.com").path == "/invite/inviteSend")
    }

    // MARK: - Method and types

    @Test("Resend and revoke are JSON POSTs carrying data")
    func methodAndTypes() {
        for endpoint in [InviteEndpoint.resendInvite(id: 1), .revokeInvite(id: 1)] {
            #expect(endpoint.method == .post)
            #expect(endpoint.requestType == .data)
            #expect(endpoint.responseType == .json)
            #expect(isNil(endpoint.parameters))
            #expect(endpoint.customURL == nil)
        }
    }

    // MARK: - Body encodes the id it was given

    @Test("Resend encodes the id it was given", arguments: [1, 42, 4242, 999_999])
    func resendEncodesId(id: Int) throws {
        let payload = try decodedPayload(.resendInvite(id: id))
        #expect(payload.id == id, "The invite id must reach the API unchanged")
    }

    @Test("Revoke encodes the id it was given", arguments: [1, 42, 4242, 999_999])
    func revokeEncodesId(id: Int) throws {
        let payload = try decodedPayload(.revokeInvite(id: id))
        #expect(payload.id == id, "The invite id must reach the API unchanged")
    }

    @Test("Resend and revoke send only the id")
    func idOnlyPayload() throws {
        for endpoint in [InviteEndpoint.resendInvite(id: 7), .revokeInvite(id: 7)] {
            let payload = try decodedPayload(endpoint)
            #expect(payload.name == nil)
            #expect(payload.email == nil)
        }
    }

    @Test("The id is encoded under the key the API reads")
    func idUsesInviteIdKey() throws {
        let body = try #require(InviteEndpoint.revokeInvite(id: 4242).bodyData)
        let json = try #require(String(data: body, encoding: .utf8))
        #expect(json.contains("inviteId"), "InviteVOPayloadData maps id -> inviteId")
        #expect(json.contains("4242"))
    }
}
