//
//  MembersViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

final class MembersViewModelTests: XCTestCase {

    // MARK: - permissions(forAccessRole:)

    func testPermissions_Owner_HasAll() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.owner")
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
    }

    func testPermissions_Manager_NoOwnership() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.manager")
        XCTAssertTrue(perms.contains(.archiveShare))
        XCTAssertFalse(perms.contains(.ownership))
    }

    func testPermissions_Curator_HasShareNoArchiveShare() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.curator")
        XCTAssertTrue(perms.contains(.share))
        XCTAssertFalse(perms.contains(.archiveShare))
    }

    func testPermissions_Editor_HasEditNoDelete() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.editor")
        XCTAssertTrue(perms.contains(.edit))
        XCTAssertFalse(perms.contains(.delete))
        XCTAssertFalse(perms.contains(.move))
    }

    func testPermissions_Contributor_HasUploadNoEdit() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.contributor")
        XCTAssertTrue(perms.contains(.upload))
        XCTAssertFalse(perms.contains(.edit))
    }

    func testPermissions_Viewer_ReadOnly() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.viewer")
        XCTAssertEqual(perms, [.read])
    }

    func testPermissions_Unknown_DefaultsToViewer() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "some.unknown.role")
        XCTAssertEqual(perms, [.read])
    }

    // MARK: - Permission count per role

    func testPermissions_OwnerCount() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.owner")
        XCTAssertEqual(perms.count, 10)
    }

    func testPermissions_ManagerCount() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.manager")
        XCTAssertEqual(perms.count, 9)
    }

    func testPermissions_CuratorCount() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.curator")
        XCTAssertEqual(perms.count, 8)
    }

    func testPermissions_EditorCount() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.editor")
        XCTAssertEqual(perms.count, 4)
    }

    func testPermissions_ContributorCount() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.contributor")
        XCTAssertEqual(perms.count, 3)
    }

    func testPermissions_ViewerCount() {
        let vm = MembersViewModel()
        let perms = vm.permissions(forAccessRole: "access.role.viewer")
        XCTAssertEqual(perms.count, 1)
    }

    // MARK: - numberOfItemsForRole

    func testNumberOfItems_EmptyMembers_ReturnsZero() {
        let vm = MembersViewModel()
        XCTAssertEqual(vm.numberOfItemsForRole(.owner), 0)
        XCTAssertEqual(vm.numberOfItemsForRole(.viewer), 0)
        XCTAssertEqual(vm.numberOfItemsForRole(.manager), 0)
    }

    // MARK: - itemAtRow

    func testItemAtRow_EmptyMembers_ReturnsNil() {
        let vm = MembersViewModel()
        XCTAssertNil(vm.itemAtRow(0, withRole: .owner))
        XCTAssertNil(vm.itemAtRow(0, withRole: .viewer))
    }

    // MARK: - archivePermissions

    func testArchivePermissions_ReturnsNonEmpty() {
        let vm = MembersViewModel()
        XCTAssertFalse(vm.archivePermissions.isEmpty)
        XCTAssertTrue(vm.archivePermissions.contains(.read))
    }

    // MARK: - currentArchive

    func testCurrentArchive_MatchesSessionArchiveId() {
        let vm = MembersViewModel()
        let archive = vm.currentArchive
        let sessionArchive = AuthenticationManager.shared.session?.selectedArchive
        XCTAssertEqual(archive?.archiveID, sessionArchive?.archiveID)
    }
}
