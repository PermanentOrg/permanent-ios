//
//  ShareAccessEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ShareAccessEndpointTests: XCTestCase {

    private func dict(_ params: RequestParameters?) -> [String: Any]? {
        return params as? [String: Any]
    }

    // MARK: - Path

    func testInviteShare_Path() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "test@example.com",
            byArchiveId: 1,
            fullName: "Test User",
            accessRole: "access.role.viewer",
            folderLinkId: 10,
            relationship: "relation.friend"
        )
        XCTAssertEqual(endpoint.path, "/invite/share")
    }

    // MARK: - Method

    func testInviteShare_UsesPostMethod() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com",
            byArchiveId: 1,
            fullName: "Name",
            accessRole: "role",
            folderLinkId: 1,
            relationship: "rel"
        )
        XCTAssertEqual(endpoint.method, .post)
    }

    // MARK: - Request/Response Types

    func testRequestType_IsData() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel"
        )
        XCTAssertEqual(endpoint.requestType, .data)
    }

    func testResponseType_IsJSON() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel"
        )
        XCTAssertEqual(endpoint.responseType, .json)
    }

    func testBodyData_IsNil() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel"
        )
        XCTAssertNil(endpoint.bodyData)
    }

    func testCustomURL_IsNil() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel"
        )
        XCTAssertNil(endpoint.customURL)
    }

    func testProgressHandler_IsNil() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel"
        )
        XCTAssertNil(endpoint.progressHandler)
    }

    // MARK: - Headers

    func testHeaders_ContainsContentType() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel"
        )
        let headers = endpoint.headers
        XCTAssertEqual(headers?["content-type"], "application/json; charset=utf-8")
    }

    func testHeaders_ContainsRequestVersion2() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel"
        )
        let headers = endpoint.headers
        XCTAssertEqual(headers?["Request-Version"], "2")
    }

    // MARK: - Parameters: Base Fields

    func testParameters_ContainsEmail() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "user@test.com", byArchiveId: 5, fullName: "Full Name",
            accessRole: "access.role.editor", folderLinkId: 20, relationship: "relation.friend"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["email"] as? String, "user@test.com")
    }

    func testParameters_ContainsByArchiveId() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 42, fullName: "Name",
            accessRole: "role", folderLinkId: 1, relationship: "rel"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["byArchiveId"] as? Int, 42)
    }

    func testParameters_ContainsFullName() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "John Doe",
            accessRole: "role", folderLinkId: 1, relationship: "rel"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["fullName"] as? String, "John Doe")
    }

    func testParameters_ContainsAccessRole() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "access.role.curator", folderLinkId: 1, relationship: "rel"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["accessRole"] as? String, "access.role.curator")
    }

    func testParameters_ContainsFolderLinkId() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 99, relationship: "rel"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["folderLinkId"] as? Int, 99)
    }

    func testParameters_ContainsRelationship() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "relation.family"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["relationship"] as? String, "relation.family")
    }

    // MARK: - Parameters: Optional recordId / folderId

    func testParameters_WithRecordId_ContainsRecordId() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel",
            recordId: 500
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["recordId"] as? Int, 500)
    }

    func testParameters_WithRecordId_DoesNotContainFolderId() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel",
            folderId: 300, recordId: 500
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["recordId"] as? Int, 500)
        XCTAssertNil(params?["folderId"])
    }

    func testParameters_WithFolderIdOnly_ContainsFolderId() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel",
            folderId: 300
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["folderId"] as? Int, 300)
    }

    func testParameters_WithFolderIdOnly_DoesNotContainRecordId() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel",
            folderId: 300
        )
        let params = dict(endpoint.parameters)
        XCTAssertNil(params?["recordId"])
    }

    func testParameters_NoOptionalIds_DoesNotContainRecordIdOrFolderId() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel"
        )
        let params = dict(endpoint.parameters)
        XCTAssertNil(params?["recordId"])
        XCTAssertNil(params?["folderId"])
    }

    func testParameters_RecordIdTakesPriorityOverFolderId() {
        let endpoint = ShareAccessEndpoint.inviteShare(
            email: "a@b.com", byArchiveId: 1, fullName: "N",
            accessRole: "r", folderLinkId: 1, relationship: "rel",
            folderId: 10, recordId: 20
        )
        let params = dict(endpoint.parameters)
        XCTAssertNotNil(params?["recordId"])
        XCTAssertNil(params?["folderId"])
    }
}
