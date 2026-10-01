//
//  SharesViewControllerTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 13.03.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class SharesViewControllerTests: XCTestCase {
    override func tearDown() {
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.sharedFileKey)
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.sharedFolderKey)
        super.tearDown()
    }

    func testNumberOfSectionsUsesViewModelValue() {
        let vc = makeController()
        let collectionView = makeCollectionView()
        vc.collectionView = collectionView

        XCTAssertEqual(vc.numberOfSections(in: collectionView), 4, "the view model's three sections plus the paging section")
    }

    func testNumberOfItemsInSyncedSectionUsesViewModelRows() {
        let vc = makeController()
        vc.viewModel?.viewModels = [makeFolder(name: "A", folderLinkId: 1), makeFolder(name: "B", folderLinkId: 2)]
        let collectionView = makeCollectionView()
        vc.collectionView = collectionView

        XCTAssertEqual(vc.collectionView(collectionView, numberOfItemsInSection: FileListType.synced.rawValue), 2)
    }

    func testSwitchViewButtonPressedChangesSyncedSizeToGrid() {
        let vc = makeController()
        let collectionView = makeCollectionView()
        let switchButton = UIButton(type: .system)
        vc.collectionView = collectionView
        vc.switchViewButton = switchButton

        let listSize = vc.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))
        vc.switchViewButtonPressed(self)
        let gridSize = vc.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))

        XCTAssertGreaterThan(gridSize.height, listSize.height)
    }

    func testSizeForItemAtNonSyncedSectionStaysListHeight() {
        let vc = makeController()
        let collectionView = makeCollectionView()
        let switchButton = UIButton(type: .system)
        vc.collectionView = collectionView
        vc.switchViewButton = switchButton

        vc.switchViewButtonPressed(self)
        let size = vc.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(row: 0, section: FileListType.downloading.rawValue))

        XCTAssertEqual(size.height, 70)
    }

    func testReferenceSizeForHeaderZeroWhenNoRowsOrEmptyTitle() {
        let vc = makeController()
        let collectionView = makeCollectionView()
        vc.collectionView = collectionView

        let size = vc.collectionView(collectionView, layout: collectionView.collectionViewLayout, referenceSizeForHeaderInSection: FileListType.synced.rawValue)
        XCTAssertEqual(size.height, 0)
    }

    func testReferenceSizeForHeaderIsTheRowHeightWhenRowsAndTitleExist() {
        let vc = makeController()
        vc.viewModel?.navigationStack = [makeFolder(name: "Root", folderLinkId: 100)]
        vc.viewModel?.viewModels = [makeFolder(name: "Child", folderLinkId: 101)]
        let collectionView = makeCollectionView()
        vc.collectionView = collectionView

        let size = vc.collectionView(collectionView, layout: collectionView.collectionViewLayout, referenceSizeForHeaderInSection: FileListType.synced.rawValue)
        XCTAssertEqual(size.height, 40)
    }

    func testDidSelectItemAtSelectingModeAppendsSelection() throws {
        let vc = makeController()
        let vm = try XCTUnwrap(vc.viewModel)
        let file = makeFolder(name: "Folder A", folderLinkId: 10)
        vm.viewModels = [file]
        vm.selectedFiles = []
        vm.isSelecting = true

        let collectionView = makeCollectionView()
        vc.collectionView = collectionView

        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))
        XCTAssertEqual(vm.selectedFiles?.count, 1)
    }

    func testDidSelectItemAtSelectingModeRemovesExistingSelection() throws {
        let vc = makeController()
        let vm = try XCTUnwrap(vc.viewModel)
        let file = makeFolder(name: "Folder A", folderLinkId: 11)
        vm.viewModels = [file]
        vm.selectedFiles = [file]
        vm.isSelecting = true

        let collectionView = makeCollectionView()
        vc.collectionView = collectionView

        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))
        XCTAssertTrue(vm.selectedFiles?.isEmpty ?? false)
    }

    func testDidSelectItemAtFolderNavigatesAndUpdatesLabels() {
        let vc = TestableSharesViewController()
        let vm = MockSharedFilesViewModel()
        vc.viewModel = vm
        vm.viewModels = [makeFolder(name: "Shared Folder", folderLinkId: 200)]
        vm.isSelecting = false
        vm.selectedFiles = []

        let collectionView = makeCollectionView()
        let backButton = UIButton(type: .system)
        let directoryLabel = UILabel()
        vc.collectionView = collectionView
        vc.backButton = backButton
        vc.directoryLabel = directoryLabel
        backButton.isHidden = true

        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))

        XCTAssertTrue(vc.didNavigateToFolder)
        XCTAssertEqual(vc.lastNavigateParams?.folderLinkId, 200)
        XCTAssertFalse(backButton.isHidden)
        XCTAssertEqual(directoryLabel.text, "Shared Folder")
    }

    func testDidSelectItemAtFilePresentsPreviewController() {
        let vc = TestableSharesViewController()
        let vm = MockSharedFilesViewModel()
        vc.viewModel = vm
        vm.viewModels = [makeFile(name: "Doc", folderLinkId: 201)]
        vm.isSelecting = false

        let collectionView = makeCollectionView()
        vc.collectionView = collectionView

        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))

        XCTAssertTrue(vc.didPresentViewController)
        XCTAssertTrue(vc.lastPresentedViewController is FilePreviewNavigationController)
    }

    func testDidSelectItemAtUnsyncedFileDoesNothing() {
        let vc = TestableSharesViewController()
        let vm = MockSharedFilesViewModel()
        vc.viewModel = vm
        var file = makeFile(name: "Failed", folderLinkId: 202)
        file.fileStatus = .failed
        vm.viewModels = [file]

        let collectionView = makeCollectionView()
        vc.collectionView = collectionView

        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))

        XCTAssertFalse(vc.didPresentViewController)
        XCTAssertFalse(vc.didNavigateToFolder)
    }

    func testSegmentedControlValueChangedResetsStateAndSelection() throws {
        let vc = makeController()
        let vm = try XCTUnwrap(vc.viewModel)
        let directoryLabel = UILabel()
        let backButton = UIButton(type: .system)
        let fabView = FABView(frame: .zero)
        let bottomView = BottomActionSheet(frame: .zero)
        let segmented = SlidingTabControl()

        vm.fileAction = .move
        vm.selectedFiles = [makeFile(name: "X", folderLinkId: 203)]
        directoryLabel.text = "Before"
        backButton.isHidden = false
        fabView.isHidden = false
        bottomView.isHidden = false
        segmented.selectedSegmentIndex = ShareListType.sharedWithMe.rawValue

        vc.directoryLabel = directoryLabel
        vc.backButton = backButton
        vc.fabView = fabView
        vc.fileActionBottomView = bottomView

        vc.segmentedControlValueChanged(segmented)

        XCTAssertEqual(vm.shareListType, .sharedWithMe)
        XCTAssertEqual(directoryLabel.text, "Shares")
        XCTAssertTrue(backButton.isHidden)
        XCTAssertTrue(fabView.isHidden)
        XCTAssertTrue(bottomView.isHidden)
        XCTAssertEqual(vm.fileAction, .none)
        XCTAssertTrue(vm.selectedFiles?.isEmpty ?? true)
    }

    func testEmptyState_EachSegmentGetsItsOwnCopy() throws {
        // The two segments need different empty-state copy: the Shared-By-Me message on an empty inbox
        // tells the user they haven't shared anything, which reads as a bug rather than an empty list.
        let vc = makeController()
        let vm = try XCTUnwrap(vc.viewModel)
        vm.viewModels = []
        let segmented = try XCTUnwrap(vc.segmentedControl)

        segmented.selectedSegmentIndex = ShareListType.sharedByMe.rawValue
        vc.segmentedControlValueChanged(segmented)
        let byMeText = (vc.collectionView.backgroundView as? EmptyFolderView)?.emptyFolderLabel.text
        XCTAssertEqual(byMeText, .shareActionMessage)

        segmented.selectedSegmentIndex = ShareListType.sharedWithMe.rawValue
        vc.segmentedControlValueChanged(segmented)
        let withMeText = (vc.collectionView.backgroundView as? EmptyFolderView)?.emptyFolderLabel.text
        XCTAssertEqual(withMeText, .shareWithMeActionMessage)
        XCTAssertNotEqual(withMeText, .shareActionMessage,
                          "an empty inbox must not claim the user hasn't shared anything")
    }

    func testBackButtonActionWithoutHierarchyAndNoActionReturns() throws {
        let vc = makeController()
        let vm = try XCTUnwrap(vc.viewModel as? MockSharedFilesViewModel)
        vm.fileAction = .none
        vm.navigationStack = []

        vc.backButtonAction(UIButton(type: .system))

        XCTAssertTrue(vm.navigationStack.isEmpty)

        vm.navigationStack = [makeFolder(name: "Root", folderLinkId: 910)]
        var didCallGetShares = false
        vc.getSharesRequest = { completion in
            didCallGetShares = true
            completion(.success)
        }
        vc.backButtonAction(UIButton(type: .system))
        XCTAssertTrue(didCallGetShares)
    }

    func testBackToTheShareList_LoadsItUnderSkeletonRows() throws {
        let vc = makeController()
        let vm = try XCTUnwrap(vc.viewModel)
        vm.navigationStack = [makeFolder(name: "Root", folderLinkId: 910)]
        var pending: ((RequestStatus) -> Void)?
        vc.getSharesRequest = { completion in pending = completion }

        vc.backButtonAction(UIButton(type: .system))

        XCTAssertTrue(vm.isLoadingFirstPage, "skeleton rows, not the spinner")
        XCTAssertEqual(vc.directoryLabel.text, "Shares".localized())
        pending?(.success)
        XCTAssertFalse(vm.isLoadingFirstPage)
    }

    func testBackButtonActionWithMoveAtRootShowsCancelMoveDialog() throws {
        let vc = makeController()
        let vm = try XCTUnwrap(vc.viewModel)
        vm.navigationStack = [makeFolder(name: "Root", folderLinkId: 905)]
        vm.fileAction = .move
        vm.selectedFiles = [makeFile(name: "Doc", folderLinkId: 906)]

        vc.backButtonAction(UIButton(type: .system))

        XCTAssertNotNil(vc.actionDialog)
    }

    func testCheckSavedFileWithoutPayloadReturnsFalse() {
        let vc = makeController()

        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.sharedFileKey)
        let hasSavedFile = vc.checkSavedFile()

        XCTAssertFalse(hasSavedFile)
    }

    func testCheckSavedFileWithPayloadSetsSharedWithMeAndShowsSwitchDialog() {
        let vc = makeController()
        let payload = ShareNotificationPayload(
            name: "Shared File",
            recordId: 21,
            folderLinkId: 901,
            archiveNbr: "1234",
            type: FileType.miscellaneous.rawValue,
            toArchiveId: 999,
            toArchiveNbr: "9999",
            toArchiveName: "Other Archive",
            accessRole: AccessRole.viewer.apiValue
        )

        try? PreferencesManager.shared.setNonPlistObject(payload, forKey: Constants.Keys.StorageKeys.sharedFileKey)
        let hasSavedFile = vc.checkSavedFile()

        let savedValue: ShareNotificationPayload? = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.sharedFileKey)
        XCTAssertTrue(hasSavedFile)
        XCTAssertEqual(vc.selectedIndex, ShareListType.sharedWithMe.rawValue)
        XCTAssertNil(savedValue)
        XCTAssertNotNil(vc.actionDialog)
    }

    func testCheckSavedFolderWithPayloadSetsSharedWithMeAndShowsSwitchDialog() {
        let vc = makeController()
        let payload = ShareNotificationPayload(
            name: "Shared Folder",
            recordId: 0,
            folderLinkId: 902,
            archiveNbr: "1234",
            type: FileType.privateFolder.rawValue,
            toArchiveId: 999,
            toArchiveNbr: "9999",
            toArchiveName: "Other Archive",
            accessRole: AccessRole.viewer.apiValue
        )

        try? PreferencesManager.shared.setNonPlistObject(payload, forKey: Constants.Keys.StorageKeys.sharedFolderKey)
        let hasSavedFolder = vc.checkSavedFolder()

        let savedValue: ShareNotificationPayload? = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.sharedFolderKey)
        XCTAssertTrue(hasSavedFolder)
        XCTAssertEqual(vc.selectedIndex, ShareListType.sharedWithMe.rawValue)
        XCTAssertNil(savedValue)
        XCTAssertNotNil(vc.actionDialog)
    }

    func testRefreshCurrentFolderNavigatesToCurrentFolder() {
        let vc = TestableSharesViewController()
        let vm = MockSharedFilesViewModel()
        let current = makeFolder(name: "Current", folderLinkId: 903)
        vm.navigationStack = [current]
        vc.viewModel = vm
        vc.directoryLabel = UILabel()
        vc.backButton = UIButton(type: .system)

        vc.refreshCurrentFolder(shouldDisplaySpinner: false, then: nil)

        XCTAssertTrue(vc.didNavigateToFolder)
        XCTAssertEqual(vc.lastNavigateParams?.folderLinkId, current.folderLinkId)
    }

    func testPullToRefreshSelectorNavigatesAndInvalidatesTimer() {
        let vc = TestableSharesViewController()
        let vm = MockSharedFilesViewModel()
        vm.navigationStack = [makeFolder(name: "Current", folderLinkId: 904)]
        vc.viewModel = vm
        vc.directoryLabel = UILabel()
        vc.backButton = UIButton(type: .system)
        vc.collectionView = makeCollectionView()

        _ = vc.perform(NSSelectorFromString("pullToRefreshAction"))

        XCTAssertTrue(vc.didNavigateToFolder)
        XCTAssertTrue(vm.didInvalidateTimer)
    }

    func testNavigateToFolderUsesInjectedNavigateMinRequest() throws {
        let vc = makeController()
        let vm = try XCTUnwrap(vc.viewModel as? MockSharedFilesViewModel)
        vm.navigationStack = [makeFolder(name: "Current", folderLinkId: 907)]

        var called = false
        var capturedParams: NavigateMinParams?
        var capturedBack = false
        vc.navigateMinRequest = { params, backNavigation, completion in
            called = true
            capturedParams = params
            capturedBack = backNavigation
            completion(.success)
        }

        vc.navigateToFolder(withParams: ("0000", 777, nil), backNavigation: true, shouldDisplaySpinner: false, then: nil)

        XCTAssertTrue(called)
        XCTAssertEqual(capturedParams?.folderLinkId, 777)
        XCTAssertTrue(capturedBack)
    }

    func testRefreshCurrentFolderWithoutCurrentFolderUsesInjectedGetSharesRequest() throws {
        let vc = makeController()
        let vm = try XCTUnwrap(vc.viewModel as? MockSharedFilesViewModel)
        vm.navigationStack = []

        var called = false
        vc.getSharesRequest = { completion in
            called = true
            completion(.success)
        }

        vc.refreshCurrentFolder(shouldDisplaySpinner: false, then: nil)

        XCTAssertTrue(called)

        let errorVC = AlertTrackingSharesViewController()
        errorVC.viewModel = MockSharedFilesViewModel()
        errorVC.view = UIView(frame: .init(x: 0, y: 0, width: 390, height: 844))
        errorVC.collectionView = makeCollectionView()
        errorVC.directoryLabel = UILabel()
        errorVC.backButton = UIButton(type: .system)
        errorVC.fabView = FABView(frame: .zero)
        errorVC.fileActionBottomView = BottomActionSheet(frame: .zero)
        errorVC.getSharesRequest = { completion in
            completion(.error(message: "Shares error"))
        }
        errorVC.refreshCurrentFolder(shouldDisplaySpinner: false, then: nil)
        XCTAssertTrue(errorVC.didShowAlert)
        XCTAssertEqual(errorVC.lastAlertMessage, "Shares error")
    }

    func testCheckSavedFilePositiveActionUsesInjectedChangeArchiveRequest() {
        let vc = makeController()
        let payload = ShareNotificationPayload(
            name: "Shared File",
            recordId: 31,
            folderLinkId: 908,
            archiveNbr: "1234",
            type: FileType.miscellaneous.rawValue,
            toArchiveId: 999,
            toArchiveNbr: "9999",
            toArchiveName: "Other Archive",
            accessRole: AccessRole.viewer.apiValue
        )

        try? PreferencesManager.shared.setNonPlistObject(payload, forKey: Constants.Keys.StorageKeys.sharedFileKey)
        _ = vc.checkSavedFile()

        var called = false
        vc.changeArchiveRequest = { archiveId, archiveNbr, completion in
            called = true
            XCTAssertEqual(archiveId, 999)
            XCTAssertEqual(archiveNbr, "9999")
            completion(false)
        }

        vc.actionDialog?.positiveAction?()

        XCTAssertTrue(called)

        let folderPayload = ShareNotificationPayload(
            name: "Shared Folder",
            recordId: 0,
            folderLinkId: 909,
            archiveNbr: "1234",
            type: FileType.privateFolder.rawValue,
            toArchiveId: 999,
            toArchiveNbr: "9999",
            toArchiveName: "Other Archive",
            accessRole: AccessRole.viewer.apiValue
        )

        try? PreferencesManager.shared.setNonPlistObject(folderPayload, forKey: Constants.Keys.StorageKeys.sharedFolderKey)
        _ = vc.checkSavedFolder()

        called = false
        vc.changeArchiveRequest = { archiveId, archiveNbr, completion in
            called = true
            XCTAssertEqual(archiveId, 999)
            XCTAssertEqual(archiveNbr, "9999")
            completion(false)
        }

        vc.actionDialog?.positiveAction?()

        XCTAssertTrue(called)
    }

    // MARK: - FAB visibility across select mode
    // A restore path that un-hides unconditionally conjures a + button inside a folder shared at
    // viewer level, which the role does not allow.

    func testDeselect_ViewOnlyFolder_DoesNotRevealFAB() {
        let vc = makeController()
        // A folder shared at viewer level: [.read] only (makeFolder's default).
        vc.viewModel?.navigationStack.append(makeFolder(name: "Shared viewer folder", folderLinkId: 9))
        // The real screen starts with the action sheet hidden; a bare view defaults to
        // visible, and the gate correctly refuses to show the FAB over it.
        vc.fileActionBottomView.isHidden = true

        vc.updateFAB()
        XCTAssertTrue(vc.fabView.isHidden, "precondition: a view-only folder never shows the FAB")

        vc.selectButtonWasPressed(UIButton())
        XCTAssertTrue(vc.fabView.isHidden)

        vc.clearButtonWasPressed(UIButton())
        XCTAssertTrue(vc.fabView.isHidden,
                      "leaving select mode must not conjure + in a folder without write access")
    }

    func testDeselect_WritableFolder_RestoresFAB() {
        let vc = makeController()
        let writable = FileModel(
            name: "Editable shared folder",
            recordId: 0,
            folderLinkId: 9,
            archiveNbr: "0001-0000",
            type: FileType.privateFolder.rawValue,
            permissions: [.read, .create, .upload]
        )
        vc.viewModel?.navigationStack.append(writable)
        // The real screen starts with the action sheet hidden; a bare view defaults to
        // visible, and the gate correctly refuses to show the FAB over it.
        vc.fileActionBottomView.isHidden = true

        vc.updateFAB()
        XCTAssertFalse(vc.fabView.isHidden, "precondition: writable folder shows the FAB")

        vc.selectButtonWasPressed(UIButton())
        XCTAssertTrue(vc.fabView.isHidden, "select mode owns the screen while active")

        vc.clearButtonWasPressed(UIButton())
        XCTAssertFalse(vc.fabView.isHidden, "deselect restores the FAB when permissions allow")
    }

    func testClosingTheMoveBar_BringsThePlusButtonBack() {
        let vc = makeController()
        let writable = FileModel(
            name: "Editable shared folder",
            recordId: 0,
            folderLinkId: 9,
            archiveNbr: "0001-0000",
            type: FileType.privateFolder.rawValue,
            permissions: [.read, .create, .upload]
        )
        vc.viewModel?.navigationStack.append(writable)
        vc.fileActionBottomView.isHidden = true
        vc.viewModel?.isSelectingDestination = true
        vc.updateFAB()
        XCTAssertTrue(vc.fabView.isHidden, "precondition: no plus button while a Move waits for its folder")

        vc.cancelRelocate()

        XCTAssertEqual(vc.viewModel?.isSelectingDestination, false)
        XCTAssertFalse(vc.fabView.isHidden, "the X on the bar brings the plus button back")
    }

    // MARK: - The pinned sort and Select row

    private static let header = UICollectionView.elementKindSectionHeader

    /// The Shares screen over a 390 x 844pt list in a window, with the screen's own cells and header registered,
    /// showing 30 rows: a shared folder's files, or the share list itself.
    private func makeHostedController(inFolder: Bool = true) -> (vc: SharesViewController, list: StickyHeaderTestList, answer: () -> ((RequestStatus) -> Void)?) {
        let list = StickyHeaderTestList()
        list.register(UINib(nibName: "FileCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "FileCell")
        list.register(UINib(nibName: "FileCollectionViewGridCell", bundle: nil), forCellWithReuseIdentifier: "FileGridCell")
        list.register(FileCollectionViewHeaderCell.nib(), forSupplementaryViewOfKind: Self.header, withReuseIdentifier: FileCollectionViewHeaderCell.identifier)
        let vc = makeController(list: list)
        list.dataSource = vc
        list.delegate = vc
        var pending: ((RequestStatus) -> Void)?
        vc.navigateMinRequest = { _, _, completion in pending = completion }
        let viewModel = vc.viewModel!
        if inFolder {
            viewModel.navigationStack = [makeFolder(name: "Shared folder", folderLinkId: 40)]
            viewModel.viewModels = (0..<30).map { makeFile(name: "File \($0)", folderLinkId: 100 + $0) }
        } else {
            viewModel.viewModels = (0..<30).map { makeFolder(name: "Share \($0)", folderLinkId: 100 + $0) }
        }
        let window = UIWindow(frame: vc.view.frame)
        window.addSubview(vc.view)
        window.isHidden = false
        addTeardownBlock { window.isHidden = true }
        list.reloadData()
        list.scroll(to: 0)
        return (vc, list, { pending })
    }

    private func stickyLayout(of list: UICollectionView) throws -> StickyHeaderFlowLayout {
        try XCTUnwrap(list.collectionViewLayout as? StickyHeaderFlowLayout)
    }

    private func syncedHeaderView(in list: UICollectionView) throws -> FileCollectionViewHeaderCell {
        list.layoutIfNeeded()
        let path = IndexPath(item: 0, section: FileListType.synced.rawValue)
        return try XCTUnwrap(list.supplementaryView(forElementKind: Self.header, at: path) as? FileCollectionViewHeaderCell)
    }

    /// Scrolls past the row's slot in code, then drags 60pt further down, which hides the row, and lifts the finger.
    private func hideTheRowWithAFinger(_ list: StickyHeaderTestList, file: StaticString = #filePath, line: UInt = #line) throws {
        list.scroll(to: 600)
        list.isDragging = true
        list.scroll(to: 630)
        list.scroll(to: 660)
        list.isDragging = false
        XCTAssertTrue(try stickyLayout(of: list).hidesStickyHeader, "precondition: a finger scroll down hides the row", file: file, line: line)
    }

    func testTheListSetUp_InstallsThePinningLayout() throws {
        let vc = makeController()
        XCTAssertFalse(vc.collectionView.collectionViewLayout is StickyHeaderFlowLayout, "precondition: a plain layout")

        vc.setupCollectionView()

        let layout = try stickyLayout(of: vc.collectionView)
        XCTAssertEqual(layout.minimumInteritemSpacing, 6)
        XCTAssertEqual(layout.minimumLineSpacing, 0)
    }

    func testTheGridListToggle_KeepsThePinningLayout() throws {
        let vc = makeController()

        vc.switchViewButtonPressed(self)

        let layout = try stickyLayout(of: vc.collectionView)
        XCTAssertEqual(layout.minimumInteritemSpacing, 6)
        XCTAssertEqual(layout.minimumLineSpacing, 0)
    }

    func testTheGridListToggle_ShowsAHiddenRow_AndItsTravelStartsAfresh() throws {
        let (vc, list, _) = makeHostedController()
        try hideTheRowWithAFinger(list)

        vc.switchViewButtonPressed(self)
        list.layoutIfNeeded()
        let grid = try stickyLayout(of: list)
        XCTAssertFalse(grid.hidesStickyHeader)

        // Back past the slot in code, which keeps the row's state, then a drag short of the 24pt a hide needs.
        list.scroll(to: 600)
        list.isDragging = true
        list.scroll(to: 620)
        XCTAssertFalse(grid.hidesStickyHeader, "the hide before the toggle is forgotten")
    }

    func testInAFolder_TheSyncedHeaderOpensTheSortMenu() throws {
        let (vc, list, _) = makeHostedController()
        let synced = try syncedHeaderView(in: list)

        XCTAssertTrue(synced.sortMenu === vc.sortMenu)
        XCTAssertNil(synced.leftButtonAction)
        XCTAssertEqual(synced.leftButton.accessibilityIdentifier, "folderSortButton")
        XCTAssertEqual(synced.gutterWidth, list.contentInset.left)
        XCTAssertEqual(synced.rightButtonTitle, "Select")
        XCTAssertEqual(synced.rightButton.configuration?.image, FileCollectionViewHeaderCell.selectIcon, "the circled check beside Select")
    }

    func testInAViewOnlyFolder_TheSyncedHeaderOffersNoSelect_AndTheSortButtonRunsToTheEdge() throws {
        let (vc, list, _) = makeHostedController()
        vc.fabView.isHidden = true
        list.reloadData()
        let synced = try syncedHeaderView(in: list)
        synced.layoutIfNeeded()

        XCTAssertTrue(vc.fabView.isHidden, "precondition: a view-only folder shows no FAB")
        XCTAssertNil(synced.rightButtonTitle)
        XCTAssertEqual(synced.rightButton.bounds.width, 0, accuracy: 0.01, "nothing to tap into select mode")
        XCTAssertFalse(synced.rightButton.isAccessibilityElement)
        XCTAssertEqual(synced.leftButton.frame.maxX, synced.bounds.width - 12, accuracy: 0.01)
    }

    func testSelectMode_NamesSelectAllWithoutPaddingSpaces() throws {
        let (vc, list, _) = makeHostedController()

        vc.viewModel?.isSelecting = true
        list.reloadData()

        XCTAssertEqual(try syncedHeaderView(in: list).rightButtonTitle, "Select all")
    }

    func testEnteringAFolderFromTheShareList_ItsHeaderOpensNoMenuYet() throws {
        let (vc, list, _) = makeHostedController(inFolder: false)

        vc.collectionView(list, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))
        let synced = try syncedHeaderView(in: list)

        XCTAssertEqual(vc.viewModel?.navigationStack.count, 0, "precondition: still at the share list while the folder loads")
        XCTAssertEqual(synced.leftButtonTitle, vc.viewModel?.activeSortOption.title, "the row names the sort over the skeleton")
        XCTAssertNil(synced.sortMenu)
        XCTAssertEqual(synced.leftButton.accessibilityIdentifier, "headerSortButton")
        XCTAssertEqual(synced.gutterWidth, list.contentInset.left, "the layout still spans it across the side insets")
    }

    func testTheShareList_HasNoRowToPin() throws {
        let (vc, list, _) = makeHostedController(inFolder: false)
        let layout = try stickyLayout(of: list)

        XCTAssertEqual(vc.collectionView(list, layout: layout, referenceSizeForHeaderInSection: FileListType.synced.rawValue).height, 0)
        XCTAssertNil(layout.stickyHeaderSlot)
        list.isDragging = true
        for offset: CGFloat in [300, 330, 600] { list.scroll(to: offset) }
        XCTAssertFalse(layout.hidesStickyHeader)
    }

    func testInAList_AFingerScrollHidesTheRow_ButTheSameOffsetsInCodeDoNot() throws {
        let (_, list, _) = makeHostedController()
        let layout = try stickyLayout(of: list)

        for offset: CGFloat in [300, 330, 600, 660] { list.scroll(to: offset) }
        XCTAssertFalse(layout.hidesStickyHeader, "offsets set in code, as by a reload or the back swipe, keep the row")

        list.isDragging = true
        list.scroll(to: 690)
        XCTAssertTrue(layout.hidesStickyHeader, "30pt of finger travel down past the slot")

        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.4))
        let hidden = try syncedHeaderView(in: list)
        XCTAssertTrue(list.visibleSupplementaryViews(ofKind: Self.header).contains(hidden), "the hidden row keeps its view")
        XCTAssertEqual(hidden.alpha, 0)

        list.scroll(to: 678)
        XCTAssertFalse(layout.hidesStickyHeader, "12pt back up")
    }

    func testEnteringAFolder_ShowsAHiddenRow() throws {
        let (vc, list, _) = makeHostedController()
        let layout = try stickyLayout(of: list)
        list.scroll(to: 600)
        list.isDragging = true
        list.scroll(to: 660)
        list.isDragging = false
        XCTAssertTrue(layout.hidesStickyHeader, "precondition: a finger scroll down hides the row")

        vc.navigateToFolder(withParams: ("0000", 123, nil), backNavigation: false)

        XCTAssertFalse(layout.hidesStickyHeader)
    }

    func testAStatusBarTap_ShowsAHiddenRow() throws {
        let (vc, list, _) = makeHostedController()
        try hideTheRowWithAFinger(list)

        vc.scrollViewDidScrollToTop(list)

        XCTAssertFalse(try stickyLayout(of: list).hidesStickyHeader)
    }

    func testAStatusBarTap_ShowsAHiddenRowAsTheScrollStarts() throws {
        let (vc, list, _) = makeHostedController()
        try hideTheRowWithAFinger(list)

        XCTAssertTrue(vc.scrollViewShouldScrollToTop(list), "the list still scrolls to the top")

        XCTAssertFalse(try stickyLayout(of: list).hidesStickyHeader)
        XCTAssertEqual(list.contentOffset.y, 660, "before the scroll moves the list")
    }

    func testAnArchiveSwitchOffScreen_ShowsAHiddenRow() throws {
        let (vc, list, _) = makeHostedController()
        try hideTheRowWithAFinger(list)
        // Off screen the switch fetches nothing, so this reset is the only one until the screen returns.
        vc.view.removeFromSuperview()

        vc.archiveDidChange()

        XCTAssertFalse(try stickyLayout(of: list).hidesStickyHeader)
    }

    func testApplySort_SavesAndRefreshesTheFolder_ThenListsItFromTheTop() throws {
        let (vc, list, _) = makeHostedController()
        var refreshed: NavigateMinParams?
        vc.navigateMinRequest = { params, _, completion in
            refreshed = params
            completion(.success)
        }
        list.scroll(to: 600)

        vc.applySort(.dateDescending)
        // The screen redraws the refreshed rows on the next main-queue turn, and the scroll follows it.
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))

        XCTAssertEqual(vc.viewModel?.activeSortOption, .dateDescending)
        XCTAssertEqual(refreshed?.folderLinkId, 40, "the folder on screen is listed again")
        XCTAssertEqual(list.contentOffset.y, -list.adjustedContentInset.top, "the new order starts at the top")
    }

    func testApplySort_WhenTheFolderComesBackShorter_RedrawsBeforeScrollingToTheTop() throws {
        let (vc, list, _) = makeHostedController()
        let viewModel = try XCTUnwrap(vc.viewModel)
        vc.navigateMinRequest = { _, _, completion in
            viewModel.viewModels = Array(viewModel.viewModels.prefix(3))
            completion(.success)
        }
        list.scroll(to: 600)

        vc.applySort(.dateDescending)
        // The layout pass the run loop makes before the redraw; at the top it would ask for rows now gone.
        list.layoutIfNeeded()
        RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.05))
        list.layoutIfNeeded()

        let synced = FileListType.synced.rawValue
        XCTAssertEqual(list.numberOfItems(inSection: synced), 3)
        XCTAssertEqual(list.contentOffset.y, -list.adjustedContentInset.top)
        XCTAssertEqual(list.indexPathsForVisibleItems.filter { $0.section == synced }.count, 3)
    }

    func testTheScreen_IsFreedAfterBuildingItsSortMenuAndRowReveal() {
        let list = UICollectionView(frame: .zero, collectionViewLayout: StickyHeaderFlowLayout.fileList())
        weak var released: SharesViewController?
        autoreleasepool {
            let vc = SharesViewController()
            vc.viewModel = MockSharedFilesViewModel()
            vc.collectionView = list
            _ = vc.sortMenu
            _ = vc.stickyHeaderReveal
            released = vc
        }

        XCTAssertNil(released, "the menu and the reveal hold the screen weakly")
    }

    // MARK: - First-open double fetch

    func testShouldFetchShares_NothingLoaded_NothingInFlight_Fetches() {
        XCTAssertTrue(SharesViewController.shouldFetchShares(loadedArchiveId: nil, sessionArchiveId: 42, inFlightArchiveId: nil))
    }

    func testShouldFetchShares_SameArchiveAlreadyInFlight_DoesNotFetchAgain() {
        XCTAssertFalse(SharesViewController.shouldFetchShares(loadedArchiveId: nil, sessionArchiveId: 42, inFlightArchiveId: 42))
    }

    func testShouldFetchShares_OtherArchiveInFlight_FetchesTheSelectedOne() {
        XCTAssertTrue(SharesViewController.shouldFetchShares(loadedArchiveId: 7, sessionArchiveId: 42, inFlightArchiveId: 7))
    }

    func testShouldFetchShares_SelectedArchiveAlreadyLoaded_DoesNotFetch() {
        XCTAssertFalse(SharesViewController.shouldFetchShares(loadedArchiveId: 42, sessionArchiveId: 42, inFlightArchiveId: nil))
    }

    func testShouldFetchShares_ArchiveSwitchedAfterLoad_Fetches() {
        XCTAssertTrue(SharesViewController.shouldFetchShares(loadedArchiveId: 7, sessionArchiveId: 42, inFlightArchiveId: nil))
    }

    private func makeController(list: UICollectionView? = nil) -> SharesViewController {
        let vc = SharesViewController()
        vc.viewModel = MockSharedFilesViewModel()

        // Keep weak outlets alive by attaching them to a retained root view.
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 390, height: 844))
        let directoryLabel = UILabel()
        let backButton = UIButton(type: .system)
        let segmentedControl = SlidingTabControl()
        let collectionView = list ?? makeCollectionView()
        let switchViewButton = UIButton(type: .system)
        let fileActionBottomView = BottomActionSheet(frame: .zero)
        let fabView = FABView(frame: .zero)

        [directoryLabel, backButton, segmentedControl, collectionView, switchViewButton, fileActionBottomView, fabView].forEach {
            rootView.addSubview($0)
        }

        vc.view = rootView
        vc.directoryLabel = directoryLabel
        vc.backButton = backButton
        vc.segmentedControl = segmentedControl
        vc.collectionView = collectionView
        vc.switchViewButton = switchViewButton
        vc.fileActionBottomView = fileActionBottomView
        vc.fabView = fabView

        let bottomConstraint = rootView.heightAnchor.constraint(equalToConstant: rootView.bounds.height)
        bottomConstraint.isActive = true
        vc.bottomButtonHeightConstraint = bottomConstraint
        return vc
    }

    private func makeCollectionView() -> UICollectionView {
        UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
    }

    private func makeFolder(name: String, folderLinkId: Int) -> FileModel {
        FileModel(
            name: name,
            recordId: 0,
            folderLinkId: folderLinkId,
            archiveNbr: "0000",
            type: FileType.privateFolder.rawValue,
            permissions: [.read]
        )
    }

    private func makeFile(name: String, folderLinkId: Int) -> FileModel {
        FileModel(
            name: name,
            recordId: 1,
            folderLinkId: folderLinkId,
            archiveNbr: "0000",
            type: FileType.miscellaneous.rawValue,
            permissions: [.read]
        )
    }
}

