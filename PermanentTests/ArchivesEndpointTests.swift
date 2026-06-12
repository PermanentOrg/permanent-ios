//
//  ArchivesEndpointTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ArchivesEndpointTests: XCTestCase {

    // MARK: - Helpers

    private func dict(_ params: RequestParameters?) -> [String: Any]? {
        return params as? [String: Any]
    }

    private func mockArchiveVOData(archiveID: Int = 42, archiveNbr: String = "0001-0000", type: String = "type.archive.person") -> ArchiveVOData {
        return ArchiveVOData(
            childFolderVOS: nil,
            folderSizeVOS: nil,
            recordVOS: nil,
            accessRole: "access.role.owner",
            fullName: "Test Archive",
            spaceTotal: nil,
            spaceLeft: nil,
            fileTotal: nil,
            fileLeft: nil,
            relationType: nil,
            homeCity: nil,
            homeState: nil,
            homeCountry: nil,
            itemVOS: nil,
            birthDay: nil,
            company: nil,
            archiveVODescription: nil,
            archiveID: archiveID,
            publicDT: nil,
            archiveNbr: archiveNbr,
            view: nil,
            viewProperty: nil,
            archiveVOPublic: nil,
            vaultKey: nil,
            thumbArchiveNbr: nil,
            type: type,
            thumbStatus: nil,
            imageRatio: nil,
            thumbnail256: nil,
            thumbURL200: nil,
            thumbURL500: nil,
            thumbURL1000: nil,
            thumbURL2000: nil,
            thumbDT: nil,
            createdDT: nil,
            updatedDT: nil,
            status: nil
        )
    }

    private func mockFileModel() -> FileModel {
        return FileModel(
            name: "photo.jpg",
            recordId: 100,
            folderLinkId: 1,
            archiveNbr: "0001-0000",
            type: "type.record.image",
            permissions: [.read]
        )
    }

    private var allEndpoints: [ArchivesEndpoint] {
        let archiveVO = mockArchiveVOData()
        let file = mockFileModel()
        return [
            .getArchivesByAccountId(accountId: 1),
            .change(archiveId: 10, archiveNbr: "0001-0000"),
            .create(name: "New", type: "type.archive.person"),
            .delete(archiveId: 10, archiveNbr: "0001-0000"),
            .accept(archiveVO: archiveVO),
            .decline(archiveVO: archiveVO),
            .update(archiveVO: archiveVO, file: file),
            .transferOwnership(archiveNbr: "0001-0000", primaryEmail: "test@example.com"),
            .getArchivesByArchivesNbr(archivesNbr: ["0001-0000"]),
            .searchArchive(searchAfter: "query")
        ]
    }

    // MARK: - Paths

    func testGetArchivesByAccountId_Path() {
        let endpoint = ArchivesEndpoint.getArchivesByAccountId(accountId: 1)
        XCTAssertEqual(endpoint.path, "/archive/getAllArchives")
    }

    func testChange_Path() {
        let endpoint = ArchivesEndpoint.change(archiveId: 10, archiveNbr: "0001-0000")
        XCTAssertEqual(endpoint.path, "/archive/change")
    }

    func testCreate_Path() {
        let endpoint = ArchivesEndpoint.create(name: "New", type: "type.archive.person")
        XCTAssertEqual(endpoint.path, "/archive/post")
    }

    func testDelete_Path() {
        let endpoint = ArchivesEndpoint.delete(archiveId: 10, archiveNbr: "0001-0000")
        XCTAssertEqual(endpoint.path, "/archive/delete")
    }

    func testAccept_Path() {
        let endpoint = ArchivesEndpoint.accept(archiveVO: mockArchiveVOData())
        XCTAssertEqual(endpoint.path, "/archive/accept")
    }

    func testDecline_Path() {
        let endpoint = ArchivesEndpoint.decline(archiveVO: mockArchiveVOData())
        XCTAssertEqual(endpoint.path, "/archive/decline")
    }

    func testUpdate_Path() {
        let endpoint = ArchivesEndpoint.update(archiveVO: mockArchiveVOData(), file: mockFileModel())
        XCTAssertEqual(endpoint.path, "/archive/update")
    }

    func testTransferOwnership_Path() {
        let endpoint = ArchivesEndpoint.transferOwnership(archiveNbr: "0001-0000", primaryEmail: "test@example.com")
        XCTAssertEqual(endpoint.path, "/archive/transferOwnership")
    }

    func testGetArchivesByArchivesNbr_Path() {
        let endpoint = ArchivesEndpoint.getArchivesByArchivesNbr(archivesNbr: ["0001-0000"])
        XCTAssertEqual(endpoint.path, "/archive/get")
    }

    func testSearchArchive_Path() {
        let endpoint = ArchivesEndpoint.searchArchive(searchAfter: "query")
        XCTAssertEqual(endpoint.path, "/search/archive")
    }

    // MARK: - Method

    func testAllEndpoints_UsePostMethod() {
        for endpoint in allEndpoints {
            XCTAssertEqual(endpoint.method, .post, "All ArchivesEndpoint cases should use POST method")
        }
    }

    // MARK: - Request/Response Types

    func testAllEndpoints_RequestType_IsData() {
        for endpoint in allEndpoints {
            XCTAssertEqual(endpoint.requestType, .data, "All ArchivesEndpoint cases should use .data request type")
        }
    }

    func testAllEndpoints_ResponseType_IsJSON() {
        for endpoint in allEndpoints {
            XCTAssertEqual(endpoint.responseType, .json, "All ArchivesEndpoint cases should use .json response type")
        }
    }

    // MARK: - Nil Properties

    func testAllEndpoints_BodyData_IsNil() {
        for endpoint in allEndpoints {
            XCTAssertNil(endpoint.bodyData)
        }
    }

    func testAllEndpoints_CustomURL_IsNil() {
        for endpoint in allEndpoints {
            XCTAssertNil(endpoint.customURL)
        }
    }

    func testAllEndpoints_ProgressHandler_IsNil() {
        for endpoint in allEndpoints {
            XCTAssertNil(endpoint.progressHandler)
        }
    }

    // MARK: - getArchivesByAccountId Parameters

    func testGetArchivesByAccountId_ContainsAccountId() {
        let endpoint = ArchivesEndpoint.getArchivesByAccountId(accountId: 999)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        XCTAssertNotNil(requestVO)

        let data = requestVO?["data"] as? [[String: Any]]
        XCTAssertEqual(data?.count, 1)

        let accountVO = data?.first?["AccountVO"] as? [String: Any]
        XCTAssertEqual(accountVO?["accountId"] as? Int, 999)
    }

    // MARK: - change Parameters

    func testChange_ContainsArchiveIdAndNbr() {
        let endpoint = ArchivesEndpoint.change(archiveId: 55, archiveNbr: "0002-0003")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertEqual(archiveVO?["archiveId"] as? Int, 55)
        XCTAssertEqual(archiveVO?["archiveNbr"] as? String, "0002-0003")
    }

    // MARK: - create Parameters

    func testCreate_ContainsNameAndType() {
        let endpoint = ArchivesEndpoint.create(name: "My Archive", type: "type.archive.family")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertEqual(archiveVO?["fullName"] as? String, "My Archive")
        XCTAssertEqual(archiveVO?["type"] as? String, "type.archive.family")
    }

    func testCreate_ContainsNSNullRelationType() {
        let endpoint = ArchivesEndpoint.create(name: "Test", type: "type.archive.person")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertTrue(archiveVO?["relationType"] is NSNull, "relationType should be NSNull")
    }

    // MARK: - delete Parameters

    func testDelete_ContainsArchiveIdAndNbr() {
        let endpoint = ArchivesEndpoint.delete(archiveId: 77, archiveNbr: "0005-0006")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertEqual(archiveVO?["archiveId"] as? Int, 77)
        XCTAssertEqual(archiveVO?["archiveNbr"] as? String, "0005-0006")
    }

    // MARK: - accept Parameters

    func testAccept_EncodesArchiveVOData() {
        let archive = mockArchiveVOData(archiveID: 100, archiveNbr: "0010-0020")
        let endpoint = ArchivesEndpoint.accept(archiveVO: archive)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertNotNil(archiveVO, "ArchiveVO should be a dictionary after JSON encoding")
        XCTAssertEqual(archiveVO?["archiveId"] as? Int, 100)
        XCTAssertEqual(archiveVO?["archiveNbr"] as? String, "0010-0020")
    }

    func testAccept_EncodesFullName() {
        let archive = mockArchiveVOData()
        let endpoint = ArchivesEndpoint.accept(archiveVO: archive)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertEqual(archiveVO?["fullName"] as? String, "Test Archive")
    }

    // MARK: - decline Parameters

    func testDecline_EncodesArchiveVOData() {
        let archive = mockArchiveVOData(archiveID: 200, archiveNbr: "0020-0030")
        let endpoint = ArchivesEndpoint.decline(archiveVO: archive)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertNotNil(archiveVO, "ArchiveVO should be a dictionary after JSON encoding")
        XCTAssertEqual(archiveVO?["archiveId"] as? Int, 200)
        XCTAssertEqual(archiveVO?["archiveNbr"] as? String, "0020-0030")
    }

    func testDecline_EncodesAccessRole() {
        let archive = mockArchiveVOData()
        let endpoint = ArchivesEndpoint.decline(archiveVO: archive)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertEqual(archiveVO?["accessRole"] as? String, "access.role.owner")
    }

    // MARK: - update Parameters

    func testUpdate_ContainsArchiveIdAndNbr() {
        let archive = mockArchiveVOData(archiveID: 42, archiveNbr: "0001-0000", type: "type.archive.person")
        let file = mockFileModel()
        let endpoint = ArchivesEndpoint.update(archiveVO: archive, file: file)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertEqual(archiveVO?["archiveId"] as? Int, 42)
        XCTAssertEqual(archiveVO?["archiveNbr"] as? String, "0001-0000")
    }

    func testUpdate_ContainsThumbArchiveNbr() {
        let archive = mockArchiveVOData()
        let file = mockFileModel()
        let endpoint = ArchivesEndpoint.update(archiveVO: archive, file: file)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertEqual(archiveVO?["thumbArchiveNbr"] as? String, "0001-0000")
    }

    func testUpdate_ContainsArchiveType() {
        let archive = mockArchiveVOData(type: "type.archive.family")
        let file = mockFileModel()
        let endpoint = ArchivesEndpoint.update(archiveVO: archive, file: file)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertEqual(archiveVO?["type"] as? String, "type.archive.family")
    }

    // MARK: - transferOwnership Parameters

    func testTransferOwnership_ContainsArchiveNbr() {
        let endpoint = ArchivesEndpoint.transferOwnership(archiveNbr: "0003-0004", primaryEmail: "user@test.com")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]

        XCTAssertEqual(archiveVO?["archiveNbr"] as? String, "0003-0004")
    }

    func testTransferOwnership_ContainsAccountVO() {
        let endpoint = ArchivesEndpoint.transferOwnership(archiveNbr: "0003-0004", primaryEmail: "user@test.com")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        XCTAssertNotNil(accountVO)
        XCTAssertEqual(accountVO?["primaryEmail"] as? String, "user@test.com")
    }

    func testTransferOwnership_ContainsOwnerAccessRole() {
        let endpoint = ArchivesEndpoint.transferOwnership(archiveNbr: "0003-0004", primaryEmail: "user@test.com")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let accountVO = data?.first?["AccountVO"] as? [String: Any]

        let expectedRole = AccessRole.apiRoleForValue(.owner)
        XCTAssertEqual(accountVO?["accessRole"] as? String, expectedRole)
    }

    func testTransferOwnership_DataContainsBothArchiveVOAndAccountVO() {
        let endpoint = ArchivesEndpoint.transferOwnership(archiveNbr: "0003-0004", primaryEmail: "user@test.com")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let firstEntry = data?.first

        XCTAssertNotNil(firstEntry?["ArchiveVO"])
        XCTAssertNotNil(firstEntry?["AccountVO"])
    }

    // MARK: - getArchivesByArchivesNbr Parameters

    func testGetArchivesByArchivesNbr_SingleArchive() {
        let endpoint = ArchivesEndpoint.getArchivesByArchivesNbr(archivesNbr: ["0001-0000"])
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]

        XCTAssertEqual(data?.count, 1)

        let archiveVO = data?.first?["ArchiveVO"] as? [String: Any]
        XCTAssertEqual(archiveVO?["archiveNbr"] as? String, "0001-0000")
    }

    func testGetArchivesByArchivesNbr_MultipleArchives() {
        let nbrs = ["0001-0000", "0002-0000", "0003-0000"]
        let endpoint = ArchivesEndpoint.getArchivesByArchivesNbr(archivesNbr: nbrs)
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]

        XCTAssertEqual(data?.count, 3)

        for (index, nbr) in nbrs.enumerated() {
            let archiveVO = data?[index]["ArchiveVO"] as? [String: Any]
            XCTAssertEqual(archiveVO?["archiveNbr"] as? String, nbr)
        }
    }

    func testGetArchivesByArchivesNbr_EmptyArray() {
        let endpoint = ArchivesEndpoint.getArchivesByArchivesNbr(archivesNbr: [])
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]

        XCTAssertEqual(data?.count, 0)
    }

    // MARK: - searchArchive Parameters

    func testSearchArchive_ContainsSearchVO() {
        let endpoint = ArchivesEndpoint.searchArchive(searchAfter: "family photos")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let searchVO = data?.first?["SearchVO"] as? [String: Any]

        XCTAssertNotNil(searchVO)
        XCTAssertEqual(searchVO?["query"] as? String, "family photos")
    }

    func testSearchArchive_EmptyQuery() {
        let endpoint = ArchivesEndpoint.searchArchive(searchAfter: "")
        let params = dict(endpoint.parameters)

        let requestVO = params?["RequestVO"] as? [String: Any]
        let data = requestVO?["data"] as? [[String: Any]]
        let searchVO = data?.first?["SearchVO"] as? [String: Any]

        XCTAssertEqual(searchVO?["query"] as? String, "")
    }

    // MARK: - Parameters Structure Consistency

    func testAllEndpoints_HaveRequestVOTopLevelKey() {
        for endpoint in allEndpoints {
            let params = dict(endpoint.parameters)
            XCTAssertNotNil(params?["RequestVO"], "Endpoint \(endpoint) should have a RequestVO key")
        }
    }

    func testAllEndpoints_HaveDataArray() {
        for endpoint in allEndpoints {
            let params = dict(endpoint.parameters)
            let requestVO = params?["RequestVO"] as? [String: Any]
            let data = requestVO?["data"] as? [Any]
            XCTAssertNotNil(data, "Endpoint \(endpoint) should have a data array inside RequestVO")
        }
    }
}
