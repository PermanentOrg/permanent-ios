//
//  AccessRoleAndPermissionTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class AccessRoleAndPermissionTests: XCTestCase {

    // MARK: - AccessRole rawValue

    func testAccessRole_RawValues() {
        XCTAssertEqual(AccessRole.owner.rawValue, 0)
        XCTAssertEqual(AccessRole.manager.rawValue, 1)
        XCTAssertEqual(AccessRole.curator.rawValue, 2)
        XCTAssertEqual(AccessRole.editor.rawValue, 3)
        XCTAssertEqual(AccessRole.contributor.rawValue, 4)
        XCTAssertEqual(AccessRole.viewer.rawValue, 5)
    }

    // MARK: - AccessRole apiValue

    func testAccessRole_ApiValues() {
        XCTAssertEqual(AccessRole.owner.apiValue, "access.role.owner")
        XCTAssertEqual(AccessRole.manager.apiValue, "access.role.manager")
        XCTAssertEqual(AccessRole.curator.apiValue, "access.role.curator")
        XCTAssertEqual(AccessRole.editor.apiValue, "access.role.editor")
        XCTAssertEqual(AccessRole.contributor.apiValue, "access.role.contributor")
        XCTAssertEqual(AccessRole.viewer.apiValue, "access.role.viewer")
    }

    // MARK: - AccessRole roleForValue

    func testAccessRole_RoleForValue_Owner() {
        XCTAssertEqual(AccessRole.roleForValue("access.role.owner"), .owner)
    }

    func testAccessRole_RoleForValue_Manager() {
        XCTAssertEqual(AccessRole.roleForValue("access.role.manager"), .manager)
    }

    func testAccessRole_RoleForValue_Curator() {
        XCTAssertEqual(AccessRole.roleForValue("access.role.curator"), .curator)
    }

    func testAccessRole_RoleForValue_Editor() {
        XCTAssertEqual(AccessRole.roleForValue("access.role.editor"), .editor)
    }

    func testAccessRole_RoleForValue_Contributor() {
        XCTAssertEqual(AccessRole.roleForValue("access.role.contributor"), .contributor)
    }

    func testAccessRole_RoleForValue_Viewer() {
        XCTAssertEqual(AccessRole.roleForValue("access.role.viewer"), .viewer)
    }

    func testAccessRole_RoleForValue_UnknownDefaultsToViewer() {
        XCTAssertEqual(AccessRole.roleForValue("unknown"), .viewer)
    }

    // MARK: - AccessRole roleForValue, Stela plain-word form

    func testAccessRole_RoleForValue_StelaPlainWords() {
        XCTAssertEqual(AccessRole.roleForValue("owner"), .owner)
        XCTAssertEqual(AccessRole.roleForValue("manager"), .manager)
        XCTAssertEqual(AccessRole.roleForValue("curator"), .curator)
        XCTAssertEqual(AccessRole.roleForValue("editor"), .editor)
        XCTAssertEqual(AccessRole.roleForValue("contributor"), .contributor)
        XCTAssertEqual(AccessRole.roleForValue("viewer"), .viewer)
    }

    func testPermissions_ForStelaPlainWordOwner_GrantFullAccess() {
        let permissions = ArchiveVOData.permissions(forAccessRole: "owner")
        XCTAssertTrue(permissions.contains(.upload))
        XCTAssertTrue(permissions.contains(.create))
        XCTAssertTrue(permissions.contains(.delete))
        XCTAssertTrue(permissions.contains(.ownership))
    }

    func testPermissions_ForStelaPlainWordViewer_StayReadOnly() {
        XCTAssertEqual(ArchiveVOData.permissions(forAccessRole: "viewer"), [.read])
    }

    func testAccessRole_RoleForValue_NilDefaultsToViewer() {
        XCTAssertEqual(AccessRole.roleForValue(nil), .viewer)
    }

    // MARK: - AccessRole apiRoleForValue

    func testAccessRole_ApiRoleForValue_AllRoles() {
        XCTAssertEqual(AccessRole.apiRoleForValue(.owner), "access.role.owner")
        XCTAssertEqual(AccessRole.apiRoleForValue(.manager), "access.role.manager")
        XCTAssertEqual(AccessRole.apiRoleForValue(.curator), "access.role.curator")
        XCTAssertEqual(AccessRole.apiRoleForValue(.editor), "access.role.editor")
        XCTAssertEqual(AccessRole.apiRoleForValue(.contributor), "access.role.contributor")
        XCTAssertEqual(AccessRole.apiRoleForValue(.viewer), "access.role.viewer")
    }

    func testAccessRole_ApiRoleForValue_UnknownReturnsNil() {
        XCTAssertNil(AccessRole.apiRoleForValue("unknown_role"))
    }

    // MARK: - AccessRole title

    func testAccessRole_Titles() {
        XCTAssertEqual(AccessRole.owner.title, "Owner")
        XCTAssertEqual(AccessRole.manager.title, "Manager")
        XCTAssertEqual(AccessRole.curator.title, "Curator")
        XCTAssertEqual(AccessRole.editor.title, "Editor")
        XCTAssertEqual(AccessRole.contributor.title, "Contributor")
        XCTAssertEqual(AccessRole.viewer.title, "Viewer")
    }

    // MARK: - AccessRole description

    func testAccessRole_DescriptionsExist() {
        for role in AccessRole.allCases {
            XCTAssertFalse(role.description.isEmpty, "\(role) should have a description")
        }
    }

    // MARK: - AccessRole CaseIterable

    func testAccessRole_AllCases() {
        XCTAssertEqual(AccessRole.allCases.count, 6)
    }

    // MARK: - AccessRole Codable

    func testAccessRole_Codable() throws {
        let role = AccessRole.editor
        let data = try JSONEncoder().encode(role)
        let decoded = try JSONDecoder().decode(AccessRole.self, from: data)
        XCTAssertEqual(decoded, role)
    }

    // MARK: - Permission prettyPermission

    func testPermission_PrettyPermission_NonNilForVisiblePermissions() {
        let visiblePermissions: [Permission] = [.read, .create, .upload, .edit, .delete, .move, .publish, .share]
        for permission in visiblePermissions {
            let pretty = permission.prettyPermission()
            XCTAssertNotNil(pretty, "\(permission) should have a pretty name")
            XCTAssertFalse(pretty!.isEmpty, "\(permission) pretty name should not be empty")
        }
    }

    func testPermission_PrettyPermission_ArchiveShareReturnsNil() {
        XCTAssertNil(Permission.archiveShare.prettyPermission())
    }

    func testPermission_PrettyPermission_OwnershipReturnsNil() {
        XCTAssertNil(Permission.ownership.prettyPermission())
    }

    func testPermission_PrettyPermission_LegacyPlanningReturnsNil() {
        XCTAssertNil(Permission.legacyPlanning.prettyPermission())
    }

    // MARK: - Permission Codable

    func testPermission_Codable() throws {
        let permission = Permission.edit
        let data = try JSONEncoder().encode(permission)
        let decoded = try JSONDecoder().decode(Permission.self, from: data)
        XCTAssertEqual(decoded, permission)
    }

    // MARK: - ShareViewAccessLevel

    func testShareViewAccessLevel_Titles() {
        XCTAssertEqual(ShareViewAccessLevel.anyoneCanView.title, "Anyone can view")
        XCTAssertEqual(ShareViewAccessLevel.restricted.title, "Restricted")
    }

    func testShareViewAccessLevel_Descriptions() {
        XCTAssertFalse(ShareViewAccessLevel.anyoneCanView.description.isEmpty)
        XCTAssertFalse(ShareViewAccessLevel.restricted.description.isEmpty)
    }

    func testShareViewAccessLevel_AllCases() {
        XCTAssertEqual(ShareViewAccessLevel.allCases.count, 2)
    }

    // MARK: - ShareExpirationOption

    func testShareExpirationOption_Titles() {
        XCTAssertEqual(ShareExpirationOption.oneDay.title, "One day")
        XCTAssertEqual(ShareExpirationOption.oneMonth.title, "One month")
        XCTAssertEqual(ShareExpirationOption.oneYear.title, "One year")
        XCTAssertEqual(ShareExpirationOption.never.title, "Never")
        XCTAssertEqual(ShareExpirationOption.none.title, "")
    }

    func testShareExpirationOption_ExpirationDate_OneDayNotNil() {
        XCTAssertNotNil(ShareExpirationOption.oneDay.expirationDate)
    }

    func testShareExpirationOption_ExpirationDate_OneMonthNotNil() {
        XCTAssertNotNil(ShareExpirationOption.oneMonth.expirationDate)
    }

    func testShareExpirationOption_ExpirationDate_OneYearNotNil() {
        XCTAssertNotNil(ShareExpirationOption.oneYear.expirationDate)
    }

    func testShareExpirationOption_ExpirationDate_NeverIsNil() {
        XCTAssertNil(ShareExpirationOption.never.expirationDate)
    }

    func testShareExpirationOption_ExpirationDate_NoneIsNil() {
        XCTAssertNil(ShareExpirationOption.none.expirationDate)
    }

    func testShareExpirationOption_AllCases() {
        XCTAssertEqual(ShareExpirationOption.allCases.count, 5)
    }

    // MARK: - NavigationDirection

    func testNavigationDirection_ValuesAreDistinct() {
        XCTAssertNotEqual(
            "\(NavigationDirection.forward)",
            "\(NavigationDirection.backward)"
        )
    }

    // MARK: - SecurityBadgeStatus

    func testSecurityBadgeStatus_Equatable() {
        let status1 = SecurityBadgeStatus(text: "ON", color: .green)
        let status2 = SecurityBadgeStatus(text: "ON", color: .green)
        let status3 = SecurityBadgeStatus(text: "OFF", color: .red)

        XCTAssertEqual(status1, status2)
        XCTAssertNotEqual(status1, status3)
    }
}
