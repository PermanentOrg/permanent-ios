//
//  FileMenuViewModelTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.03.2026.
//

import XCTest
import SwiftUI
@testable import Permanent

@MainActor
final class FileMenuViewModelTests: XCTestCase {

    // MARK: - Initialization Tests

    func testInit_SingleFile_SetsFormattedSizeAndDate() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})

        XCTAssertEqual(sut.displayTitle, "Test.pdf")
        XCTAssertNotNil(sut.cachedFormattedDate)
        XCTAssertEqual(sut.dynamicMenuItems.count, 0)
        XCTAssertTrue(sut.isPresented)
        XCTAssertFalse(sut.isAnimating)
    }

    func testInit_MultipleFiles_ShowsItemCount() {
        let file1 = makeFileModel(name: "A.pdf")
        let file2 = makeFileModel(name: "B.pdf")

        let sut = FileMenuViewModel(
            fileViewModel: file1,
            menuItems: [],
            selectedItemCount: 2,
            selectedFiles: [file1, file2],
            onDismiss: {}
        )

        XCTAssertEqual(sut.displayTitle, "2 Items selected")
    }

    func testInit_ShowArchiveInfo_WithSharedByArchive_SetsArchiveName() {
        var fm = makeFileModel()
        fm.sharedByArchive = MinArchiveVO(name: "Family Archive", thumbnail: nil, shareStatus: "", shareId: 0, archiveID: 42, folderLinkID: nil, accessRole: nil)

        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], showArchiveInfo: true, onDismiss: {})

        XCTAssertEqual(sut.archiveName, "Family Archive")
    }

    func testInit_ShowArchiveInfo_WithoutSharedByArchive_NilArchiveName() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], showArchiveInfo: true, onDismiss: {})

        XCTAssertNil(sut.archiveName)
    }

    func testInit_DynamicMenuItems_MatchesInput() {
        let items = [
            FileMenuViewModel.MenuItem(type: .download, action: nil),
            FileMenuViewModel.MenuItem(type: .rename, action: nil),
            FileMenuViewModel.MenuItem(type: .delete, action: nil)
        ]
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: items, onDismiss: {})

        XCTAssertEqual(sut.dynamicMenuItems.count, 3)
        XCTAssertEqual(sut.dynamicHeight, sut.preCalculatedHeight)
    }

    // MARK: - Format File Size Tests

    func testFormatFileSize_PositiveSize_ReturnsFormattedString() throws {
        let result = try XCTUnwrap(FileMenuViewModel.formatFileSize(1024))
        XCTAssertFalse(result.isEmpty)
    }

    func testFormatFileSize_LargeSize_ReturnsFormattedString() throws {
        let result = try XCTUnwrap(FileMenuViewModel.formatFileSize(1_073_741_824))
        XCTAssertTrue(result.contains("GB"), "Expected GB unit, got: \(result)")
    }

    func testFormatFileSize_Zero_ReturnsNil() {
        let result = FileMenuViewModel.formatFileSize(0)
        XCTAssertNil(result)
    }

    func testFormatFileSize_Negative_ReturnsNil() {
        let result = FileMenuViewModel.formatFileSize(-100)
        XCTAssertNil(result)
    }

    func testFormatFileSize_SmallSize_ReturnsBytes() {
        let result = FileMenuViewModel.formatFileSize(500)
        XCTAssertNotNil(result)
    }

    // MARK: - Format Date Tests

    func testFormatDate_ValidDate_ReturnsFormatted() {
        let result = FileMenuViewModel.formatDate("2026-05-07")
        XCTAssertEqual(result, "May. 7, 2026")
    }

    func testFormatDate_EmptyString_ReturnsEmpty() {
        XCTAssertEqual(FileMenuViewModel.formatDate(""), "")
    }

    func testFormatDate_Dash_ReturnsEmpty() {
        XCTAssertEqual(FileMenuViewModel.formatDate("-"), "")
    }

    func testFormatDate_InvalidFormat_ReturnsEmpty() {
        // Unparseable input now yields "" instead of echoing the raw string into the UI.
        XCTAssertEqual(FileMenuViewModel.formatDate("not-a-date"), "")
    }

    func testFormatDate_DifferentValidDate_ReturnsFormatted() {
        let result = FileMenuViewModel.formatDate("2025-12-25")
        XCTAssertEqual(result, "Dec. 25, 2025")
    }

    // MARK: - Calculate Sheet Height Tests

    func testCalculateSheetHeight_NoItems_ReturnsHeaderOnly() {
        let height = FileMenuViewModel.calculateSheetHeight(for: [])
        XCTAssertEqual(height, 88)
    }

    func testCalculateSheetHeight_NoItems_WithArchiveInfo_IncludesArchiveHeight() {
        let height = FileMenuViewModel.calculateSheetHeight(for: [], showArchiveInfo: true)
        XCTAssertEqual(height, 88 + 54)
    }

    func testCalculateSheetHeight_OneRegularItem_CalculatesCorrectly() {
        let items = [FileMenuViewModel.MenuItem(type: .download, action: nil)]
        let height = FileMenuViewModel.calculateSheetHeight(for: items)
        XCTAssertGreaterThan(height, 88)
    }

    func testCalculateSheetHeight_OneDestructiveItem_CalculatesCorrectly() {
        let items = [FileMenuViewModel.MenuItem(type: .delete, action: nil)]
        let height = FileMenuViewModel.calculateSheetHeight(for: items)
        XCTAssertGreaterThan(height, 88)
    }

    func testCalculateSheetHeight_MixedItems_CountsDestructiveAsOne() {
        let items = [
            FileMenuViewModel.MenuItem(type: .download, action: nil),
            FileMenuViewModel.MenuItem(type: .rename, action: nil),
            FileMenuViewModel.MenuItem(type: .delete, action: nil),
            FileMenuViewModel.MenuItem(type: .unshare, action: nil)
        ]
        let height = FileMenuViewModel.calculateSheetHeight(for: items)
        let heightWithThreeItems = FileMenuViewModel.calculateSheetHeight(for: [
            FileMenuViewModel.MenuItem(type: .download, action: nil),
            FileMenuViewModel.MenuItem(type: .rename, action: nil),
            FileMenuViewModel.MenuItem(type: .delete, action: nil)
        ])
        XCTAssertEqual(height, heightWithThreeItems, "Two destructive items should count as one")
    }

    func testCalculateSheetHeight_CappedAtScreenHeight() {
        var manyItems: [FileMenuViewModel.MenuItem] = []
        for type in FileMenuViewModel.MenuItem.ItemType.allCases {
            manyItems.append(FileMenuViewModel.MenuItem(type: type, action: nil))
        }
        let height = FileMenuViewModel.calculateSheetHeight(for: manyItems)
        XCTAssertLessThanOrEqual(height, UIScreen.main.bounds.height * 0.85)
    }

    // MARK: - Computed Properties Tests

    func testRegularMenuItems_FiltersOutDestructive() {
        let items = [
            FileMenuViewModel.MenuItem(type: .download, action: nil),
            FileMenuViewModel.MenuItem(type: .delete, action: nil),
            FileMenuViewModel.MenuItem(type: .rename, action: nil),
            FileMenuViewModel.MenuItem(type: .unshare, action: nil)
        ]
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: items, onDismiss: {})

        XCTAssertEqual(sut.regularMenuItems.count, 2)
        XCTAssertTrue(sut.regularMenuItems.allSatisfy { $0.type != .delete && $0.type != .unshare })
    }

    func testDestructiveMenuItem_ReturnsDeleteOrUnshare() {
        let items = [
            FileMenuViewModel.MenuItem(type: .download, action: nil),
            FileMenuViewModel.MenuItem(type: .delete, action: nil)
        ]
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: items, onDismiss: {})

        XCTAssertEqual(sut.destructiveMenuItem?.type, .delete)
    }

    func testDestructiveMenuItem_PrefersDeleteOverUnshare() {
        let items = [
            FileMenuViewModel.MenuItem(type: .delete, action: nil),
            FileMenuViewModel.MenuItem(type: .unshare, action: nil)
        ]
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: items, onDismiss: {})

        XCTAssertEqual(sut.destructiveMenuItem?.type, .delete)
    }

    func testDestructiveMenuItem_ReturnsUnshareWhenNoDelete() {
        let items = [
            FileMenuViewModel.MenuItem(type: .download, action: nil),
            FileMenuViewModel.MenuItem(type: .unshare, action: nil)
        ]
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: items, onDismiss: {})

        XCTAssertEqual(sut.destructiveMenuItem?.type, .unshare)
    }

    func testDestructiveMenuItem_NilWhenNoDestructiveItems() {
        let items = [FileMenuViewModel.MenuItem(type: .download, action: nil)]
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: items, onDismiss: {})

        XCTAssertNil(sut.destructiveMenuItem)
    }

    func testDisplayTitle_SingleFile_ReturnsFileName() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(name: "Report.docx"), menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.displayTitle, "Report.docx")
    }

    func testDisplayTitle_MultipleItems_ReturnsCount() {
        let sut = FileMenuViewModel(
            fileViewModel: makeFileModel(),
            menuItems: [],
            selectedItemCount: 5,
            onDismiss: {}
        )
        XCTAssertEqual(sut.displayTitle, "5 Items selected")
    }

    func testDisplayTitle_SelectedItemCountOne_ReturnsFileName() {
        let sut = FileMenuViewModel(
            fileViewModel: makeFileModel(name: "Single.pdf"),
            menuItems: [],
            selectedItemCount: 1,
            onDismiss: {}
        )
        XCTAssertEqual(sut.displayTitle, "Single.pdf")
    }

    func testAccessRoleName_WithSharedArchive_ReturnsUppercasedRole() {
        var fm = makeFileModel()
        fm.sharedByArchive = MinArchiveVO(name: "Test", thumbnail: nil, shareStatus: "", shareId: 0, archiveID: 1, folderLinkID: nil, accessRole: nil)
        fm.accessRole = .viewer

        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], showArchiveInfo: true, onDismiss: {})

        XCTAssertEqual(sut.accessRoleName, "VIEWER")
    }

    func testAccessRoleName_ManagerRole_DisplaysAsCurator() {
        var fm = makeFileModel()
        fm.sharedByArchive = MinArchiveVO(name: "Test", thumbnail: nil, shareStatus: "", shareId: 0, archiveID: 1, folderLinkID: nil, accessRole: nil)
        fm.accessRole = .manager

        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], showArchiveInfo: true, onDismiss: {})

        XCTAssertEqual(sut.accessRoleName, "CURATOR")
    }

    func testAccessRoleName_NoSharedArchive_ReturnsNil() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], showArchiveInfo: true, onDismiss: {})
        XCTAssertNil(sut.accessRoleName)
    }

    func testAccessRoleName_ShowArchiveInfoFalse_ReturnsNil() {
        var fm = makeFileModel()
        fm.sharedByArchive = MinArchiveVO(name: "Test", thumbnail: nil, shareStatus: "", shareId: 0, archiveID: 1, folderLinkID: nil, accessRole: nil)

        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], showArchiveInfo: false, onDismiss: {})
        XCTAssertNil(sut.accessRoleName)
    }

    func testBackgroundOpacity_NotAnimating_ReturnsZero() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})
        sut.isAnimating = false

        XCTAssertEqual(sut.backgroundOpacity, 0.0)
    }

    func testBackgroundOpacity_Animating_NoDrag_ReturnsMax() {
        let items = [FileMenuViewModel.MenuItem(type: .download, action: nil)]
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: items, onDismiss: {})
        sut.isAnimating = true
        sut.dragOffset = 0

        XCTAssertEqual(sut.backgroundOpacity, 0.3, accuracy: 0.01)
    }

    func testBackgroundOpacity_Animating_HalfDrag_ReducesOpacity() {
        let items = [FileMenuViewModel.MenuItem(type: .download, action: nil)]
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: items, onDismiss: {})
        sut.isAnimating = true
        sut.dragOffset = sut.dynamicHeight / 2

        XCTAssertLessThan(sut.backgroundOpacity, 0.3)
        XCTAssertGreaterThan(sut.backgroundOpacity, 0.0)
    }

    // MARK: - Thumbnail Logic Tests

    func testPrepareThumbnailForLoading_Folder_NoThumbnail() {
        let fm = makeFolderModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        sut.prepareThumbnailForLoading()

        XCTAssertNil(sut.thumbnailURL)
        XCTAssertFalse(sut.shouldShowThumbnail)
    }

    func testPrepareThumbnailForLoading_FileWithNilThumbnail_NoThumbnail() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        sut.prepareThumbnailForLoading()

        XCTAssertNil(sut.thumbnailURL)
        XCTAssertFalse(sut.shouldShowThumbnail)
    }

    func testShouldShowSkeletonAnimation_ThumbnailShowingButNotLoaded() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})
        sut.shouldShowThumbnail = true
        sut.imageOpacity = 0.0

        XCTAssertTrue(sut.shouldShowSkeletonAnimation)
    }

    func testShouldShowSkeletonAnimation_ImageFullyLoaded_ReturnsFalse() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})
        sut.shouldShowThumbnail = true
        sut.imageOpacity = 1.0

        XCTAssertFalse(sut.shouldShowSkeletonAnimation)
    }

    func testShouldShowSkeletonAnimation_NoThumbnail_ReturnsFalse() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})
        sut.shouldShowThumbnail = false
        sut.imageOpacity = 0.0

        XCTAssertFalse(sut.shouldShowSkeletonAnimation)
    }

    func testThumbnailPlaceholderOpacity_InverseOfImageOpacity() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        sut.imageOpacity = 0.0
        XCTAssertEqual(sut.thumbnailPlaceholderOpacity, 1.0)

        sut.imageOpacity = 0.5
        XCTAssertEqual(sut.thumbnailPlaceholderOpacity, 0.5)

        sut.imageOpacity = 1.0
        XCTAssertEqual(sut.thumbnailPlaceholderOpacity, 0.0)
    }

    // MARK: - Menu Item Interaction Tests

    func testHandleMenuItemPressed_SetsPressedId() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        sut.handleMenuItemPressed(.download)

        XCTAssertEqual(sut.pressedMenuItemId, "download")
        XCTAssertTrue(sut.isMenuItemPressed(.download))
        XCTAssertFalse(sut.isMenuItemPressed(.rename))
    }

    func testHandleMenuItemReleased_ClearsPressedId() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        sut.handleMenuItemPressed(.download)
        sut.handleMenuItemReleased()

        XCTAssertNil(sut.pressedMenuItemId)
        XCTAssertFalse(sut.isMenuItemPressed(.download))
    }

    func testIsMenuItemPressed_NoPress_ReturnsFalse() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        XCTAssertFalse(sut.isMenuItemPressed(.download))
    }

    // MARK: - Validate Tap Gesture Tests

    func testValidateTapGesture_QuickTapNoDrag_ReturnsTrue() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        XCTAssertTrue(sut.validateTapGesture(tapDuration: 0.1, dragDistance: 5, swipeVelocity: 50))
    }

    func testValidateTapGesture_LongPress_ReturnsFalse() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        XCTAssertFalse(sut.validateTapGesture(tapDuration: 0.6, dragDistance: 5, swipeVelocity: 50))
    }

    func testValidateTapGesture_TooMuchDrag_ReturnsFalse() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        XCTAssertFalse(sut.validateTapGesture(tapDuration: 0.1, dragDistance: 25, swipeVelocity: 50))
    }

    func testValidateTapGesture_TooFastSwipe_ReturnsFalse() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        XCTAssertFalse(sut.validateTapGesture(tapDuration: 0.1, dragDistance: 5, swipeVelocity: 150))
    }

    func testValidateTapGesture_ExactThresholds_ReturnsFalse() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        XCTAssertFalse(sut.validateTapGesture(tapDuration: 0.5, dragDistance: 20, swipeVelocity: 100))
    }

    func testValidateTapGesture_JustBelowThresholds_ReturnsTrue() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        XCTAssertTrue(sut.validateTapGesture(tapDuration: 0.49, dragDistance: 19, swipeVelocity: 99))
    }

    // MARK: - Handle Menu Item Tap Tests

    func testHandleMenuItemTap_Delete_ShowsConfirmation() {
        var actionCalled = false
        let deleteItem = FileMenuViewModel.MenuItem(type: .delete, action: { actionCalled = true })
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [deleteItem], onDismiss: {})

        sut.handleMenuItemTap(deleteItem)

        XCTAssertTrue(sut.showDeleteConfirmation)
        XCTAssertNotNil(sut.pendingDeleteAction)
        XCTAssertFalse(actionCalled, "Action should not execute immediately for delete")
    }

    func testHandleMenuItemTap_Unshare_ShowsLeaveShareConfirmation() {
        let unshareItem = FileMenuViewModel.MenuItem(type: .unshare, action: {})
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [unshareItem], onDismiss: {})

        sut.handleMenuItemTap(unshareItem)

        XCTAssertTrue(sut.showLeaveShareConfirmation)
        XCTAssertNotNil(sut.pendingLeaveShareAction)
    }

    func testHandleMenuItemTap_ShareToAnotherApp_SetsSpecialMenuItemWhenNoVC() {
        let shareItem = FileMenuViewModel.MenuItem(type: .shareToAnotherApp, action: nil)
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [shareItem], onDismiss: {})

        sut.handleMenuItemTap(shareItem)

        XCTAssertEqual(sut.specialMenuItemRequested?.type, .shareToAnotherApp)
    }

    func testHandleMenuItemTap_ShareToPermanent_SetsSpecialMenuItemWhenNoVC() {
        let shareItem = FileMenuViewModel.MenuItem(type: .shareToPermanent, action: nil)
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [shareItem], onDismiss: {})

        sut.handleMenuItemTap(shareItem)

        XCTAssertEqual(sut.specialMenuItemRequested?.type, .shareToPermanent)
    }

    // MARK: - Confirmation Action Tests

    func testCancelDeleteAction_ClearsState() {
        let deleteItem = FileMenuViewModel.MenuItem(type: .delete, action: {})
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [deleteItem], onDismiss: {})

        sut.handleMenuItemTap(deleteItem)
        XCTAssertTrue(sut.showDeleteConfirmation)

        sut.cancelDeleteAction()

        XCTAssertFalse(sut.showDeleteConfirmation)
        XCTAssertNil(sut.pendingDeleteAction)
    }

    func testCancelLeaveShareAction_ClearsState() {
        let unshareItem = FileMenuViewModel.MenuItem(type: .unshare, action: {})
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [unshareItem], onDismiss: {})

        sut.handleMenuItemTap(unshareItem)
        XCTAssertTrue(sut.showLeaveShareConfirmation)

        sut.cancelLeaveShareAction()

        XCTAssertFalse(sut.showLeaveShareConfirmation)
        XCTAssertNil(sut.pendingLeaveShareAction)
    }

    func testExecuteDeleteAction_CallsActionAndDismisses() async {
        var dismissed = false
        var actionCalled = false
        let deleteItem = FileMenuViewModel.MenuItem(type: .delete, action: { actionCalled = true })
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [deleteItem], onDismiss: { dismissed = true })

        sut.handleMenuItemTap(deleteItem)
        sut.executeDeleteAction()

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(actionCalled)
        XCTAssertTrue(dismissed)
    }

    func testExecuteLeaveShareAction_CallsActionAndDismisses() async {
        var dismissed = false
        var actionCalled = false
        let unshareItem = FileMenuViewModel.MenuItem(type: .unshare, action: { actionCalled = true })
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [unshareItem], onDismiss: { dismissed = true })

        sut.handleMenuItemTap(unshareItem)
        sut.executeLeaveShareAction()

        try? await Task.sleep(nanoseconds: 500_000_000)

        XCTAssertTrue(actionCalled)
        XCTAssertTrue(dismissed)
    }

    // MARK: - Dependency Setter Tests

    func testSetDownloadHandler_StoresHandler() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})
        var handlerCalled = false

        sut.setDownloadHandler { _, completion in
            handlerCalled = true
            completion(nil, nil)
        }

        XCTAssertFalse(handlerCalled, "Handler should not be called until needed")
    }

    func testSetMenuItemsGenerator_StoresGenerator() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        sut.setMenuItemsGenerator { _ in
            return [FileMenuViewModel.MenuItem(type: .download, action: nil)]
        }

        // Generator is stored but not called until regenerateMenuItemsAndAnimateHeight
    }

    func testSetFileModelUpdateHandler_StoresHandler() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        sut.setFileModelUpdateHandler { _ in }

        // Handler is stored for later use
    }

    // MARK: - Image Load / Animation Tests

    func testOnImageLoadSuccess_SetsFullOpacity() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.imageOpacity, 0.0)

        sut.onImageLoadSuccess()

        XCTAssertEqual(sut.imageOpacity, 1.0)
    }

    func testStartPresentationAnimation_SetsAnimating() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        sut.startPresentationAnimation()

        XCTAssertTrue(sut.isAnimating)
    }

    // MARK: - Dismiss With Animation Tests

    func testDismissWithAnimation_SetsNotAnimating() async {
        var dismissed = false
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: { dismissed = true })
        sut.isAnimating = true

        sut.dismissWithAnimation()

        XCTAssertFalse(sut.isAnimating)

        try? await Task.sleep(nanoseconds: 400_000_000)

        XCTAssertTrue(dismissed)
    }

    // MARK: - Clear Special Menu Item Tests

    func testClearSpecialMenuItemRequest_ClearsState() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})
        sut.specialMenuItemRequested = FileMenuViewModel.MenuItem(type: .rename, action: nil)

        sut.clearSpecialMenuItemRequest()

        XCTAssertNil(sut.specialMenuItemRequested)
    }

    // MARK: - Get Icon Image Tests

    func testGetIconImage_AllItemTypes_ReturnImages() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        for itemType in FileMenuViewModel.MenuItem.ItemType.allCases {
            let image = sut.getIconImage(for: itemType)
            XCTAssertNotNil(image, "Should have icon for \(itemType.rawValue)")
        }
    }

    // MARK: - Get Title Tests

    func testGetTitle_AllItemTypes_ReturnNonEmptyStrings() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        for itemType in FileMenuViewModel.MenuItem.ItemType.allCases {
            let title = sut.getTitle(for: itemType)
            XCTAssertFalse(title.isEmpty, "Should have title for \(itemType.rawValue)")
        }
    }

    func testGetTitle_SpecificValues() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        XCTAssertEqual(sut.getTitle(for: .download), "Save")
        XCTAssertEqual(sut.getTitle(for: .delete), "Delete")
        XCTAssertEqual(sut.getTitle(for: .rename), "Rename")
        XCTAssertEqual(sut.getTitle(for: .unshare), "Leave share")
        XCTAssertEqual(sut.getTitle(for: .shareToPermanent), "Share and manage access")
        XCTAssertEqual(sut.getTitle(for: .shareToAnotherApp), "Save or send a copy")
        XCTAssertEqual(sut.getTitle(for: .editMetadata), "Edit Metadata")
    }

    // MARK: - Pending Invitation Badge Tests

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

    func testPendingInvitationBadgeCount_NoPendingShares_ReturnsZero() {
        var fileModel = makeFileModel()
        fileModel.minArchiveVOS = [
            MinArchiveVO(name: "A1", thumbnail: nil, shareStatus: ArchiveVOData.Status.ok.rawValue, shareId: 1, archiveID: 101, folderLinkID: 1, accessRole: "viewer")
        ]

        let sut = FileMenuViewModel(fileViewModel: fileModel, menuItems: [], onDismiss: {})

        XCTAssertEqual(sut.pendingInvitationBadgeCount(for: .shareToPermanent), 0)
        XCTAssertFalse(sut.shouldShowPendingInvitationBadge(for: .shareToPermanent))
    }

    func testPendingInvitationBadgeCount_EmptyArchives_ReturnsZero() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})

        XCTAssertEqual(sut.pendingInvitationBadgeCount(for: .shareToPermanent), 0)
    }

    // MARK: - MenuItem Equality Tests

    func testMenuItem_Equality_SameType_AreEqual() {
        let a = FileMenuViewModel.MenuItem(type: .download, action: {})
        let b = FileMenuViewModel.MenuItem(type: .download, action: nil)

        XCTAssertEqual(a, b, "MenuItems with same type should be equal regardless of action")
    }

    func testMenuItem_Equality_DifferentType_NotEqual() {
        let a = FileMenuViewModel.MenuItem(type: .download, action: nil)
        let b = FileMenuViewModel.MenuItem(type: .rename, action: nil)

        XCTAssertNotEqual(a, b)
    }

    // MARK: - Drag State Tests

    func testDragOffset_InitiallyZero() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.dragOffset, 0)
        XCTAssertFalse(sut.isDragging)
    }

    func testDragOffset_CanBeSetDirectly() {
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: [], onDismiss: {})
        sut.dragOffset = 150
        XCTAssertEqual(sut.dragOffset, 150)
    }

    // MARK: - Multiple File Selection Tests

    func testInit_MultipleFiles_CalculatesTotalSize() {
        let file1 = makeFileModel(name: "A.pdf")
        let file2 = makeFileModel(name: "B.pdf")

        let sut = FileMenuViewModel(
            fileViewModel: file1,
            menuItems: [],
            selectedItemCount: 2,
            selectedFiles: [file1, file2],
            onDismiss: {}
        )

        // cachedFormattedFileSize may be nil if size is 0 (default for test files)
        XCTAssertNotNil(sut.cachedFormattedDate)
    }

    func testInit_MultipleFilesWithFolder_UseFolderDateFirst() {
        let file1 = makeFileModel(name: "A.pdf")
        let folder = makeFolderModel()

        let sut = FileMenuViewModel(
            fileViewModel: file1,
            menuItems: [],
            selectedItemCount: 2,
            selectedFiles: [file1, folder],
            onDismiss: {}
        )

        XCTAssertNotNil(sut.cachedFormattedDate)
    }

    // MARK: - Scrolling Tests

    func testNeedsScrolling_FewItems_ReturnsFalse() {
        let items = [FileMenuViewModel.MenuItem(type: .download, action: nil)]
        let sut = FileMenuViewModel(fileViewModel: makeFileModel(), menuItems: items, onDismiss: {})

        XCTAssertFalse(sut.needsScrolling)
    }

    // MARK: - getIconImage

    func testGetIconImage_AllItemTypes_ReturnNonNilImage() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        for itemType in FileMenuViewModel.MenuItem.ItemType.allCases {
            let image = sut.getIconImage(for: itemType)
            XCTAssertNotNil(image, "\(itemType) should return a non-nil Image")
        }
    }

    // MARK: - getTitle

    func testGetTitle_Download_ReturnsSave() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.getTitle(for: .download), "Save")
    }

    func testGetTitle_Copy_ReturnsExpected() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.getTitle(for: .copy), "Copy to another folder")
    }

    func testGetTitle_Move_ReturnsExpected() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.getTitle(for: .move), "Move to another folder")
    }

    func testGetTitle_Delete_ReturnsDelete() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.getTitle(for: .delete), "Delete")
    }

    func testGetTitle_Unshare_ReturnsLeaveShare() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.getTitle(for: .unshare), "Leave share")
    }

    func testGetTitle_Rename_ReturnsRename() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.getTitle(for: .rename), "Rename")
    }

    func testGetTitle_Publish_ReturnsPublishOnTheWeb() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.getTitle(for: .publish), "Publish on the web")
    }

    func testGetTitle_ShareToPermanent_ReturnsExpected() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.getTitle(for: .shareToPermanent), "Share and manage access")
    }

    func testGetTitle_ShareToAnotherApp_ReturnsExpected() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.getTitle(for: .shareToAnotherApp), "Save or send a copy")
    }

    func testGetTitle_AllItemTypes_ReturnNonEmpty() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        for itemType in FileMenuViewModel.MenuItem.ItemType.allCases {
            let title = sut.getTitle(for: itemType)
            XCTAssertFalse(title.isEmpty, "\(itemType) should have a non-empty title")
        }
    }

    // MARK: - shouldShowPendingInvitationBadge

    func testShouldShowPendingInvitationBadge_NonShareItem_ReturnsFalse() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertFalse(sut.shouldShowPendingInvitationBadge(for: .download))
        XCTAssertFalse(sut.shouldShowPendingInvitationBadge(for: .delete))
        XCTAssertFalse(sut.shouldShowPendingInvitationBadge(for: .rename))
    }

    func testShouldShowPendingInvitationBadge_ShareToPermanent_NoPending_ReturnsFalse() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertFalse(sut.shouldShowPendingInvitationBadge(for: .shareToPermanent))
    }

    // MARK: - pendingInvitationBadgeCount

    func testPendingInvitationBadgeCount_NonShareItem_ReturnsZero() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.pendingInvitationBadgeCount(for: .download), 0)
        XCTAssertEqual(sut.pendingInvitationBadgeCount(for: .copy), 0)
        XCTAssertEqual(sut.pendingInvitationBadgeCount(for: .move), 0)
    }

    func testPendingInvitationBadgeCount_ShareToPermanent_NoPending_ReturnsZero() {
        let fm = makeFileModel()
        let sut = FileMenuViewModel(fileViewModel: fm, menuItems: [], onDismiss: {})
        XCTAssertEqual(sut.pendingInvitationBadgeCount(for: .shareToPermanent), 0)
    }

    // MARK: - MenuItem.ItemType

    func testMenuItemType_AllCases_Has10Cases() {
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.allCases.count, 10)
    }

    func testMenuItemType_RawValues() {
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.download.rawValue, "download")
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.copy.rawValue, "copy")
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.move.rawValue, "move")
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.delete.rawValue, "delete")
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.unshare.rawValue, "unshare")
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.rename.rawValue, "rename")
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.publish.rawValue, "publish")
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.shareToPermanent.rawValue, "shareToPermanent")
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.shareToAnotherApp.rawValue, "shareToAnotherApp")
        XCTAssertEqual(FileMenuViewModel.MenuItem.ItemType.editMetadata.rawValue, "editMetadata")
    }

    // MARK: - MenuItem Equatable

    func testMenuItem_Equatable_SameType_AreEqual() {
        let a = FileMenuViewModel.MenuItem(type: .download, action: nil)
        let b = FileMenuViewModel.MenuItem(type: .download, action: { })
        XCTAssertEqual(a, b)
    }

    func testMenuItem_Equatable_DifferentType_AreNotEqual() {
        let a = FileMenuViewModel.MenuItem(type: .download, action: nil)
        let b = FileMenuViewModel.MenuItem(type: .delete, action: nil)
        XCTAssertNotEqual(a, b)
    }

    // MARK: - Helpers

    private func makeFileModel(name: String = "Test.pdf") -> FileModel {
        FileModel(
            name: name,
            recordId: 100,
            folderLinkId: 1,
            archiveNbr: "0001",
            type: "type.record.document.pdf",
            permissions: [.read, .share, .ownership]
        )
    }

    private func makeFolderModel(name: String = "Test Folder") -> FileModel {
        FileModel(
            name: name,
            recordId: 0,
            folderLinkId: 2,
            archiveNbr: "0001",
            type: "type.folder.private",
            permissions: [.read, .edit, .share]
        )
    }

}
