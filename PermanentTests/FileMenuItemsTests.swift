//
//  FileMenuItemsTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 30.09.2026.
//

import XCTest
@testable import Permanent

final class FileMenuItemsTests: XCTestCase {
    private typealias ItemType = FileMenuItems.ItemType

    private func file(role: String, isFolder: Bool = false) -> FileModel {
        FileModel(
            name: isFolder ? "August" : "August_Hike_003.jpg",
            recordId: isFolder ? 0 : 42,
            folderLinkId: 7,
            archiveNbr: "0001",
            type: isFolder ? "type.folder.private" : "type.record.image",
            permissions: ArchiveVOData.permissions(forAccessRole: role)
        )
    }

    private func types(_ role: String, isFolder: Bool = false, in place: FileMenuItems.Place) -> [ItemType] {
        FileMenuItems.types(for: file(role: role, isFolder: isFolder), in: place)
    }

    // MARK: - Private Files

    func testPrivateFiles_OwnerFile_GetsNineActionsInTheSheetOrder() {
        XCTAssertEqual(types("access.role.owner", in: .privateFiles),
                       [.shareToPermanent, .shareToAnotherApp, .publish, .fileInformation, .rename, .move, .copy, .download, .delete])
    }

    func testPrivateFiles_OwnerFolder_HasNoSaveAndNoSendACopy() {
        XCTAssertEqual(types("access.role.owner", isFolder: true, in: .privateFiles),
                       [.shareToPermanent, .publish, .rename, .move, .copy, .delete])
    }

    func testPrivateFiles_ManagerAndCurator_LoseOnlyShareAndManageAccess() {
        let expected: [ItemType] = [.shareToAnotherApp, .publish, .fileInformation, .rename, .move, .copy, .download, .delete]
        XCTAssertEqual(types("access.role.manager", in: .privateFiles), expected)
        XCTAssertEqual(types("access.role.curator", in: .privateFiles), expected)
    }

    func testPrivateFiles_Editor_RenamesCopiesAndSaves() {
        XCTAssertEqual(types("access.role.editor", in: .privateFiles), [.fileInformation, .rename, .copy, .download])
    }

    func testPrivateFiles_Contributor_CopiesAndSaves() {
        XCTAssertEqual(types("access.role.contributor", in: .privateFiles), [.fileInformation, .copy, .download])
    }

    func testPrivateFiles_Viewer_ReadsTheInformationAndSaves() {
        XCTAssertEqual(types("access.role.viewer", in: .privateFiles), [.fileInformation, .download])
    }

    func testPrivateFiles_ViewerFolder_HasNoActions() {
        XCTAssertEqual(types("access.role.viewer", isFolder: true, in: .privateFiles), [])
    }

    // MARK: - Public Files

    func testPublicFiles_Owner_HasEverythingButPublish() {
        XCTAssertEqual(types("access.role.owner", in: .publicFiles),
                       [.shareToPermanent, .shareToAnotherApp, .fileInformation, .rename, .move, .copy, .download, .delete])
    }

    // MARK: - Shared

    func testSharedWithMe_TopLevel_LeavesTheShareAndNeverMovesOrCopies() {
        XCTAssertEqual(types("access.role.curator", in: .sharedWithMe(isRoot: true)), [.shareToAnotherApp, .rename, .download, .unshare])
        XCTAssertEqual(types("access.role.viewer", in: .sharedWithMe(isRoot: true)), [.download, .unshare])
    }

    func testSharedWithMe_InsideAFolder_MovesCopiesAndDeletes() {
        XCTAssertEqual(types("access.role.curator", in: .sharedWithMe(isRoot: false)),
                       [.shareToAnotherApp, .rename, .move, .copy, .download, .delete])
    }

    func testSharedByMe_TopLevel_SharesAndDeletesButNeverMovesOrCopies() {
        XCTAssertEqual(types("access.role.owner", in: .sharedByMe(isRoot: true)),
                       [.shareToPermanent, .shareToAnotherApp, .fileInformation, .rename, .download, .delete])
    }

    func testSharedByMe_InsideAFolder_TakesThePrivateFilesOrderWithoutPublish() {
        XCTAssertEqual(types("access.role.owner", in: .sharedByMe(isRoot: false)),
                       [.shareToPermanent, .shareToAnotherApp, .fileInformation, .rename, .move, .copy, .download, .delete])
    }

    func testShareAndManageAccess_NeedsTheSharePermissionTooInSharedLists() {
        let owned = FileModel(name: "a.jpg", recordId: 1, folderLinkId: 1, archiveNbr: "0001", type: "type.record.image", permissions: [.ownership, .read])
        XCTAssertFalse(FileMenuItems.types(for: owned, in: .sharedByMe(isRoot: false)).contains(.shareToPermanent))
        XCTAssertTrue(FileMenuItems.types(for: owned, in: .privateFiles).contains(.shareToPermanent), "Private Files asks for ownership alone")
    }

