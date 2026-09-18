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

    /// The nested share carries the long legacy vocabulary while the folder's own role is short.
    /// Both reach `AccessRole.roleForValue`, which accepts either.
    func testFolder_DecodesSharesWithStatusAndArchive() throws {
        let response = try decode("""
        {"items": [{"id": "55", "accessRole": "owner",
          "shares": [{"id": "9", "accessRole": "access.role.editor", "status": "status.generic.ok",
                      "archive": {"id": "3", "name": "Family", "thumbUrl200": "https://x/200"}}]}]}
        """)
        let share = response.items?.first?.shares?.first
        XCTAssertEqual(response.items?.first?.accessRole, "owner")
        XCTAssertEqual(share?.shareId, "9")
        XCTAssertEqual(AccessRole.roleForValue(share?.accessRole), .editor)
        XCTAssertEqual(share?.status, "status.generic.ok")
        XCTAssertEqual(share?.archive?.name, "Family")
        XCTAssertEqual(share?.archive?.thumbUrl200, "https://x/200")
    }

    /// A requested-but-unapproved share arrives in `shares`, not `pendingShares`, and only when the
    /// caller is a manager or owner. `pendingShares` carries email invitations, which have no archive.
    func testFolder_DecodesPendingShareRequestAndInvitation() throws {
        let response = try decode("""
        {"items": [{"id": "55", "accessRole": "manager",
          "shares": [{"id": "9", "accessRole": "access.role.viewer", "status": "status.generic.pending",
                      "archive": {"id": "3", "name": "Asking Archive"}}],
          "pendingShares": [{"id": "77", "email": "a@b.c", "name": "Ada", "accessRole": "access.role.viewer"}]}]}
        """)
        let folder = response.items?.first
        XCTAssertEqual(folder?.shares?.first?.status, "status.generic.pending")
        XCTAssertEqual(folder?.shares?.first?.archive?.name, "Asking Archive")
        XCTAssertEqual(folder?.pendingShares?.first?.email, "a@b.c")
        XCTAssertEqual(AccessRole.roleForValue(folder?.pendingShares?.first?.accessRole), .viewer)
    }

    /// Absent means "no answer" and empty means "no shares"; the list read distinguishes them.
    func testFolder_MissingSharesKeyDecodesToNil() throws {
        let response = try decode("""
        {"items": [{"id": "55", "accessRole": "curator"}]}
        """)
        XCTAssertNil(response.items?.first?.shares)
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
