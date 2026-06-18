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

        XCTAssertEqual(vc.numberOfSections(in: collectionView), 3)
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

    func testReferenceSizeForHeaderFortyWhenRowsAndTitleExist() {
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
        let segmented = UISegmentedControl(items: ["A", "B"])

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

    private func makeController() -> SharesViewController {
        let vc = SharesViewController()
        vc.viewModel = MockSharedFilesViewModel()

        // Keep weak outlets alive by attaching them to a retained root view.
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 390, height: 844))
        let directoryLabel = UILabel()
        let backButton = UIButton(type: .system)
        let segmentedControl = UISegmentedControl(items: ["A", "B"])
        let collectionView = makeCollectionView()
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

    override func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, shouldDisplaySpinner: Bool = true, silenceErrors: Bool = false, then handler: VoidAction? = nil) {
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