    func testFileInformation_IsForFilesAnyoneCanOpen_OutsideSharedWithMe() {
        for place: FileMenuItems.Place in [.privateFiles, .publicFiles, .sharedByMe(isRoot: true), .sharedByMe(isRoot: false)] {
            XCTAssertTrue(types("access.role.viewer", in: place).contains(.fileInformation), "\(place)")
            XCTAssertFalse(types("access.role.owner", isFolder: true, in: place).contains(.fileInformation), "no details screen for a folder, \(place)")
        }
        for isRoot in [true, false] {
            XCTAssertFalse(types("access.role.owner", in: .sharedWithMe(isRoot: isRoot)).contains(.fileInformation), "another archive's record")
        }
    }

    // MARK: - Parity with the rules the two screens had before

    private func oldPrivateOrPublicRules(_ file: FileModel, isPublic: Bool) -> [ItemType] {
        let p = file.permissions, isFolder = file.type.isFolder
        var types: [ItemType] = []
        if p.contains(.ownership) { types.append(.shareToPermanent) }
        if p.contains(.share) && !isFolder { types.append(.shareToAnotherApp) }
        if p.contains(.delete) && !isPublic { types.append(.publish) }
        if p.contains(.edit) { types.append(.rename) }
        if p.contains(.delete) { types.append(.delete) }
        if p.contains(.move) { types.append(.move) }
        if p.contains(.create) { types.append(.copy) }
        if p.contains(.read) && !isFolder { types.append(.download) }
        return types
    }

    private func oldSharedRules(_ file: FileModel, isRoot: Bool, isSharedWithMe: Bool) -> [ItemType] {
        let p = file.permissions, isFolder = file.type.isFolder
        var types: [ItemType] = []
        if p.contains(.share) && p.contains(.ownership) { types.append(.shareToPermanent) }
        if p.contains(.share) && !isFolder { types.append(.shareToAnotherApp) }
        if p.contains(.edit) { types.append(.rename) }
        if p.contains(.read) && !isFolder { types.append(.download) }
        if p.contains(.create) && !isRoot { types.append(.copy) }
        if p.contains(.move) && !isRoot { types.append(.move) }
        if isRoot && isSharedWithMe { types.append(.unshare) } else if p.contains(.delete) { types.append(.delete) }
        return types
    }

    func testEveryRoleAndPlace_OffersTheSameActionsAsBefore() {
        let roles = ["owner", "manager", "curator", "editor", "contributor", "viewer"].map { ArchiveVOData.permissions(forAccessRole: "access.role.\($0)") }
        let odd: [[Permission]] = [[.ownership, .read], [.delete], [.create], [.move], [.share], []]
        for permissions in roles + odd {
            for isFolder in [false, true] {
                let item = FileModel(name: "x", recordId: 1, folderLinkId: 1, archiveNbr: "0001",
                                     type: isFolder ? "type.folder.private" : "type.record.image", permissions: permissions)
                let label = "\(permissions), folder: \(isFolder)"
                for isPublic in [false, true] {
                    let before = oldPrivateOrPublicRules(item, isPublic: isPublic)
                    // File information is new, so it stays out of the comparison.
                    let now = FileMenuItems.types(for: item, in: isPublic ? .publicFiles : .privateFiles).filter { $0 != .fileInformation }
                    // the sheet shows the destructive item last, so that is the order people saw
                    XCTAssertEqual(now, before.filter { !$0.isDestructive } + before.filter(\.isDestructive), label)
                }
                for isRoot in [false, true] {
                    XCTAssertEqual(Set(FileMenuItems.types(for: item, in: .sharedByMe(isRoot: isRoot)).filter { $0 != .fileInformation }),
                                   Set(oldSharedRules(item, isRoot: isRoot, isSharedWithMe: false)), label)
                    XCTAssertEqual(Set(FileMenuItems.types(for: item, in: .sharedWithMe(isRoot: isRoot))),
                                   Set(oldSharedRules(item, isRoot: isRoot, isSharedWithMe: true)), label)
                }
            }
        }
    }

    func testEveryPlace_EndsWithItsOnlyDestructiveItem() {
        let places: [FileMenuItems.Place] = [.privateFiles, .publicFiles, .sharedByMe(isRoot: true), .sharedByMe(isRoot: false), .sharedWithMe(isRoot: true), .sharedWithMe(isRoot: false)]
        for place in places {
            let list = types("access.role.owner", in: place)
            XCTAssertEqual(list.filter(\.isDestructive).count, 1, "\(place)")
            XCTAssertEqual(list.last?.isDestructive, true, "\(place)")
        }
    }
}
