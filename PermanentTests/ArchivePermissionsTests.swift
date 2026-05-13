//
//  ArchivePermissionsTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ArchivePermissionsTests: XCTestCase {

    // MARK: - ArchiveVOData.permissions(forAccessRole:)

    func testPermissions_Owner_HasAllPermissions() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.owner")

        XCTAssertTrue(perms.contains(.read))
        XCTAssertTrue(perms.contains(.create))
        XCTAssertTrue(perms.contains(.upload))
        XCTAssertTrue(perms.contains(.edit))
        XCTAssertTrue(perms.contains(.delete))
        XCTAssertTrue(perms.contains(.move))
        XCTAssertTrue(perms.contains(.publish))
        XCTAssertTrue(perms.contains(.share))
        XCTAssertTrue(perms.contains(.archiveShare))
        XCTAssertTrue(perms.contains(.ownership))
        XCTAssertTrue(perms.contains(.legacyPlanning))
    }

    func testPermissions_Manager_HasSharePermissions() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.manager")

        XCTAssertTrue(perms.contains(.read))
        XCTAssertTrue(perms.contains(.create))
        XCTAssertTrue(perms.contains(.upload))
        XCTAssertTrue(perms.contains(.edit))
        XCTAssertTrue(perms.contains(.delete))
        XCTAssertTrue(perms.contains(.move))
        XCTAssertTrue(perms.contains(.publish))
        XCTAssertTrue(perms.contains(.share))
        XCTAssertTrue(perms.contains(.archiveShare))
        XCTAssertFalse(perms.contains(.ownership))
        XCTAssertFalse(perms.contains(.legacyPlanning))
    }

    func testPermissions_Curator_HasPublishAndShare() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.curator")

        XCTAssertTrue(perms.contains(.read))
        XCTAssertTrue(perms.contains(.create))
        XCTAssertTrue(perms.contains(.upload))
        XCTAssertTrue(perms.contains(.edit))
        XCTAssertTrue(perms.contains(.delete))
        XCTAssertTrue(perms.contains(.move))
        XCTAssertTrue(perms.contains(.publish))
        XCTAssertTrue(perms.contains(.share))
        XCTAssertFalse(perms.contains(.archiveShare))
    }

    func testPermissions_Editor_HasEditPermissions() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.editor")

        XCTAssertTrue(perms.contains(.read))
        XCTAssertTrue(perms.contains(.create))
        XCTAssertTrue(perms.contains(.upload))
        XCTAssertTrue(perms.contains(.edit))
        XCTAssertFalse(perms.contains(.delete))
        XCTAssertFalse(perms.contains(.move))
        XCTAssertFalse(perms.contains(.share))
    }

    func testPermissions_Contributor_HasUploadOnly() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.contributor")

        XCTAssertTrue(perms.contains(.read))
        XCTAssertTrue(perms.contains(.create))
        XCTAssertTrue(perms.contains(.upload))
        XCTAssertFalse(perms.contains(.edit))
        XCTAssertFalse(perms.contains(.delete))
    }

    func testPermissions_Viewer_HasReadOnly() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.viewer")

        XCTAssertTrue(perms.contains(.read))
        XCTAssertFalse(perms.contains(.create))
        XCTAssertFalse(perms.contains(.upload))
        XCTAssertFalse(perms.contains(.edit))
        XCTAssertFalse(perms.contains(.delete))
    }

    func testPermissions_UnknownRole_DefaultsToViewer() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.unknown")

        XCTAssertTrue(perms.contains(.read))
        XCTAssertFalse(perms.contains(.create))
    }

    // MARK: - ArchiveVOData.permissions() Instance Method

    func testPermissions_InstanceMethod_UsesAccessRole() {
        let archive = ArchiveVOData.mock()
        let perms = archive.permissions()

        XCTAssertTrue(perms.contains(.read))
    }

    // MARK: - ArchiveVOData.mock()

    func testMock_ReturnsValidData() {
        let mock = ArchiveVOData.mock()

        XCTAssertEqual(mock.archiveID, 1)
        XCTAssertEqual(mock.fullName, "Mock User")
        XCTAssertEqual(mock.archiveNbr, "1001")
        XCTAssertNotNil(mock.vaultKey)
        XCTAssertNotNil(mock.createdDT)
        XCTAssertNotNil(mock.updatedDT)
    }

    func testMock_HasThumbnailURLs() {
        let mock = ArchiveVOData.mock()

        XCTAssertNotNil(mock.thumbURL200)
        XCTAssertNotNil(mock.thumbURL500)
        XCTAssertNotNil(mock.thumbURL1000)
        XCTAssertNotNil(mock.thumbURL2000)
    }

    func testMock_StatusIsOk() {
        let mock = ArchiveVOData.mock()
        XCTAssertEqual(mock.status, .ok)
        XCTAssertEqual(mock.thumbStatus, .ok)
    }

    // MARK: - Permission Hierarchy

    func testPermissions_OwnerHasMoreThanManager() {
        let ownerPerms = ArchiveVOData.permissions(forAccessRole: "access.role.owner")
        let managerPerms = ArchiveVOData.permissions(forAccessRole: "access.role.manager")
        XCTAssertGreaterThan(ownerPerms.count, managerPerms.count)
    }

    func testPermissions_ManagerHasMoreThanCurator() {
        let managerPerms = ArchiveVOData.permissions(forAccessRole: "access.role.manager")
        let curatorPerms = ArchiveVOData.permissions(forAccessRole: "access.role.curator")
        XCTAssertGreaterThan(managerPerms.count, curatorPerms.count)
    }

    func testPermissions_CuratorHasMoreThanEditor() {
        let curatorPerms = ArchiveVOData.permissions(forAccessRole: "access.role.curator")
        let editorPerms = ArchiveVOData.permissions(forAccessRole: "access.role.editor")
        XCTAssertGreaterThan(curatorPerms.count, editorPerms.count)
    }

    func testPermissions_EditorHasMoreThanContributor() {
        let editorPerms = ArchiveVOData.permissions(forAccessRole: "access.role.editor")
        let contributorPerms = ArchiveVOData.permissions(forAccessRole: "access.role.contributor")
        XCTAssertGreaterThan(editorPerms.count, contributorPerms.count)
    }

    func testPermissions_ContributorHasMoreThanViewer() {
        let contributorPerms = ArchiveVOData.permissions(forAccessRole: "access.role.contributor")
        let viewerPerms = ArchiveVOData.permissions(forAccessRole: "access.role.viewer")
        XCTAssertGreaterThan(contributorPerms.count, viewerPerms.count)
    }
}
