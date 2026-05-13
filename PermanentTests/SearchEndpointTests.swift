//
//  SearchEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class SearchEndpointTests: XCTestCase {

    // MARK: - Paths

    func testFolderAndRecord_Path() {
        let endpoint = SearchEndpoint.folderAndRecord(text: "test", tagVOs: [])
        XCTAssertEqual(endpoint.path, "/search/folderAndRecord")
    }

    func testArchiveByEmail_Path() {
        let endpoint = SearchEndpoint.archiveByEmail(email: "a@b.com")
        XCTAssertEqual(endpoint.path, "/search/archiveByEmail")
    }

    // MARK: - Method

    func testAllEndpoints_UsePostMethod() {
        let endpoints: [SearchEndpoint] = [
            .folderAndRecord(text: "", tagVOs: []),
            .archiveByEmail(email: "")
        ]
        for endpoint in endpoints {
            XCTAssertEqual(endpoint.method, .post)
        }
    }

    // MARK: - Request/Response Types

    func testRequestType_IsData() {
        let endpoint = SearchEndpoint.folderAndRecord(text: "", tagVOs: [])
        XCTAssertEqual(endpoint.requestType, .data)
    }

    func testResponseType_IsJSON() {
        let endpoint = SearchEndpoint.folderAndRecord(text: "", tagVOs: [])
        XCTAssertEqual(endpoint.responseType, .json)
    }

    // MARK: - Nil Properties

    func testBodyData_IsNil() {
        let endpoint = SearchEndpoint.folderAndRecord(text: "", tagVOs: [])
        XCTAssertNil(endpoint.bodyData)
    }

    func testCustomURL_IsNil() {
        let endpoint = SearchEndpoint.folderAndRecord(text: "", tagVOs: [])
        XCTAssertNil(endpoint.customURL)
    }

    func testProgressHandler_IsNil() {
        let endpoint = SearchEndpoint.folderAndRecord(text: "", tagVOs: [])
        XCTAssertNil(endpoint.progressHandler)
    }

    // MARK: - Parameters

    func testFolderAndRecord_HasParameters() {
        let endpoint = SearchEndpoint.folderAndRecord(text: "photo", tagVOs: [])
        XCTAssertNotNil(endpoint.parameters)
    }

    func testArchiveByEmail_HasParameters() {
        let endpoint = SearchEndpoint.archiveByEmail(email: "user@test.com")
        XCTAssertNotNil(endpoint.parameters)
    }
}