private final class TestableSharesViewController: SharesViewController {
    var didNavigateToFolder = false
    var lastNavigateParams: NavigateMinParams?
    var didPresentViewController = false
    var lastPresentedViewController: UIViewController?

    override func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, shouldDisplaySpinner: Bool = true, isRefresh: Bool = false, silenceErrors: Bool = false, then handler: VoidAction? = nil) {
        didNavigateToFolder = true
        lastNavigateParams = params
        handler?()
    }

    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didPresentViewController = true
        lastPresentedViewController = viewControllerToPresent
        completion?()
    }
}

private final class AlertTrackingSharesViewController: SharesViewController {
    var didShowAlert = false
    var lastAlertTitle: String?
    var lastAlertMessage: String?

    override func showAlert(title: String?, message: String?) {
        didShowAlert = true
        lastAlertTitle = title
        lastAlertMessage = message
    }
}

private final class MockSharedFilesViewModel: SharedFilesViewModel {
    private var _selectedFiles: [FileModel]? = []
    private var _fileAction: FileAction = .none
    var didInvalidateTimer = false

    override var selectedFiles: [FileModel]? {
        get { _selectedFiles }
        set { _selectedFiles = newValue }
    }

    override var fileAction: FileAction {
        get { _fileAction }
        set { _fileAction = newValue }
    }

    override func invalidateTimer() {
        didInvalidateTimer = true
        super.invalidateTimer()
    }
}
