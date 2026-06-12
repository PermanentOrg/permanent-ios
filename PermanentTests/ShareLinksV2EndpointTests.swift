//
//  ShareLinksV2EndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ShareLinksV2EndpointTests: XCTestCase {

    private func dict(_ params: RequestParameters?) -> [String: Any]? {
        return params as? [String: Any]
    }

    private func makeRecordFile() -> FileModel {
        return FileModel(
            name: "photo.jpg",
            recordId: 100,
            folderLinkId: 1,
            archiveNbr: "0001-0000",
            type: "type.record.image",
            permissions: [.read, .share]
        )
    }

    private func makeFolderFile() -> FileModel {
        return FileModel(
            name: "My Folder",
            recordId: 200,
            folderLinkId: 2,
            archiveNbr: "0001-0000",
            type: "type.folder.public",
            permissions: [.read]
        )
    }

    // MARK: - Method

    func testCreateShareLink_UsesPostMethod() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        XCTAssertEqual(endpoint.method, .post)
    }

    func testUpdateShareLink_UsesPatchMethod() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(shareLinkId: "abc")
        XCTAssertEqual(endpoint.method, .patch)
    }

    func testGetShareLink_UsesGetMethod() {
        let endpoint = ShareLinksV2Endpoint.getShareLink(shareLinkId: "abc")
        XCTAssertEqual(endpoint.method, .get)
    }

    func testGetShareLinkByToken_UsesGetMethod() {
        let endpoint = ShareLinksV2Endpoint.getShareLinkByToken(token: "tok")
        XCTAssertEqual(endpoint.method, .get)
    }

    func testDeleteShareLink_UsesDeleteMethod() {
        let endpoint = ShareLinksV2Endpoint.deleteShareLink(shareLinkId: "abc")
        XCTAssertEqual(endpoint.method, .delete)
    }

    // MARK: - Request/Response Types

    func testAllEndpoints_RequestTypeIsData() {
        let endpoints: [ShareLinksV2Endpoint] = [
            .createShareLink(file: makeRecordFile()),
            .updateShareLink(shareLinkId: "x"),
            .getShareLink(shareLinkId: "x"),
            .getShareLinkByToken(token: "t"),
            .deleteShareLink(shareLinkId: "x")
        ]
        for endpoint in endpoints {
            XCTAssertEqual(endpoint.requestType, .data)
        }
    }

    func testAllEndpoints_ResponseTypeIsJSON() {
        let endpoints: [ShareLinksV2Endpoint] = [
            .createShareLink(file: makeRecordFile()),
            .updateShareLink(shareLinkId: "x"),
            .getShareLink(shareLinkId: "x"),
            .getShareLinkByToken(token: "t"),
            .deleteShareLink(shareLinkId: "x")
        ]
        for endpoint in endpoints {
            XCTAssertEqual(endpoint.responseType, .json)
        }
    }

    // MARK: - skipAuthentication

    func testSkipAuthentication_GetShareLinkByToken_ReturnsTrue() {
        let endpoint = ShareLinksV2Endpoint.getShareLinkByToken(token: "tok")
        XCTAssertTrue(endpoint.skipAuthentication)
    }

    func testSkipAuthentication_CreateShareLink_ReturnsFalse() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        XCTAssertFalse(endpoint.skipAuthentication)
    }

    func testSkipAuthentication_UpdateShareLink_ReturnsFalse() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(shareLinkId: "x")
        XCTAssertFalse(endpoint.skipAuthentication)
    }

    func testSkipAuthentication_GetShareLink_ReturnsFalse() {
        let endpoint = ShareLinksV2Endpoint.getShareLink(shareLinkId: "x")
        XCTAssertFalse(endpoint.skipAuthentication)
    }

    func testSkipAuthentication_DeleteShareLink_ReturnsFalse() {
        let endpoint = ShareLinksV2Endpoint.deleteShareLink(shareLinkId: "x")
        XCTAssertFalse(endpoint.skipAuthentication)
    }

    // MARK: - Headers

    func testCreateShareLink_HasContentTypeHeader() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        XCTAssertEqual(endpoint.headers?["content-type"], "application/json; charset=utf-8")
    }

    func testUpdateShareLink_HasContentTypeHeader() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(shareLinkId: "x")
        XCTAssertEqual(endpoint.headers?["content-type"], "application/json; charset=utf-8")
    }

    func testGetShareLink_HasNoHeaders() {
        let endpoint = ShareLinksV2Endpoint.getShareLink(shareLinkId: "x")
        XCTAssertNil(endpoint.headers)
    }

    func testGetShareLinkByToken_HasRequestVersion2() {
        let endpoint = ShareLinksV2Endpoint.getShareLinkByToken(token: "t")
        XCTAssertEqual(endpoint.headers?["Request-Version"], "2")
    }

    func testDeleteShareLink_HasNoHeaders() {
        let endpoint = ShareLinksV2Endpoint.deleteShareLink(shareLinkId: "x")
        XCTAssertNil(endpoint.headers)
    }

    // MARK: - customURL

    func testCustomURL_CreateShareLink_ContainsShareLinksPath() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        XCTAssertTrue(endpoint.customURL?.contains("api/v2/share-links") == true)
    }

    func testCustomURL_UpdateShareLink_ContainsShareLinkId() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(shareLinkId: "link-42")
        XCTAssertTrue(endpoint.customURL?.contains("api/v2/share-links/link-42") == true)
    }

    func testCustomURL_GetShareLink_ContainsQueryParam() {
        let endpoint = ShareLinksV2Endpoint.getShareLink(shareLinkId: "link-99")
        XCTAssertTrue(endpoint.customURL?.contains("shareLinkIds[]=link-99") == true)
    }

    func testCustomURL_GetShareLinkByToken_ContainsTokenParam() {
        let endpoint = ShareLinksV2Endpoint.getShareLinkByToken(token: "my-token")
        XCTAssertTrue(endpoint.customURL?.contains("shareTokens[]=my-token") == true)
    }

    func testCustomURL_DeleteShareLink_ContainsShareLinkId() {
        let endpoint = ShareLinksV2Endpoint.deleteShareLink(shareLinkId: "link-del")
        XCTAssertTrue(endpoint.customURL?.contains("api/v2/share-links/link-del") == true)
    }

    // MARK: - Parameters: nil for GET/DELETE

    func testGetShareLink_ParametersAreNil() {
        let endpoint = ShareLinksV2Endpoint.getShareLink(shareLinkId: "x")
        XCTAssertNil(endpoint.parameters)
    }

    func testGetShareLinkByToken_ParametersAreNil() {
        let endpoint = ShareLinksV2Endpoint.getShareLinkByToken(token: "t")
        XCTAssertNil(endpoint.parameters)
    }

    func testDeleteShareLink_ParametersAreNil() {
        let endpoint = ShareLinksV2Endpoint.deleteShareLink(shareLinkId: "x")
        XCTAssertNil(endpoint.parameters)
    }

    // MARK: - createShareLink Parameters

    func testCreateShareLink_Record_ContainsItemTypeRecord() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["itemType"] as? String, "record")
    }

    func testCreateShareLink_Folder_ContainsItemTypeFolder() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeFolderFile())
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["itemType"] as? String, "folder")
    }

    func testCreateShareLink_DefaultPermissionsLevel() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["permissionsLevel"] as? String, "viewer")
    }

    func testCreateShareLink_DefaultAccessRestrictions() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["accessRestrictions"] as? String, "none")
    }

    func testCreateShareLink_CustomPermissionsLevel() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(
            file: makeRecordFile(), permissionsLevel: "editor"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["permissionsLevel"] as? String, "editor")
    }

    func testCreateShareLink_WithMaxUses() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(
            file: makeRecordFile(), maxUses: 5
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["maxUses"] as? Int, 5)
    }

    func testCreateShareLink_WithoutMaxUses_NoMaxUsesKey() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        let params = dict(endpoint.parameters)
        XCTAssertNil(params?["maxUses"])
    }

    func testCreateShareLink_WithExpiration() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(
            file: makeRecordFile(), expirationTimestamp: "2026-12-31T23:59:59"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["expirationTimestamp"] as? String, "2026-12-31T23:59:59")
    }

    func testCreateShareLink_WithoutExpiration_NoExpirationKey() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        let params = dict(endpoint.parameters)
        XCTAssertNil(params?["expirationTimestamp"])
    }

    func testCreateShareLink_ContainsItemId() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        let params = dict(endpoint.parameters)
        XCTAssertNotNil(params?["itemId"])
    }

    // MARK: - updateShareLinkParameters

    func testUpdateShareLink_WithPermissionsLevel() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(
            shareLinkId: "link-1", permissionsLevel: "editor"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["permissionsLevel"] as? String, "editor")
    }

    func testUpdateShareLink_WithAccessRestrictions() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(
            shareLinkId: "link-1", accessRestrictions: "account"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["accessRestrictions"] as? String, "account")
    }

    func testUpdateShareLink_WithMaxUses() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(
            shareLinkId: "link-1", maxUses: 10
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["maxUses"] as? Int, 10)
    }

    func testUpdateShareLink_WithExpiration() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(
            shareLinkId: "link-1", expirationTimestamp: "2027-01-01"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?["expirationTimestamp"] as? String, "2027-01-01")
    }

    func testUpdateShareLink_NullExpiration_SetsNSNull() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(
            shareLinkId: "link-1", expirationTimestamp: "null"
        )
        let params = dict(endpoint.parameters)
        XCTAssertTrue(params?["expirationTimestamp"] is NSNull)
    }

    func testUpdateShareLink_NoParams_ReturnsEmptyDict() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(shareLinkId: "link-1")
        let params = dict(endpoint.parameters)
        XCTAssertNotNil(params)
        XCTAssertTrue(params?.isEmpty == true)
    }

    func testUpdateShareLink_AllParams() {
        let endpoint = ShareLinksV2Endpoint.updateShareLink(
            shareLinkId: "link-1",
            permissionsLevel: "viewer",
            accessRestrictions: "none",
            maxUses: 3,
            expirationTimestamp: "2026-06-01"
        )
        let params = dict(endpoint.parameters)
        XCTAssertEqual(params?.count, 4)
    }

    // MARK: - bodyData and path

    func testBodyData_IsNil() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        XCTAssertNil(endpoint.bodyData)
    }

    func testPath_IsEmpty() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        XCTAssertTrue(endpoint.path.isEmpty)
    }

    func testProgressHandler_IsNil() {
        let endpoint = ShareLinksV2Endpoint.createShareLink(file: makeRecordFile())
        XCTAssertNil(endpoint.progressHandler)
    }
}
