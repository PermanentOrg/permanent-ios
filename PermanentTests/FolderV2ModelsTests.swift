//
//  FolderV2ModelsTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 02.09.2026.
//

import XCTest
@testable import Permanent

final class FolderV2ModelsTests: XCTestCase {

    private func decode(_ json: String) throws -> FolderV2Response {
        try FolderV2Response.decoder.decode(FolderV2Response.self, from: Data(json.utf8))
    }

    // MARK: - accessRole

    func testFolder_DecodesCallerAccessRole() throws {
        let response = try decode("""
        {"items": [{"id": "55", "folderId": "55", "displayName": "Shared", "accessRole": "owner"}]}
        """)
        XCTAssertEqual(response.items?.first?.accessRole, "owner")
        XCTAssertEqual(AccessRole.roleForValue(response.items?.first?.accessRole), .owner)
    }

    func testFolder_MissingAccessRole_DecodesToNil() throws {
        let response = try decode("""
        {"items": [{"id": "55", "folderId": "55", "displayName": "Shared"}]}
        """)
        XCTAssertNotNil(response.items?.first)
        XCTAssertNil(response.items?.first?.accessRole)
    }

    // MARK: - shares

    func testFolder_DecodesSharesWithStatusAndArchive() throws {
        let response = try decode("""
        {"items": [{"id": "55", "accessRole": "viewer",
          "shares": [{"id": "9", "accessRole": "editor", "status": "ok", "archive": {"id": "3", "name": "Family"}}]}]}
        """)
        let share = response.items?.first?.shares?.first
        XCTAssertEqual(share?.shareId, "9")
        XCTAssertEqual(share?.accessRole, "editor")
        XCTAssertEqual(share?.status, "ok")
        XCTAssertEqual(share?.archive?.name, "Family")
    }

    func testFolder_EmptyItems_DecodesToEmptyList() throws {
        let response = try decode("""
        {"items": []}
        """)
        XCTAssertEqual(response.items?.count, 0)
    }

    func testFolderV2Data_MemberwiseInit_DefaultsAccessRoleToNil() {
        let folder = FolderV2Data(folderId: "1", displayName: "F")
        XCTAssertNil(folder.accessRole)
        XCTAssertEqual(FolderV2Data(folderId: "1", accessRole: "manager").accessRole, "manager")
    }
}
