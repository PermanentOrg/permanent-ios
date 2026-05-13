//
//  TagEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class TagEndpointTests: XCTestCase {

    private func dict(_ params: RequestParameters?) -> [String: Any]? {
        return params as? [String: Any]
    }

    // MARK: - Paths

    func testPost_Path() {
        let endpoint = TagEndpoint.post(params: (names: ["tag1"], refID: 1))
        XCTAssertEqual(endpoint.path, "/tag/post")
    }

    func testDelete_Path() {
        let endpoint = TagEndpoint.delete(params: [])
        XCTAssertEqual(endpoint.path, "/tag/delete")
    }

    func testGetByArchive_Path() {
        let endpoint = TagEndpoint.getByArchive(params: 1)
        XCTAssertEqual(endpoint.path, "/tag/getTagsByArchive")
    }

    func testUnlink_Path() {
        let endpoint = TagEndpoint.unlink(params: (tagVO: [], refID: 1))
        XCTAssertEqual(endpoint.path, "/tag/DeleteTagLink")
    }

    func testUpdateTag_Path() {
        let tag = TagVO(tagVO: TagVOData(name: "old", status: nil, tagId: 1, type: nil, createdDT: nil, updatedDT: nil))
        let endpoint = TagEndpoint.updateTag(params: (tag: tag, newTagName: "new", archiveId: 10))
        XCTAssertEqual(endpoint.path, "/tag/updateTag")
    }

    // MARK: - Method

    func testAllEndpoints_UsePostMethod() {
        let endpoints: [TagEndpoint] = [
            .post(params: (names: [], refID: 0)),
            .delete(params: []),
            .getByArchive(params: 0),
            .unlink(params: (tagVO: [], refID: 0)),
            .updateTag(params: (tag: TagVO(tagVO: TagVOData(name: nil, status: nil, tagId: 1, type: nil, createdDT: nil, updatedDT: nil)), newTagName: "", archiveId: 0))
        ]

        for endpoint in endpoints {
            XCTAssertEqual(endpoint.method, .post, "All TagEndpoint cases should use POST method")
        }
    }

    // MARK: - Request/Response Types

    func testRequestType_IsData() {
        let endpoint = TagEndpoint.post(params: (names: ["a"], refID: 1))
        XCTAssertEqual(endpoint.requestType, .data)
    }

    func testResponseType_IsJSON() {
        let endpoint = TagEndpoint.post(params: (names: ["a"], refID: 1))
        XCTAssertEqual(endpoint.responseType, .json)
    }

    func testBodyData_IsNil() {
        let endpoint = TagEndpoint.post(params: (names: ["a"], refID: 1))
        XCTAssertNil(endpoint.bodyData)
    }

    func testCustomURL_IsNil() {
        let endpoint = TagEndpoint.post(params: (names: ["a"], refID: 1))
        XCTAssertNil(endpoint.customURL)
    }

    func testProgressHandler_IsNil() {
        let endpoint = TagEndpoint.post(params: (names: ["a"], refID: 1))
        XCTAssertNil(endpoint.progressHandler)
    }

    // MARK: - tagPost Parameters

    func testTagPost_SingleTag_StructureIsCorrect() {
        let endpoint = TagEndpoint.post(params: (names: ["MyTag"], refID: 42))
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        XCTAssertNotNil(requestVO)

        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertEqual(data?.count, 1)

        let firstEntry = data?.first
        let tagLinkVO = firstEntry?["TagLinkVO"] as? [String: Any]
        XCTAssertEqual(tagLinkVO?["refId"] as? Int, 42)
        XCTAssertEqual(tagLinkVO?["refTable"] as? String, "record")

        let tagVO = firstEntry?["TagVO"] as? [String: Any]
        XCTAssertEqual(tagVO?["name"] as? String, "MyTag")
    }

    func testTagPost_MultipleTags_CreatesMultipleEntries() {
        let endpoint = TagEndpoint.post(params: (names: ["Tag1", "Tag2", "Tag3"], refID: 10))
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertEqual(data?.count, 3)
    }

    func testTagPost_EmptyNames_CreatesEmptyData() {
        let endpoint = TagEndpoint.post(params: (names: [], refID: 1))
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertEqual(data?.count, 0)
    }

    // MARK: - getTagsByArchive Parameters

    func testGetTagsByArchive_ContainsArchiveId() {
        let endpoint = TagEndpoint.getByArchive(params: 555)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]
        XCTAssertEqual(archiveVO?["archiveId"] as? Int, 555)
    }

    // MARK: - deleteTagPost Parameters

    func testDeleteTagPost_ContainsTagId() {
        let tagData = TagVOData(name: "ToDelete", status: nil, tagId: 99, type: nil, createdDT: nil, updatedDT: nil)
        let tag = TagVO(tagVO: tagData)
        let endpoint = TagEndpoint.delete(params: [tag])
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let tagVO = data?.first?["TagVO"] as? [String: Any]
        XCTAssertEqual(tagVO?["tagId"] as? Int, 99)
    }

    func testDeleteTagPost_MultipleTags() {
        let tag1 = TagVO(tagVO: TagVOData(name: "A", status: nil, tagId: 1, type: nil, createdDT: nil, updatedDT: nil))
        let tag2 = TagVO(tagVO: TagVOData(name: "B", status: nil, tagId: 2, type: nil, createdDT: nil, updatedDT: nil))
        let endpoint = TagEndpoint.delete(params: [tag1, tag2])
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertEqual(data?.count, 2)
    }

    func testDeleteTagPost_NilTagId_DefaultsToZero() {
        let tag = TagVO(tagVO: TagVOData(name: "X", status: nil, tagId: nil, type: nil, createdDT: nil, updatedDT: nil))
        let endpoint = TagEndpoint.delete(params: [tag])
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let tagVO = data?.first?["TagVO"] as? [String: Any]
        XCTAssertEqual(tagVO?["tagId"] as? Int, 0)
    }

    // MARK: - deleteTagLinkPost Parameters

    func testDeleteTagLinkPost_ContainsRefIdAndTagData() {
        let tagData = TagVOData(name: "Linked", status: nil, tagId: 77, type: nil, createdDT: nil, updatedDT: nil)
        let tag = TagVO(tagVO: tagData)
        let endpoint = TagEndpoint.unlink(params: (tagVO: [tag], refID: 200))
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertEqual(data?.count, 1)

        let entry = data?.first
        let tagLinkVO = entry?["TagLinkVO"] as? [String: Any]
        XCTAssertEqual(tagLinkVO?["refId"] as? Int, 200)
        XCTAssertEqual(tagLinkVO?["refTable"] as? String, "record")

        let tagVO = entry?["TagVO"] as? [String: Any]
        XCTAssertEqual(tagVO?["name"] as? String, "Linked")
        XCTAssertEqual(tagVO?["tagId"] as? Int, 77)
    }

    // MARK: - updateTagPost Parameters

    func testUpdateTagPost_ContainsNewNameAndIds() {
        let tagData = TagVOData(name: "OldName", status: nil, tagId: 33, type: nil, createdDT: nil, updatedDT: nil)
        let tag = TagVO(tagVO: tagData)
        let endpoint = TagEndpoint.updateTag(params: (tag: tag, newTagName: "NewName", archiveId: 100))
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let tagVO = data?.first?["TagVO"] as? [String: Any]

        XCTAssertEqual(tagVO?["name"] as? String, "NewName")
        XCTAssertEqual(tagVO?["archiveId"] as? Int, 100)
        XCTAssertEqual(tagVO?["tagId"] as? Int, 33)
    }

    func testUpdateTagPost_NilTagId_ReturnsEmptyParams() {
        let tagData = TagVOData(name: "Name", status: nil, tagId: nil, type: nil, createdDT: nil, updatedDT: nil)
        let tag = TagVO(tagVO: tagData)
        let endpoint = TagEndpoint.updateTag(params: (tag: tag, newTagName: "New", archiveId: 1))
        let params = endpoint.parameters

        let paramsArray = params as? [Any]
        XCTAssertTrue(paramsArray?.isEmpty == true, "Should return empty params when tagId is nil")
    }
}
