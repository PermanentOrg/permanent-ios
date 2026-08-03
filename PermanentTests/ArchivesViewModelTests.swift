//
//  ArchivesViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 12.05.2026.
//

import XCTest
@testable import Permanent

final class ArchivesViewModelTests: XCTestCase {

    private func makeArchive(archiveNbr: String = "0001", status: ArchiveVOData.Status = .ok, archiveID: Int = 1, fullName: String? = "Test") -> ArchiveVOData {
        return ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: "access.role.viewer", fullName: fullName,
            spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
            relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil,
            itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil,
            archiveID: archiveID, publicDT: nil, archiveNbr: archiveNbr,
            view: nil, viewProperty: nil, archiveVOPublic: nil,
            vaultKey: nil, thumbArchiveNbr: nil, type: nil, thumbStatus: nil,
            imageRatio: nil, thumbnail256: nil, thumbURL200: nil, thumbURL500: nil,
            thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil,
            createdDT: nil, updatedDT: nil, status: status
        )
    }

    // MARK: - Notification Names

    func testCloseArchiveSettings_NotificationName() {
        XCTAssertEqual(ArchivesViewModel.closeArchiveSettings.rawValue, "ArchivesViewModel.closeArchiveSettings")
    }

    func testDidChangeArchive_NotificationName() {
        XCTAssertEqual(ArchivesViewModel.didChangeArchiveNotification.rawValue, "ArchivesViewModel.didChangeArchiveNotification")
    }

    // MARK: - Init

    func testInit_AllArchivesEmpty() {
        let vm = ArchivesViewModel()
        XCTAssertTrue(vm.allArchives.isEmpty)
    }

    func testInit_AccountNil() {
        let vm = ArchivesViewModel()
        XCTAssertNil(vm.account)
    }

    func testInit_DefaultArchiveIdNil() {
        let vm = ArchivesViewModel()
        XCTAssertNil(vm.defaultArchiveId)
    }

    // MARK: - defaultArchiveId

    func testDefaultArchiveId_WithAccount() {
        let vm = ArchivesViewModel()
        vm.account = AccountVOData.mock()
        XCTAssertNotNil(vm.defaultArchiveId)
    }

    // MARK: - usableArchives (the parsing step that feeds allArchives)
    // The pendingArchives tests below all assign `allArchives` directly, so none of them
    // exercised parsing — which is exactly where a `status != .pending` filter was dropping
    // invitations. The web showed a pending viewer archive that iOS could not accept at all.

    func testUsableArchives_KeepsPending_SoInvitationsAreAcceptable() {
        let parsed = ArchivesViewModel.usableArchives(from: [
            ArchiveVO(archiveVO: makeArchive(archiveNbr: "001", status: .ok, archiveID: 1)),
            ArchiveVO(archiveVO: makeArchive(archiveNbr: "002", status: .pending, archiveID: 2))
        ])

        XCTAssertEqual(parsed.count, 2, "a pending invitation must survive parsing")
        XCTAssertEqual(parsed.filter { $0.status == .pending }.first?.archiveNbr, "002")

        // End to end through the property the Pending Archives section actually reads.
        let vm = ArchivesViewModel()
        vm.allArchives = parsed
        XCTAssertEqual(vm.pendingArchives.count, 1,
                       "parsing must feed pendingArchives, or Accept/Decline is unreachable")
        XCTAssertEqual(vm.selectableArchives.count, 1,
                       "the switcher must still exclude pending — it requires .ok")
    }

    func testUsableArchives_DropsUnknownStatus() {
        let parsed = ArchivesViewModel.usableArchives(from: [
            ArchiveVO(archiveVO: makeArchive(archiveNbr: "001", status: .ok, archiveID: 1)),
            ArchiveVO(archiveVO: makeArchive(archiveNbr: "002", status: .unknown, archiveID: 2))
        ])

        XCTAssertEqual(parsed.count, 1, "an unparseable status is still dropped")
        XCTAssertEqual(parsed.first?.archiveNbr, "001")
    }

    func testUsableArchives_DedupesByIdPreferringNamedRow() {
        // Server-side duplicates: the row carrying a name must win regardless of order.
        let namelessFirst = ArchivesViewModel.usableArchives(from: [
            ArchiveVO(archiveVO: makeArchive(archiveNbr: "001", status: .ok, archiveID: 7, fullName: nil)),
            ArchiveVO(archiveVO: makeArchive(archiveNbr: "001", status: .ok, archiveID: 7, fullName: "Real Name"))
        ])
        XCTAssertEqual(namelessFirst.count, 1)
        XCTAssertEqual(namelessFirst.first?.fullName, "Real Name")

        let namedFirst = ArchivesViewModel.usableArchives(from: [
            ArchiveVO(archiveVO: makeArchive(archiveNbr: "001", status: .ok, archiveID: 7, fullName: "Real Name")),
            ArchiveVO(archiveVO: makeArchive(archiveNbr: "001", status: .ok, archiveID: 7, fullName: nil))
        ])
        XCTAssertEqual(namedFirst.count, 1)
        XCTAssertEqual(namedFirst.first?.fullName, "Real Name")
    }

    func testUsableArchives_NilInput_ReturnsEmpty() {
        XCTAssertTrue(ArchivesViewModel.usableArchives(from: nil).isEmpty)
    }

    // MARK: - pendingArchives

    func testPendingArchives_Empty_ReturnsEmpty() {
        let vm = ArchivesViewModel()
        XCTAssertTrue(vm.pendingArchives.isEmpty)
    }

    func testPendingArchives_FiltersPendingOnly() {
        let vm = ArchivesViewModel()
        vm.allArchives = [
            makeArchive(archiveNbr: "001", status: .ok, archiveID: 1),
            makeArchive(archiveNbr: "002", status: .pending, archiveID: 2),
            makeArchive(archiveNbr: "003", status: .ok, archiveID: 3)
        ]
        XCTAssertEqual(vm.pendingArchives.count, 1)
        XCTAssertEqual(vm.pendingArchives.first?.archiveNbr, "002")
    }

    func testPendingArchives_NoPending_ReturnsEmpty() {
        let vm = ArchivesViewModel()
        vm.allArchives = [
            makeArchive(archiveNbr: "001", status: .ok, archiveID: 1),
            makeArchive(archiveNbr: "002", status: .ok, archiveID: 2)
        ]
        XCTAssertTrue(vm.pendingArchives.isEmpty)
    }

    func testPendingArchives_AllPending_ReturnsAll() {
        let vm = ArchivesViewModel()
        vm.allArchives = [
            makeArchive(archiveNbr: "001", status: .pending, archiveID: 1),
            makeArchive(archiveNbr: "002", status: .pending, archiveID: 2)
        ]
        XCTAssertEqual(vm.pendingArchives.count, 2)
    }

    // MARK: - selectableArchives

    func testSelectableArchives_FiltersOkAndNonCurrent() {
        let vm = ArchivesViewModel()
        vm.allArchives = [
            makeArchive(archiveNbr: "001", status: .ok, archiveID: 1),
            makeArchive(archiveNbr: "002", status: .pending, archiveID: 2),
            makeArchive(archiveNbr: "003", status: .ok, archiveID: 3)
        ]
        let selectable = vm.selectableArchives
        XCTAssertTrue(selectable.allSatisfy { $0.status == .ok })
    }

    func testSelectableArchives_ExcludesPending() {
        let vm = ArchivesViewModel()
        vm.allArchives = [
            makeArchive(archiveNbr: "001", status: .pending, archiveID: 1),
            makeArchive(archiveNbr: "002", status: .pending, archiveID: 2)
        ]
        XCTAssertTrue(vm.selectableArchives.isEmpty)
    }

    // MARK: - currentArchive (no session)

    func testCurrentArchive_NoSession_ReturnsNil() {
        let vm = ArchivesViewModel()
        XCTAssertNil(vm.currentArchive())
    }

    // MARK: - getAccountInfo edge case

    func testGetAccountInfo_NoSession_ReturnsError() {
        let vm = ArchivesViewModel()
        let expectation = expectation(description: "completion")

        vm.getAccountInfo { account, error in
            XCTAssertNil(account)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - getAccountArchives edge case

    func testGetAccountArchives_NoSession_ReturnsError() {
        let vm = ArchivesViewModel()
        let expectation = expectation(description: "completion")

        vm.getAccountArchives { archives, error in
            XCTAssertNil(archives)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - updateAccount edge case

    func testUpdateAccount_NilAccount_ReturnsError() {
        let vm = ArchivesViewModel()
        vm.account = nil
        let expectation = expectation(description: "completion")

        vm.updateAccount(withDefaultArchiveId: 1) { account, error in
            XCTAssertNil(account)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - deleteArchive edge cases

    func testDeleteArchive_NilArchiveId_ReturnsError() {
        let vm = ArchivesViewModel()
        let expectation = expectation(description: "completion")

        vm.deleteArchive(archiveId: nil, archiveNbr: "001") { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func testDeleteArchive_NilArchiveNbr_ReturnsError() {
        let vm = ArchivesViewModel()
        let expectation = expectation(description: "completion")

        vm.deleteArchive(archiveId: 1, archiveNbr: nil) { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - changeArchive edge cases

    func testChangeArchive_NilArchiveId_ReturnsError() {
        let vm = ArchivesViewModel()
        let noIdArchive = ArchiveVOData(
            childFolderVOS: nil, folderSizeVOS: nil, recordVOS: nil,
            accessRole: nil, fullName: nil,
            spaceTotal: nil, spaceLeft: nil, fileTotal: nil, fileLeft: nil,
            relationType: nil, homeCity: nil, homeState: nil, homeCountry: nil,
            itemVOS: nil, birthDay: nil, company: nil, archiveVODescription: nil,
            archiveID: nil, publicDT: nil, archiveNbr: "001",
            view: nil, viewProperty: nil, archiveVOPublic: nil,
            vaultKey: nil, thumbArchiveNbr: nil, type: nil, thumbStatus: nil,
            imageRatio: nil, thumbnail256: nil, thumbURL200: nil, thumbURL500: nil,
            thumbURL1000: nil, thumbURL2000: nil, thumbDT: nil,
            createdDT: nil, updatedDT: nil, status: nil
        )
        let expectation = expectation(description: "completion")

        vm.changeArchive(noIdArchive) { success, error in
            XCTAssertFalse(success)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - ArchiveVOData.Status

    func testArchiveStatus_OkRawValue() {
        XCTAssertEqual(ArchiveVOData.Status.ok.rawValue, "status.generic.ok")
    }

    func testArchiveStatus_PendingRawValue() {
        XCTAssertEqual(ArchiveVOData.Status.pending.rawValue, "status.generic.pending")
    }

    func testArchiveStatus_OrphanedRawValue() {
        XCTAssertEqual(ArchiveVOData.Status.orphaned.rawValue, "status.generic.orphaned")
    }

    func testArchiveStatus_GenAvatarRawValue() {
        XCTAssertEqual(ArchiveVOData.Status.genAvatar.rawValue, "status.archive.gen_avatar")
    }

    func testArchiveStatus_CurrentOwnerRawValue() {
        XCTAssertEqual(ArchiveVOData.Status.currentOwner.rawValue, "status.generic.owner")
    }

    func testArchiveStatus_UnknownRawValue() {
        XCTAssertEqual(ArchiveVOData.Status.unknown.rawValue, "N/A")
    }

    func testArchiveStatus_DecodeUnknownValue() throws {
        let json = "\"some.random.status\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ArchiveVOData.Status.self, from: data)
        XCTAssertEqual(decoded, .unknown)
    }

    func testArchiveStatus_DecodeOkValue() throws {
        let json = "\"status.generic.ok\""
        let data = json.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(ArchiveVOData.Status.self, from: data)
        XCTAssertEqual(decoded, .ok)
    }

    // MARK: - ArchiveVOData.permissions

    func testArchivePermissions_Owner_HasAllPermissions() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.owner")
        XCTAssertTrue(perms.contains(.read))
        XCTAssertTrue(perms.contains(.ownership))
        XCTAssertTrue(perms.contains(.legacyPlanning))
    }

    func testArchivePermissions_Viewer_HasReadOnly() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.viewer")
        XCTAssertEqual(perms, [.read])
    }

    func testArchivePermissions_Manager_NoOwnership() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.manager")
        XCTAssertFalse(perms.contains(.ownership))
    }

    func testArchivePermissions_Editor_HasEdit() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.editor")
        XCTAssertTrue(perms.contains(.edit))
        XCTAssertFalse(perms.contains(.delete))
    }

    func testArchivePermissions_Contributor_HasUpload() {
        let perms = ArchiveVOData.permissions(forAccessRole: "access.role.contributor")
        XCTAssertTrue(perms.contains(.upload))
        XCTAssertFalse(perms.contains(.edit))
    }

    // MARK: - ArchiveVOData.mock

    func testArchiveMock_HasExpectedValues() {
        let mock = ArchiveVOData.mock()
        XCTAssertEqual(mock.archiveID, 1)
        XCTAssertEqual(mock.archiveNbr, "1001")
        XCTAssertEqual(mock.fullName, "Mock User")
        XCTAssertEqual(mock.status, .ok)
    }
}
