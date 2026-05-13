//
//  RelationEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class RelationEndpointTests: XCTestCase {

    private func dict(_ params: RequestParameters?) -> [String: Any]? {
        return params as? [String: Any]
    }

    // MARK: - Path

    func testGetAll_Path() {
        let endpoint = RelationEndpoint.getAll(archiveId: 1)
        XCTAssertEqual(endpoint.path, "/relation/getAll")
    }

    // MARK: - Method

    func testGetAll_UsesPostMethod() {
        let endpoint = RelationEndpoint.getAll(archiveId: 1)
        XCTAssertEqual(endpoint.method, .post)
    }

    // MARK: - Types

    func testRequestType_IsData() {
        let endpoint = RelationEndpoint.getAll(archiveId: 1)
        XCTAssertEqual(endpoint.requestType, .data)
    }

    func testResponseType_IsJSON() {
        let endpoint = RelationEndpoint.getAll(archiveId: 1)
        XCTAssertEqual(endpoint.responseType, .json)
    }

    // MARK: - Nil Properties

    func testBodyData_IsNil() {
        let endpoint = RelationEndpoint.getAll(archiveId: 1)
        XCTAssertNil(endpoint.bodyData)
    }

    func testCustomURL_IsNil() {
        let endpoint = RelationEndpoint.getAll(archiveId: 1)
        XCTAssertNil(endpoint.customURL)
    }

    func testProgressHandler_IsNil() {
        let endpoint = RelationEndpoint.getAll(archiveId: 1)
        XCTAssertNil(endpoint.progressHandler)
    }

    // MARK: - Parameters Structure

    func testGetAll_ContainsRequestVO() {
        let endpoint = RelationEndpoint.getAll(archiveId: 42)
        let params = dict(endpoint.parameters)
        XCTAssertNotNil(params?["RequestVO"])
    }

    func testGetAll_ContainsDataArray() {
        let endpoint = RelationEndpoint.getAll(archiveId: 42)
        let params = dict(endpoint.parameters)
        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertEqual(data?.count, 1)
    }

    func testGetAll_ContainsRelationVO() {
        let endpoint = RelationEndpoint.getAll(archiveId: 42)
        let params = dict(endpoint.parameters)
        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let relationVO = data?.first?["RelationVO"] as? [String: Any]
        XCTAssertNotNil(relationVO)
    }

    func testGetAll_ContainsCorrectArchiveId() {
        let endpoint = RelationEndpoint.getAll(archiveId: 555)
        let params = dict(endpoint.parameters)
        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let relationVO = data?.first?["RelationVO"] as? [String: Any]
        XCTAssertEqual(relationVO?["archiveId"] as? Int, 555)
    }

    func testGetAll_DifferentArchiveId() {
        let endpoint = RelationEndpoint.getAll(archiveId: 999)
        let params = dict(endpoint.parameters)
        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let relationVO = data?.first?["RelationVO"] as? [String: Any]
        XCTAssertEqual(relationVO?["archiveId"] as? Int, 999)
    }
}
