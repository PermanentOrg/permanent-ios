//
//  FileMenuViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.03.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class FileMenuViewModelTests: XCTestCase {

    func testPendingInvitationBadgeCount_ForShareToPermanent_ReturnsPendingCount() {
        var fileModel = makeFileModel()
        fileModel.minArchiveVOS = [
            MinArchiveVO(name: "A1", thumbnail: nil, shareStatus: ArchiveVOData.Status.pending.rawValue, shareId: 1, archiveID: 101, folderLinkID: 1, accessRole: "viewer"),
            MinArchiveVO(name: "A2", thumbnail: nil, shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 2, archiveID: 102, folderLinkID: 1, accessRole: "viewer"),
            MinArchiveVO(name: "A3", thumbnail: nil, shareStatus: ArchiveVOData.Status.pending.rawValue, shareId: 3, archiveID: 103, folderLinkID: 1, accessRole: "viewer")
        ]

        let sut = FileMenuViewModel(fileViewModel: fileModel, menuItems: [], onDismiss: {})

        XCTAssertEqual(sut.pendingInvitationBadgeCount(for: .shareToPermanent), 2)
        XCTAssertTrue(sut.shouldShowPendingInvitationBadge(for: .shareToPermanent))
    }

    func testPendingInvitationBadgeCount_ForNonShareItem_ReturnsZero() {
        var fileModel = makeFileModel()
        fileModel.minArchiveVOS = [
            MinArchiveVO(name: "A1", thumbnail: nil, shareStatus: ArchiveVOData.Status.pending.rawValue, shareId: 1, archiveID: 101, folderLinkID: 1, accessRole: "viewer")
        ]

        let sut = FileMenuViewModel(fileViewModel: fileModel, menuItems: [], onDismiss: {})

        XCTAssertEqual(sut.pendingInvitationBadgeCount(for: .download), 0)
        XCTAssertFalse(sut.shouldShowPendingInvitationBadge(for: .download))
    }

    private func makeFileModel() -> FileModel {
        FileModel(
            name: "Test.pdf",
            recordId: 100,
            folderLinkId: 1,
            archiveNbr: "0001",
            type: "type.record.document.pdf",
            permissions: [.read, .share, .ownership]
        )
    }
}
