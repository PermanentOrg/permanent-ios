//
//  ShareEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ShareEndpointTests: XCTestCase {

    // MARK: - Helpers

    private func makeFile() -> FileModel {
        return FileModel(
            name: "photo.jpg",
            recordId: 100,
            folderLinkId: 1,
            archiveNbr: "0001-0000",
            type: "type.record.image",
            permissions: [.read]
        )
    }

    private func makeFolderFile() -> FileModel {
        return FileModel(
            name: "TestFolder",
            recordId: 0,
            folderLinkId: 2,
            archiveNbr: "0001-0000",
            type: "type.folder.private",
            permissions: [.read]
        )
    }

    // MARK: - Path Tests

    func testGetLink_Path() {
        let endpoint = ShareEndpoint.getLink(file: makeFile())
        XCTAssertEqual(endpoint.path, "/share/getLink")
    }

    func testGenerateShareLink_Path() {
        let endpoint = ShareEndpoint.generateShareLink(file: makeFile())
        XCTAssertEqual(endpoint.path, "/share/generateShareLink")
    }

    func testRevokeLink_Path() {
        let link = SharebyURLVOData(sharebyURLID: nil, status: nil, urlToken: nil, folderLinkID: nil, shareURL: nil, uses: nil, maxUses: nil, autoApproveToggle: nil, previewToggle: nil, defaultAccessRole: nil, expiresDT: nil, byAccountID: nil, byArchiveID: nil, createdDT: nil, updatedDT: nil, accountVO: nil, folderData: nil, recordData: nil, archiveVO: nil, shareVO: nil)
        let endpoint = ShareEndpoint.revokeLink(link: link)
        XCTAssertEqual(endpoint.path, "/share/dropShareLink")
    }

    func testUpdateShareLink_Path() {
        let link = SharebyURLVOData(sharebyURLID: nil, status: nil, urlToken: nil, folderLinkID: nil, shareURL: nil, uses: nil, maxUses: nil, autoApproveToggle: nil, previewToggle: nil, defaultAccessRole: nil, expiresDT: nil, byAccountID: nil, byArchiveID: nil, createdDT: nil, updatedDT: nil, accountVO: nil, folderData: nil, recordData: nil, archiveVO: nil, shareVO: nil)
        let endpoint = ShareEndpoint.updateShareLink(link: link)
        XCTAssertEqual(endpoint.path, "/share/updateShareLink")
    }

    func testGetShares_Path() {
        let endpoint = ShareEndpoint.getShares
        XCTAssertEqual(endpoint.path, "/share/getShares")
    }

    func testCheckLink_Path() {
        let endpoint = ShareEndpoint.checkLink(token: "abc123")
        XCTAssertEqual(endpoint.path, "/share/checkShareLink")
    }

    func testRequestShareAccess_Path() {
        let endpoint = ShareEndpoint.requestShareAccess(token: "token456")
        XCTAssertEqual(endpoint.path, "/share/requestShareAccess")
    }

    func testGetShareForPreview_Path() {
        let endpoint = ShareEndpoint.getShareForPreview(shareId: 10, folder_linkId: 20)
        XCTAssertEqual(endpoint.path, "/share/getShareForPreview")
    }

    // MARK: - Method Tests

    func testAllEndpoints_MethodIsPost() {
        let file = makeFile()
        let link = SharebyURLVOData(sharebyURLID: nil, status: nil, urlToken: nil, folderLinkID: nil, shareURL: nil, uses: nil, maxUses: nil, autoApproveToggle: nil, previewToggle: nil, defaultAccessRole: nil, expiresDT: nil, byAccountID: nil, byArchiveID: nil, createdDT: nil, updatedDT: nil, accountVO: nil, folderData: nil, recordData: nil, archiveVO: nil, shareVO: nil)

        let endpoints: [ShareEndpoint] = [
            .getLink(file: file),
            .generateShareLink(file: file),
            .revokeLink(link: link),
            .updateShareLink(link: link),
            .getShares,
            .checkLink(token: "t"),
            .requestShareAccess(token: "t"),
            .getShareForPreview(shareId: 1, folder_linkId: 2)
        ]

        for endpoint in endpoints {
            XCTAssertEqual(endpoint.method, .post, "All ShareEndpoint cases should use POST")
        }
    }

    // MARK: - RequestType / ResponseType Tests

    func testAllEndpoints_RequestTypeIsData() {
        let file = makeFile()
        let endpoints: [ShareEndpoint] = [
            .getLink(file: file),
            .generateShareLink(file: file),
            .getShares,
            .checkLink(token: "t"),
            .requestShareAccess(token: "t"),
            .getShareForPreview(shareId: 1, folder_linkId: 2)
        ]

        for endpoint in endpoints {
            XCTAssertEqual(endpoint.requestType, .data, "requestType should be .data")
        }
    }

    func testAllEndpoints_ResponseTypeIsJson() {
        let file = makeFile()
        let endpoints: [ShareEndpoint] = [
            .getLink(file: file),
            .generateShareLink(file: file),
            .getShares,
            .checkLink(token: "t"),
            .requestShareAccess(token: "t"),
            .getShareForPreview(shareId: 1, folder_linkId: 2)
        ]

        for endpoint in endpoints {
            XCTAssertEqual(endpoint.responseType, .json, "responseType should be .json")
        }
    }

    // MARK: - CustomURL Tests

    func testAllEndpoints_CustomURLIsNil() {
        let file = makeFile()
        let link = SharebyURLVOData(sharebyURLID: nil, status: nil, urlToken: nil, folderLinkID: nil, shareURL: nil, uses: nil, maxUses: nil, autoApproveToggle: nil, previewToggle: nil, defaultAccessRole: nil, expiresDT: nil, byAccountID: nil, byArchiveID: nil, createdDT: nil, updatedDT: nil, accountVO: nil, folderData: nil, recordData: nil, archiveVO: nil, shareVO: nil)

        let endpoints: [ShareEndpoint] = [
            .getLink(file: file),
            .generateShareLink(file: file),
            .revokeLink(link: link),
            .updateShareLink(link: link),
            .getShares,
            .checkLink(token: "t"),
            .requestShareAccess(token: "t"),
            .getShareForPreview(shareId: 1, folder_linkId: 2)
        ]

        for endpoint in endpoints {
            XCTAssertNil(endpoint.customURL, "customURL should be nil for \(endpoint)")
        }
    }

    // MARK: - ProgressHandler Tests

    func testAllEndpoints_ProgressHandlerIsNil() {
        let file = makeFile()
        let endpoints: [ShareEndpoint] = [
            .getLink(file: file),
            .generateShareLink(file: file),
            .getShares,
            .checkLink(token: "t"),
            .requestShareAccess(token: "t"),
            .getShareForPreview(shareId: 1, folder_linkId: 2)
        ]

        for endpoint in endpoints {
            XCTAssertNil(endpoint.progressHandler, "progressHandler should be nil")
        }
    }

    // MARK: - Parameters Tests

    func testGetShareForPreview_ParametersAreNotNil() {
        let endpoint = ShareEndpoint.getShareForPreview(shareId: 10, folder_linkId: 20)
        XCTAssertNotNil(endpoint.parameters)
    }

    func testGetShareForPreview_ParametersContainRequestVO() {
        let endpoint = ShareEndpoint.getShareForPreview(shareId: 10, folder_linkId: 20)
        let params = endpoint.parameters as? [String: Any]
        XCTAssertNotNil(params?["RequestVO"], "Parameters should contain RequestVO key")
    }

    func testGetShareForPreview_ShareVOContainsShareIdAsString() {
        let endpoint = ShareEndpoint.getShareForPreview(shareId: 55, folder_linkId: 77)
        let params = endpoint.parameters as? [String: Any]
        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let shareVO = data?.first?["ShareVO"] as? [String: Any]

        XCTAssertEqual(shareVO?["shareId"] as? String, "55")
    }

    func testGetShareForPreview_ShareVOContainsFolderLinkIdAsString() {
        let endpoint = ShareEndpoint.getShareForPreview(shareId: 55, folder_linkId: 77)
        let params = endpoint.parameters as? [String: Any]
        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let shareVO = data?.first?["ShareVO"] as? [String: Any]

        XCTAssertEqual(shareVO?["folder_linkId"] as? String, "77")
    }

    func testGetLink_ParametersAreNil() {
        let endpoint = ShareEndpoint.getLink(file: makeFile())
        XCTAssertNil(endpoint.parameters)
    }

    func testGenerateShareLink_ParametersAreNil() {
        let endpoint = ShareEndpoint.generateShareLink(file: makeFile())
        XCTAssertNil(endpoint.parameters)
    }

    func testGetShares_ParametersAreNil() {
        let endpoint = ShareEndpoint.getShares
        XCTAssertNil(endpoint.parameters)
    }

    func testCheckLink_ParametersAreNil() {
        let endpoint = ShareEndpoint.checkLink(token: "abc")
        XCTAssertNil(endpoint.parameters)
    }

    func testRequestShareAccess_ParametersAreNil() {
        let endpoint = ShareEndpoint.requestShareAccess(token: "abc")
        XCTAssertNil(endpoint.parameters)
    }

    // MARK: - BodyData Tests

    func testGetLink_BodyDataIsNotNil() {
        let endpoint = ShareEndpoint.getLink(file: makeFile())
        XCTAssertNotNil(endpoint.bodyData, "getLink should produce bodyData for a record file")
    }

    func testGenerateShareLink_BodyDataIsNotNil() {
        let endpoint = ShareEndpoint.generateShareLink(file: makeFile())
        XCTAssertNotNil(endpoint.bodyData, "generateShareLink should produce bodyData for a record file")
    }

    func testCheckLink_BodyDataIsNotNil() {
        let endpoint = ShareEndpoint.checkLink(token: "someToken")
        XCTAssertNotNil(endpoint.bodyData, "checkLink should produce bodyData with token")
    }

    func testRequestShareAccess_BodyDataIsNotNil() {
        let endpoint = ShareEndpoint.requestShareAccess(token: "someToken")
        XCTAssertNotNil(endpoint.bodyData, "requestShareAccess should produce bodyData with token")
    }

    func testGetShares_BodyDataIsNil() {
        let endpoint = ShareEndpoint.getShares
        XCTAssertNil(endpoint.bodyData, "getShares should not have bodyData")
    }

    func testGetShareForPreview_BodyDataIsNil() {
        let endpoint = ShareEndpoint.getShareForPreview(shareId: 1, folder_linkId: 2)
        XCTAssertNil(endpoint.bodyData, "getShareForPreview should not have bodyData")
    }

    func testGetLink_WithFolder_BodyDataIsNotNil() {
        let endpoint = ShareEndpoint.getLink(file: makeFolderFile())
        XCTAssertNotNil(endpoint.bodyData, "getLink should produce bodyData for a folder file")
    }

    func testGenerateShareLink_WithFolder_BodyDataIsNotNil() {
        let endpoint = ShareEndpoint.generateShareLink(file: makeFolderFile())
        XCTAssertNotNil(endpoint.bodyData, "generateShareLink should produce bodyData for a folder file")
    }
}
