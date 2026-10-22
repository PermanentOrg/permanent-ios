//
//  ItemMenuLayoutTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 20.10.2026.
//

import Foundation
import Testing
import UIKit
@testable import Permanent

private let roles = ["owner", "manager", "curator", "editor", "contributor", "viewer"]

/// The Stage 1 item menu: the rows of the … sheet, who sees Save or send a copy and the date row,
/// and what a tap on the date row does.
@MainActor
struct ItemMenuLayoutTests {
    private typealias ItemType = FileMenuItems.ItemType

    private let places: [FileMenuItems.Place] = [
        .privateFiles, .publicFiles, .sharedByMe(isRoot: true), .sharedByMe(isRoot: false),
        .sharedWithMe(isRoot: true), .sharedWithMe(isRoot: false)
    ]

    private func item(role: String, isFolder: Bool = false) -> FileModel {
        FileModel(
            name: isFolder ? "August" : "August_Hike_003.jpg",
            recordId: isFolder ? 0 : 42,
            folderLinkId: 7,
            archiveNbr: "0001",
            type: isFolder ? "type.folder.private" : "type.record.image",
            permissions: ArchiveVOData.permissions(forAccessRole: "access.role.\(role)")
        )
    }

    private func titles(_ role: String, in place: FileMenuItems.Place) -> [String] {
        FileMenuItems.types(for: item(role: role), in: place).map(\.title)
    }

    @Test("An owner's photo in Private Files shows the nine rows of the Figma menu, in its order")
    func ownerPhotoFollowsTheFigmaMenu() {
        #expect(titles("owner", in: .privateFiles) == [
            "Share and manage access", "Publish on the web", "Save or send a copy", "Rename", "Adjust date and time",
            "View information", "Move to another folder", "Copy to another folder", "Delete"
        ])
    }

    @Test("No role in any place gets a Save row", arguments: roles)
    func noRoleGetsSave(role: String) {
        for place in places {
            for isFolder in [false, true] {
                let types = FileMenuItems.types(for: item(role: role, isFolder: isFolder), in: place)
                #expect(!types.contains(.download), "\(role), \(place), folder: \(isFolder)")
            }
        }
    }

    @Test("Save or send a copy shows only for a file whose role has the share right", arguments: roles)
    func sendACopyNeedsTheShareRight(role: String) {
        for place in places {
            for isFolder in [false, true] {
                let file = item(role: role, isFolder: isFolder)
                let shows = FileMenuItems.types(for: file, in: place).contains(.shareToAnotherApp)
                #expect(shows == (file.permissions.contains(.share) && !isFolder), "\(role), \(place), folder: \(isFolder)")
            }
        }
    }

    @Test("A viewer keeps only View information in Private Files, and only Leave share at the top of Shared with me")
    func viewerKeepsOneRow() {
        #expect(FileMenuItems.types(for: item(role: "viewer"), in: .privateFiles) == [.fileInformation])
        #expect(FileMenuItems.types(for: item(role: "viewer"), in: .sharedWithMe(isRoot: true)) == [.unshare])
    }

    @Test("Adjust date and time shows for every file a role can edit, in every place, and never for a folder", arguments: roles)
    func dateRowNeedsTheEditRight(role: String) {
        for place in places {
            let file = item(role: role)
            #expect(FileMenuItems.types(for: file, in: place).contains(.adjustDateTime) == file.permissions.contains(.edit), "\(role), \(place)")
            #expect(!FileMenuItems.types(for: item(role: role, isFolder: true), in: place).contains(.adjustDateTime), "\(role), \(place)")
        }
    }

    @Test("The date row comes right after Rename, and View information right after the date row")
    func dateRowSitsBetweenRenameAndInformation() throws {
        let types = FileMenuItems.types(for: item(role: "editor"), in: .privateFiles)
        let rename = try #require(types.firstIndex(of: .rename))
        #expect(types[rename + 1] == .adjustDateTime)
        #expect(types[rename + 2] == .fileInformation)
    }

    @Test("The two new rows are called View information and Adjust date and time")
    func newTitles() {
        #expect(ItemType.fileInformation.title == "View information")
        #expect(ItemType.adjustDateTime.title == "Adjust date and time")
    }

    @Test("The long-press menu leaves the date row out, and says View information")
    func longPressHasNoDateRow() {
        let types = FileMenuItems.types(for: item(role: "owner"), in: .privateFiles)
        let titles = FileContextMenu.make(for: types) { _ in }.children
            .compactMap { $0 as? UIMenu }
            .flatMap(\.children)
            .compactMap { ($0 as? UIAction)?.title }
        #expect(titles.contains("View information"))
        #expect(!titles.contains("Adjust date and time"))
        #expect(!FileContextMenu.hasActions(for: [.adjustDateTime]), "a long press with only the date row shows no menu")
    }

    @Test("A tap on the date row closes the sheet first, then opens the date screen")
    func dateRowRunsAfterTheSheetCloses() async {
        var events: [String] = []
        let row = FileMenuViewModel.MenuItem(type: .adjustDateTime, action: { events.append("date screen") })
        let sheet = FileMenuViewModel(fileViewModel: item(role: "owner"), menuItems: [row], onDismiss: { events.append("sheet closed") })

        sheet.handleMenuItemTap(row)
        #expect(events.isEmpty, "nothing opens while the sheet slides away")

        let deadline = Date().addingTimeInterval(2)
        while events.count < 2, Date() < deadline {
            await Task.yield()
        }
        #expect(events == ["sheet closed", "date screen"])
    }
}
