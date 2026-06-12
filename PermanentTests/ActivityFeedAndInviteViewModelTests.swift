//
//  ActivityFeedAndInviteViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ActivityFeedAndInviteViewModelTests: XCTestCase {

    // MARK: - ActivityFeedViewModel

    func testActivityFeed_InitialState() {
        let vm = ActivityFeedViewModel()

        XCTAssertFalse(vm.isBusy)
        XCTAssertEqual(vm.numberOfItems, 0)
        XCTAssertNil(vm.viewDelegate)
    }

    func testActivityFeed_NumberOfItems_Initially() {
        let vm = ActivityFeedViewModel()
        XCTAssertEqual(vm.numberOfItems, 0)
    }

    // MARK: - InviteViewModel

    func testInvite_InitialState() {
        let vm = InviteViewModel()

        XCTAssertFalse(vm.isBusy)
        XCTAssertFalse(vm.hasData)
        XCTAssertEqual(vm.numberOfItems, 0)
        XCTAssertNil(vm.viewDelegate)
    }

    func testInvite_HasData_EmptyInvites() {
        let vm = InviteViewModel()
        XCTAssertFalse(vm.hasData)
    }

    func testInvite_SendInvite_NilInfo_DoesNotCrash() {
        let vm = InviteViewModel()
        vm.sendInvite(info: nil)
        XCTAssertFalse(vm.isBusy)
    }

    func testInvite_SendInvite_EmptyInfo_DoesNotCrash() {
        let vm = InviteViewModel()
        vm.sendInvite(info: [])
        XCTAssertFalse(vm.isBusy)
    }

    func testInvite_SendInvite_EmptyNameAndEmail_DoesNotCrash() {
        let vm = InviteViewModel()
        vm.sendInvite(info: ["", ""])
        XCTAssertFalse(vm.isBusy)
    }

    // MARK: - InviteStatus

    func testInviteStatus_RawValues() {
        XCTAssertEqual(InviteStatus.accepted.rawValue, "accepted")
        XCTAssertEqual(InviteStatus.revoked.rawValue, "revoked")
        XCTAssertEqual(InviteStatus.pending.rawValue, "pending")
        XCTAssertEqual(InviteStatus.rejected.rawValue, "rejected")
        XCTAssertEqual(InviteStatus.unknown.rawValue, "unknown")
    }

    // MARK: - Workspace

    func testWorkspace_AllCasesAreUnique() {
        let allCases: [Workspace] = [.privateFiles, .sharedByMeFiles, .shareWithMeFiles, .publicFiles]
        let uniqueSet = Set(allCases.map { "\($0)" })
        XCTAssertEqual(uniqueSet.count, allCases.count, "All Workspace cases should be unique")
    }

    // MARK: - PasswordChangeStatus

    func testPasswordChangeStatus_Success() {
        let status = PasswordChangeStatus.success(message: "Password changed")
        if case .success(let message) = status {
            XCTAssertEqual(message, "Password changed")
        } else {
            XCTFail("Expected success")
        }
    }

    func testPasswordChangeStatus_Error() {
        let status = PasswordChangeStatus.error(message: "Failed")
        if case .error(let message) = status {
            XCTAssertEqual(message, "Failed")
        } else {
            XCTFail("Expected error")
        }
    }

}
