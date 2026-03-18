//
//  FileMenuViewControllerTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.03.2026.
//

import UIKit
import XCTest
@testable import Permanent

@MainActor
final class FileMenuViewControllerTests: XCTestCase {

    func testSetupMenuView_WhenOwnerShareAndNoArchives_AddsShareManagementItem() {
        let sut = makeSUT(file: makeFile(permissions: [.share, .ownership]))
        sut.menuItems = [
            FileMenuViewController.MenuItem(type: .shareToPermanent, action: nil)
        ]

        sut.setupMenuView()

        let identifiers = sut.stackView.arrangedSubviews.compactMap { $0.accessibilityIdentifier }
        XCTAssertTrue(identifiers.contains("Share management".localized()))
    }

    func testReloadArchivesStackView_WhenCollapsed_ShowsOnlyTwoArchives() {
        var file = makeFile(permissions: [.share])
        file.minArchiveVOS = [
            MinArchiveVO(name: "Archive A", thumbnail: nil, shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 1, archiveID: 101, folderLinkID: 1, accessRole: AccessRole.viewer.apiValue),
            MinArchiveVO(name: "Archive B", thumbnail: nil, shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 2, archiveID: 102, folderLinkID: 1, accessRole: AccessRole.viewer.apiValue),
            MinArchiveVO(name: "Archive C", thumbnail: nil, shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 3, archiveID: 103, folderLinkID: 1, accessRole: AccessRole.viewer.apiValue)
        ]

        let sut = makeSUT(file: file)
        sut.menuItems = [FileMenuViewController.MenuItem(type: .shareToPermanent, action: nil)]
        sut.showAllArchives = false

        sut.reloadArchivesStackView()

        XCTAssertEqual(sut.archivesStackView?.arrangedSubviews.count, 3)
    }

    func testReloadArchivesStackView_WhenExpanded_ShowsAllArchives() {
        var file = makeFile(permissions: [.share])
        file.minArchiveVOS = [
            MinArchiveVO(name: "Archive A", thumbnail: nil, shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 1, archiveID: 101, folderLinkID: 1, accessRole: AccessRole.viewer.apiValue),
            MinArchiveVO(name: "Archive B", thumbnail: nil, shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 2, archiveID: 102, folderLinkID: 1, accessRole: AccessRole.viewer.apiValue),
            MinArchiveVO(name: "Archive C", thumbnail: nil, shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 3, archiveID: 103, folderLinkID: 1, accessRole: AccessRole.viewer.apiValue)
        ]

        let sut = makeSUT(file: file)
        sut.menuItems = [FileMenuViewController.MenuItem(type: .shareToPermanent, action: nil)]
        sut.showAllArchives = true

        sut.reloadArchivesStackView()

        XCTAssertEqual(sut.archivesStackView?.arrangedSubviews.count, 4)
    }

    func testReloadArchivesStackView_WhenPendingShare_UsesPendingRoleLabel() {
        var file = makeFile(permissions: [.share])
        file.minArchiveVOS = [
            MinArchiveVO(name: "Archive A", thumbnail: nil, shareStatus: ArchiveVOData.Status.pending.rawValue, shareId: 1, archiveID: 101, folderLinkID: 1, accessRole: AccessRole.viewer.apiValue)
        ]

        let sut = makeSUT(file: file)
        sut.menuItems = [FileMenuViewController.MenuItem(type: .shareToPermanent, action: nil)]

        sut.reloadArchivesStackView()

        let labels = allLabels(in: sut.archivesStackView).compactMap(\.text)
        XCTAssertTrue(labels.contains("Pending...".localized().uppercased()))
    }

    private func makeSUT(file: FileModel) -> FileMenuViewController {
        let sut = FileMenuViewController()
        sut.fileViewModel = file
        sut.view = UIView(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        return sut
    }

    private func makeFile(permissions: [Permission]) -> FileModel {
        FileModel(
            name: "File.pdf",
            recordId: 1,
            folderLinkId: 10,
            archiveNbr: "0000",
            type: FileType.miscellaneous.rawValue,
            permissions: permissions
        )
    }

    private func allLabels(in root: UIView?) -> [UILabel] {
        guard let root else { return [] }

        var labels: [UILabel] = []
        var queue: [UIView] = [root]

        while !queue.isEmpty {
            let current = queue.removeFirst()
            if let label = current as? UILabel {
                labels.append(label)
            }
            queue.append(contentsOf: current.subviews)
        }

        return labels
    }
}
