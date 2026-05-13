//
//  ShareLinkViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.05.2026.
//

import XCTest
@testable import Permanent

final class ShareLinkViewModelTests: XCTestCase {

    // MARK: - Helpers

    private func makeFileModel(minArchiveVOS: [MinArchiveVO] = []) -> FileModel {
        var file = FileModel.mockFile()
        file.minArchiveVOS = minArchiveVOS
        return file
    }

    private func makeMinArchiveVO(name: String = "Archive", shareStatus: String, shareId: Int = 1, archiveID: Int = 1) -> MinArchiveVO {
        MinArchiveVO(
            name: name,
            thumbnail: nil,
            shareStatus: shareStatus,
            shareId: shareId,
            archiveID: archiveID,
            folderLinkID: 1,
            accessRole: "access.role.viewer"
        )
    }

    private func makeSUT(minArchiveVOS: [MinArchiveVO] = []) -> ShareLinkViewModel {
        let file = makeFileModel(minArchiveVOS: minArchiveVOS)
        return ShareLinkViewModel(fileViewModel: file)
    }

    // MARK: - Initialization

    func testInit_StoresFileViewModel() {
        let sut = makeSUT()
        XCTAssertNotNil(sut.fileViewModel)
    }

    func testInit_ShareVOIsNil() {
        let sut = makeSUT()
        XCTAssertNil(sut.shareVO)
    }

    func testInit_RecordVOIsNil() {
        let sut = makeSUT()
        XCTAssertNil(sut.recordVO)
    }

    func testInit_FolderVOIsNil() {
        let sut = makeSUT()
        XCTAssertNil(sut.folderVO)
    }

    // MARK: - Notification Names

    func testDidRevokeShareLinkNotifName_HasExpectedValue() {
        XCTAssertEqual(
            ShareLinkViewModel.didRevokeShareLinkNotifName.rawValue,
            "ShareLinkViewModel.didRevokeShareLinkNotif"
        )
    }

    func testDidUpdateSharesNotifName_HasExpectedValue() {
        XCTAssertEqual(
            ShareLinkViewModel.didUpdateSharesNotifName.rawValue,
            "ShareLinkViewModel.didUpdateSharesNotifName"
        )
    }

    func testDidCreateShareLinkNotifName_HasExpectedValue() {
        XCTAssertEqual(
            ShareLinkViewModel.didCreateShareLinkNotifName.rawValue,
            "ShareLinkViewModel.didCreateShareLinkNotifName"
        )
    }

    func testDidUpdateShareLinkRoleNotifName_HasExpectedValue() {
        XCTAssertEqual(
            ShareLinkViewModel.didUpdateShareLinkRoleNotifName.rawValue,
            "ShareLinkViewModel.didUpdateShareLinkRoleNotifName"
        )
    }

    func testNotificationNames_AreAllUnique() {
        let names: Set = [
            ShareLinkViewModel.didRevokeShareLinkNotifName,
            ShareLinkViewModel.didUpdateSharesNotifName,
            ShareLinkViewModel.didCreateShareLinkNotifName,
            ShareLinkViewModel.didUpdateShareLinkRoleNotifName
        ]
        XCTAssertEqual(names.count, 4)
    }

    // MARK: - pendingShareVOs

    func testPendingShareVOs_EmptyWhenNoArchives() {
        let sut = makeSUT()
        XCTAssertTrue(sut.pendingShareVOs.isEmpty)
    }

    func testPendingShareVOs_FiltersPendingOnly() {
        let pending = makeMinArchiveVO(name: "Pending", shareStatus: ArchiveVOData.Status.pending.rawValue, shareId: 1, archiveID: 1)
        let accepted = makeMinArchiveVO(name: "Accepted", shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 2, archiveID: 2)
        let sut = makeSUT(minArchiveVOS: [pending, accepted])

        XCTAssertEqual(sut.pendingShareVOs.count, 1)
        XCTAssertEqual(sut.pendingShareVOs.first?.name, "Pending")
    }

    func testPendingShareVOs_ReturnsAllPending() {
        let pending1 = makeMinArchiveVO(name: "P1", shareStatus: ArchiveVOData.Status.pending.rawValue, shareId: 1, archiveID: 1)
        let pending2 = makeMinArchiveVO(name: "P2", shareStatus: ArchiveVOData.Status.pending.rawValue, shareId: 2, archiveID: 2)
        let sut = makeSUT(minArchiveVOS: [pending1, pending2])

        XCTAssertEqual(sut.pendingShareVOs.count, 2)
    }

    func testPendingShareVOs_EmptyWhenAllAccepted() {
        let accepted = makeMinArchiveVO(shareStatus: ArchiveVOData.Status.ok.rawValue)
        let sut = makeSUT(minArchiveVOS: [accepted])

        XCTAssertTrue(sut.pendingShareVOs.isEmpty)
    }

    // MARK: - acceptedShareVOs

    func testAcceptedShareVOs_EmptyWhenNoArchives() {
        let sut = makeSUT()
        XCTAssertTrue(sut.acceptedShareVOs.isEmpty)
    }

    func testAcceptedShareVOs_ExcludesPending() {
        let pending = makeMinArchiveVO(name: "Pending", shareStatus: ArchiveVOData.Status.pending.rawValue, shareId: 1, archiveID: 1)
        let accepted = makeMinArchiveVO(name: "Accepted", shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 2, archiveID: 2)
        let sut = makeSUT(minArchiveVOS: [pending, accepted])

        XCTAssertEqual(sut.acceptedShareVOs.count, 1)
        XCTAssertEqual(sut.acceptedShareVOs.first?.name, "Accepted")
    }

    func testAcceptedShareVOs_EmptyWhenAllPending() {
        let pending = makeMinArchiveVO(shareStatus: ArchiveVOData.Status.pending.rawValue)
        let sut = makeSUT(minArchiveVOS: [pending])

        XCTAssertTrue(sut.acceptedShareVOs.isEmpty)
    }

    func testAcceptedShareVOs_IncludesNonPendingStatuses() {
        let ok = makeMinArchiveVO(name: "OK", shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 1, archiveID: 1)
        let orphaned = makeMinArchiveVO(name: "Orphaned", shareStatus: ArchiveVOData.Status.orphaned.rawValue, shareId: 2, archiveID: 2)
        let sut = makeSUT(minArchiveVOS: [ok, orphaned])

        XCTAssertEqual(sut.acceptedShareVOs.count, 2)
    }

    // MARK: - Pending + Accepted Consistency

    func testPendingAndAccepted_CoverAllArchives() {
        let pending = makeMinArchiveVO(shareStatus: ArchiveVOData.Status.pending.rawValue, shareId: 1, archiveID: 1)
        let ok = makeMinArchiveVO(shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 2, archiveID: 2)
        let orphaned = makeMinArchiveVO(shareStatus: ArchiveVOData.Status.orphaned.rawValue, shareId: 3, archiveID: 3)
        let sut = makeSUT(minArchiveVOS: [pending, ok, orphaned])

        let total = sut.pendingShareVOs.count + sut.acceptedShareVOs.count
        XCTAssertEqual(total, 3, "Pending + accepted should cover all archives")
    }

    // MARK: - shareVOS

    func testShareVOS_NilWhenBothRecordAndFolderNil() {
        let sut = makeSUT()
        XCTAssertNil(sut.shareVOS)
    }
}
