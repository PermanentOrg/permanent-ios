//
//  MainViewControllerTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 13.03.2026.
//

import XCTest
@testable import Permanent

@MainActor
final class MainViewControllerTests: XCTestCase {
    override func tearDown() {
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.navigationToShareFolderLink)
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.shareURLToken)
        super.tearDown()
    }


    func testSearchButtonPressedUsesInjectedFactoryAndPresenter() {
        let vc = MainViewController()
        vc.viewModel = MyFilesViewModel()

        let expectedSearchVC = SearchViewController()
        var presentedVC: UIViewController?
        var presentedAnimated: Bool?

        vc.makeSearchViewController = { expectedSearchVC }
        vc.presentSearchController = { viewController, animated in
            presentedVC = viewController
            presentedAnimated = animated
        }

        vc.searchButtonPressed(self)

        let nav = presentedVC as? NavigationController
        XCTAssertNotNil(nav)
        XCTAssertTrue(nav?.viewControllers.first === expectedSearchVC)
        XCTAssertEqual(presentedAnimated, false)
    }
    
    func testSearchButtonPressedWhenFactoryReturnsNilDoesNotPresent() {
        let vc = MainViewController()
        vc.viewModel = MyFilesViewModel()
        
        var didPresent = false
        vc.makeSearchViewController = { nil }
        vc.presentSearchController = { _, _ in
            didPresent = true
        }
        
        vc.searchButtonPressed(self)
        
        XCTAssertFalse(didPresent)
    }

    func testSearchButtonPressedWithoutInjectedPresenterUsesControllerPresent() {
        let vc = TestableMainViewController()
        vc.viewModel = MyFilesViewModel()
        vc.makeSearchViewController = { SearchViewController() }
        vc.presentSearchController = nil

        vc.searchButtonPressed(self)

        XCTAssertTrue(vc.didPresentViewController)
        XCTAssertTrue(vc.lastPresentedViewController is NavigationController)
    }

    func testSwitchViewButtonPressedUpdatesLayoutAndButtonImage() {
        let vc = MainViewController()
        let vm = PermissionAwareMyFilesViewModel()
        vc.viewModel = vm
        
        // Keep strong refs because controller outlets are weak.
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let switchButton = UIButton(type: .system)
        vc.collectionView = collectionView
        vc.switchViewButton = switchButton

        vc.switchViewButtonPressed(self)

        XCTAssertNotNil(switchButton.currentImage)
        XCTAssertTrue(collectionView.collectionViewLayout is UICollectionViewFlowLayout)

        vm.testArchivePermissions = [.create, .upload]
        vm.isPickingImage = false
        vc.fabView = FABView(frame: .zero)
        vc.updateFABViewVisibility()
        XCTAssertFalse(vc.fabView.isHidden)

        vm.testArchivePermissions = [.create]
        vc.updateFABViewVisibility()
        XCTAssertTrue(vc.fabView.isHidden)

        collectionView.setContentOffset(CGPoint(x: 20, y: 80), animated: false)
        vc.resetCollectionViewState()
        XCTAssertEqual(collectionView.contentOffset, .zero)
        XCTAssertTrue(collectionView.alwaysBounceVertical)
        XCTAssertNotNil(collectionView.refreshControl)
    }

    // MARK: - FAB visibility across select mode
    // The + button is gated on archive permissions, but the RESTORE paths used to un-hide
    // it unconditionally. The reported repro: open a viewer-role archive, tap Select, then
    // deselect — the create/upload FAB appeared on an archive the user cannot write to.

    /// Wires just the outlets the select-mode handlers touch. Returns strong refs —
    /// controller outlets are weak.
    private func makeSelectModeHarness(_ vm: MyFilesViewModel)
    -> (vc: MainViewController, retained: [UIView]) {
        let vc = MainViewController()
        vc.viewModel = vm
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let backButton = UIButton(type: .system)
        let fabView = FABView(frame: .zero)
        vc.collectionView = collectionView
        vc.backButton = backButton
        vc.fabView = fabView
        return (vc, [collectionView, backButton, fabView])
    }

    func testDeselect_ViewerArchive_DoesNotRevealFAB() {
        let vm = PermissionAwareMyFilesViewModel()
        vm.testArchivePermissions = [.read]           // viewer role — no create/upload
        let (vc, retained) = makeSelectModeHarness(vm)
        defer { _ = retained }

        vc.updateFABViewVisibility()
        XCTAssertTrue(vc.fabView.isHidden, "precondition: a viewer archive never shows the FAB")

        vc.selectButtonWasPressed(UIButton())
        XCTAssertTrue(vc.fabView.isHidden, "select mode keeps it hidden")

        vc.clearButtonWasPressed(UIButton())          // the reported repro: deselect
        XCTAssertTrue(vc.fabView.isHidden,
                      "leaving select mode must not conjure + on an archive without write access")
    }

    func testDeselect_WritableArchive_RestoresFAB() {
        // The gate must not over-tighten: with create+upload the FAB comes back on deselect.
        let vm = PermissionAwareMyFilesViewModel()
        vm.testArchivePermissions = [.read, .create, .upload]
        let (vc, retained) = makeSelectModeHarness(vm)
        defer { _ = retained }

        vc.updateFABViewVisibility()
        XCTAssertFalse(vc.fabView.isHidden, "precondition: writable archive shows the FAB")

        vc.selectButtonWasPressed(UIButton())
        XCTAssertTrue(vc.fabView.isHidden, "select mode owns the screen while active")

        vc.clearButtonWasPressed(UIButton())
        XCTAssertFalse(vc.fabView.isHidden, "deselect restores the FAB when permissions allow")
    }

    func testUpdateFABViewVisibility_HiddenWhileSelecting() {
        // The gate itself must treat select mode as hidden, so any stray refresh that
        // recomputes visibility mid-selection cannot re-show the FAB either.
        let vm = PermissionAwareMyFilesViewModel()
        vm.testArchivePermissions = [.read, .create, .upload]
        let (vc, retained) = makeSelectModeHarness(vm)
        defer { _ = retained }

        vm.isSelecting = true
        vc.updateFABViewVisibility()
        XCTAssertTrue(vc.fabView.isHidden)
    }

    func testCancelButtonPressedDismissesController() {
        let vc = TestableMainViewController()

        vc.cancelButtonPressed(self)

        XCTAssertTrue(vc.didDismiss)
        XCTAssertEqual(vc.dismissAnimatedValue, true)
    }

    func testBackButtonActionWithoutFolderHierarchyDoesNotNavigate() {
        let vc = TestableMainViewController()
        vc.viewModel = MyFilesViewModel()
        let backButton = UIButton(type: .system)
        let directoryLabel = UILabel()
        vc.backButton = backButton
        vc.directoryLabel = directoryLabel

        vc.backButtonAction(backButton)

        XCTAssertFalse(vc.didNavigateToFolder)
    }

    func testBackButtonActionNavigatesToParentAndHidesBackButtonAtRoot() {
        let vc = TestableMainViewController()
        let vm = MyFilesViewModel()
        vc.viewModel = vm

        let root = makeFolder(name: "My Files", folderLinkId: 100)
        let child = makeFolder(name: "Child", folderLinkId: 200)
        vm.navigationStack = [root, child]

        let backButton = UIButton(type: .system)
        let directoryLabel = UILabel()
        vc.backButton = backButton
        vc.directoryLabel = directoryLabel
        backButton.isHidden = false

        vc.backButtonAction(backButton)

        XCTAssertTrue(vc.didNavigateToFolder)
        XCTAssertEqual(vc.lastNavigateParams?.folderLinkId, root.folderLinkId)
        XCTAssertTrue(backButton.isHidden)
        XCTAssertEqual(directoryLabel.text, vm.rootFolderName)
    }
    
    func testNumberOfSectionsUsesViewModelValue() {
        let vc = MainViewController()
        vc.viewModel = MyFilesViewModel()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        XCTAssertEqual(vc.numberOfSections(in: collectionView), 3)
    }
    
    func testNumberOfItemsInSyncedSectionUsesViewModelRows() {
        let vc = MainViewController()
        let vm = MyFilesViewModel()
        vc.viewModel = vm
        
        vm.viewModels = [
            makeFolder(name: "A", folderLinkId: 1),
            makeFolder(name: "B", folderLinkId: 2)
        ]
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        XCTAssertEqual(vc.collectionView(collectionView, numberOfItemsInSection: FileListType.synced.rawValue), 2)
    }
    
    func testHandleTableBackgroundViewShowsEmptyFolderViewWhenNoData() {
        let vc = MainViewController()
        let vm = MyFilesViewModel()
        vc.viewModel = vm
        
        vm.viewModels = []
        vm.uploadQueue = []
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        vc.handleTableBackgroundView()
        
        XCTAssertNotNil(collectionView.backgroundView)
    }
    
    func testHandleTableBackgroundViewClearsBackgroundWhenDataExists() {
        let vc = MainViewController()
        let vm = MyFilesViewModel()
        vc.viewModel = vm
        
        vm.viewModels = [makeFolder(name: "A", folderLinkId: 1)]
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        vc.handleTableBackgroundView()
        
        XCTAssertNil(collectionView.backgroundView)
    }
    
    func testSelectButtonSelectorWhenNotSelectingEnablesSelectingAndUpdatesUI() {
        let vc = MainViewController()
        let vm = MyFilesViewModel()
        vc.viewModel = vm
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        vc.fabView = FABView(frame: .zero)
        vc.backButton = UIButton(type: .system)
        vc.backButton.isHidden = false
        
        vm.isSelecting = false
        
        _ = vc.perform(NSSelectorFromString("selectButtonWasPressed:"), with: UIButton(type: .system))
        
        XCTAssertTrue(vm.isSelecting)
        XCTAssertTrue(vc.fabView.isHidden)
        XCTAssertFalse(vc.backButton.isUserInteractionEnabled)
        XCTAssertEqual(vc.backButton.layer.opacity, 0.3)
    }
    
    func testClearButtonSelectorDisablesSelectingAndRestoresUI() {
        let vc = MainViewController()
        // Permission-aware mock WITH write access: the FAB restore below is only correct
        // for a writable archive. (A bare MyFilesViewModel has no session, so its
        // permissions are [.read] — this test used to assert the FAB reappearing in that
        // state, which was precisely the permission leak fixed by routing the restore
        // through updateFABViewVisibility. The viewer case is covered by
        // testDeselect_ViewerArchive_DoesNotRevealFAB.)
        let vm = PermissionAwareMyFilesViewModel()
        vm.testArchivePermissions = [.read, .create, .upload]
        vc.viewModel = vm
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        vc.fabView = FABView(frame: .zero)
        vc.backButton = UIButton(type: .system)
        vc.backButton.isHidden = false
        
        vm.isSelecting = true
        vc.fabView.isHidden = true
        vc.backButton.isUserInteractionEnabled = false
        vc.backButton.layer.opacity = 0.3
        
        _ = vc.perform(NSSelectorFromString("clearButtonWasPressed:"), with: UIButton(type: .system))
        
        XCTAssertFalse(vm.isSelecting)
        XCTAssertFalse(vc.fabView.isHidden)
        XCTAssertTrue(vc.backButton.isUserInteractionEnabled)
        XCTAssertEqual(vc.backButton.layer.opacity, 1)
    }
    
    func testNavigationToShareFolderLinkNavigatesAndUsesProvidedFolderName() {
        let vc = TestableMainViewController()
        vc.viewModel = MyFilesViewModel()
        vc.backButton = UIButton(type: .system)
        vc.directoryLabel = UILabel()
        
        let payload = NavigationDataForShareFolderLink(archiveNo: "0000", folderLinkId: 321, folderName: "Shared Folder")
        try? PreferencesManager.shared.setCodableObject(payload, forKey: Constants.Keys.StorageKeys.navigationToShareFolderLink)
        
        vc.navigationToShareFolderLink()
        
        XCTAssertTrue(vc.didNavigateToFolder)
        XCTAssertEqual(vc.lastNavigateParams?.archiveNo, "0000")
        XCTAssertEqual(vc.lastNavigateParams?.folderLinkId, 321)
        XCTAssertFalse(vc.backButton.isHidden)
        XCTAssertEqual(vc.directoryLabel.text, "Shared Folder")
    }
    
    func testNavigationToShareFolderLinkFallsBackToCurrentFolderNameWhenMissing() {
        let vc = TestableMainViewController()
        let vm = MyFilesViewModel()
        vm.navigationStack = [makeFolder(name: "Current Folder", folderLinkId: 111)]
        vc.viewModel = vm
        vc.backButton = UIButton(type: .system)
        vc.directoryLabel = UILabel()
        
        let payload = NavigationDataForShareFolderLink(archiveNo: "0000", folderLinkId: 654, folderName: nil)
        try? PreferencesManager.shared.setCodableObject(payload, forKey: Constants.Keys.StorageKeys.navigationToShareFolderLink)
        
        vc.navigationToShareFolderLink()
        
        XCTAssertTrue(vc.didNavigateToFolder)
        XCTAssertEqual(vc.directoryLabel.text, "Current Folder")
    }
    
    func testDidSelectItemAtWhenSelectingTogglesSelectionAndRefreshes() {
        let vc = TestableMainViewController()
        let vm = MyFilesViewModel()
        vc.viewModel = vm
        
        let file = makeFolder(name: "Folder A", folderLinkId: 10)
        vm.viewModels = [file]
        vm.isSelecting = true
        vm.selectedFiles = []
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))
        
        // selectedFiles is session-backed in MyFilesViewModel and can be nil in test env.
        // We assert the controller path was executed by verifying refresh was triggered.
        XCTAssertTrue(vc.didRefreshCollectionView)
    }

    func testDidSelectItemAtWhenSelectingAndAlreadySelectedRemovesFile() {
        let vc = TestableMainViewController()
        let vm = MockMyFilesViewModel()
        vc.viewModel = vm

        let file = makeFolder(name: "Folder A", folderLinkId: 12)
        vm.viewModels = [file]
        vm.isSelecting = true
        vm.selectedFiles = [file]

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView

        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))

        XCTAssertTrue(vm.selectedFiles?.isEmpty ?? false)
        XCTAssertTrue(vc.didRefreshCollectionView)
    }
    
    func testDidSelectItemAtFolderNavigatesAndUpdatesHeaderState() {
        let vc = TestableMainViewController()
        let vm = MyFilesViewModel()
        vc.viewModel = vm
        
        let folder = makeFolder(name: "Folder B", folderLinkId: 20)
        vm.viewModels = [folder]
        vm.isSelecting = false
        vm.selectedFiles = []
        vm.fileAction = .none
        
        vc.backButton = UIButton(type: .system)
        vc.backButton.isHidden = true
        vc.directoryLabel = UILabel()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))
        
        XCTAssertTrue(vc.didNavigateToFolder)
        XCTAssertEqual(vc.lastNavigateParams?.folderLinkId, 20)
        XCTAssertFalse(vc.backButton.isHidden)
        XCTAssertEqual(vc.directoryLabel.text, "Folder B")
    }
    
    func testDidSelectItemAtFileInPickerModeCallsPickerDelegate() {
        let vc = TestableMainViewController()
        let vm = MyFilesViewModel()
        let pickerDelegate = PickerDelegateSpy()
        vm.pickerDelegate = pickerDelegate
        vm.isPickingImage = true
        vc.viewModel = vm
        
        let file = makeFile(name: "Photo", folderLinkId: 30)
        vm.viewModels = [file]
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))
        
        XCTAssertTrue(pickerDelegate.didPickFile)
    }

    func testHandleImagePickerSelectionCallsPickerDelegate() {
        let vc = MainViewController()
        let vm = MyFilesViewModel()
        let pickerDelegate = PickerDelegateSpy()
        vm.pickerDelegate = pickerDelegate
        vc.viewModel = vm

        vc.handleImagePickerSelection(file: makeFile(name: "Picked", folderLinkId: 77))

        XCTAssertTrue(pickerDelegate.didPickFile)
    }
    
    func testDidSelectItemAtFileInPreviewModePresentsPreviewController() {
        let vc = TestableMainViewController()
        let vm = MyFilesViewModel()
        vm.isPickingImage = false
        vc.viewModel = vm
        
        let file = makeFile(name: "Doc", folderLinkId: 40)
        vm.viewModels = [file]
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))
        
        XCTAssertTrue(vc.didPresentViewController)
        XCTAssertTrue(vc.lastPresentedViewController is FilePreviewNavigationController)
    }
    
    func testReferenceSizeForHeaderIsZeroWhenSectionEmpty() {
        let vc = MainViewController()
        vc.viewModel = MyFilesViewModel()
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        let size = vc.collectionView(collectionView, layout: collectionView.collectionViewLayout, referenceSizeForHeaderInSection: FileListType.synced.rawValue)
        
        XCTAssertEqual(size.height, 0)
    }
    
    func testReferenceSizeForHeaderIsFortyWhenSectionHasRows() {
        let vc = MainViewController()
        let vm = MyFilesViewModel()
        vm.viewModels = [makeFolder(name: "Folder C", folderLinkId: 50)]
        vc.viewModel = vm
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        let size = vc.collectionView(collectionView, layout: collectionView.collectionViewLayout, referenceSizeForHeaderInSection: FileListType.synced.rawValue)
        
        XCTAssertEqual(size.height, 40)
    }
    
    func testNumberOfItemsInDownloadingSectionUsesDownloadQueueCount() {
        let vc = MainViewController()
        let vm = MyFilesViewModel()
        vc.viewModel = vm
        vm.downloadQueue = [makeFile(name: "D1", folderLinkId: 90)]
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        XCTAssertEqual(vc.collectionView(collectionView, numberOfItemsInSection: FileListType.downloading.rawValue), 1)
    }
    
    func testSizeForItemAtSyncedListIsListHeight() {
        let vc = MainViewController()
        vc.viewModel = MyFilesViewModel()
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        let size = vc.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))

        XCTAssertEqual(size.height, 74)
    }

    func testSizeForItemAtSyncedGridIsLargerThanListAfterToggle() {
        let vc = MainViewController()
        vc.viewModel = MyFilesViewModel()

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let switchButton = UIButton(type: .system)
        vc.collectionView = collectionView
        vc.switchViewButton = switchButton

        vc.switchViewButtonPressed(self)

        let size = vc.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))

        XCTAssertGreaterThan(size.height, 74)
    }

    func testSizeForItemAtNonSyncedSectionAlwaysUsesListHeight() {
        let vc = MainViewController()
        vc.viewModel = MyFilesViewModel()

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let switchButton = UIButton(type: .system)
        vc.collectionView = collectionView
        vc.switchViewButton = switchButton

        vc.switchViewButtonPressed(self)

        let size = vc.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAt: IndexPath(row: 0, section: FileListType.downloading.rawValue))

        XCTAssertEqual(size.height, 74)
    }
    
    func testDidSelectItemAtUnsyncedFileDoesNothing() {
        let vc = TestableMainViewController()
        let vm = MyFilesViewModel()
        vc.viewModel = vm
        
        var file = makeFile(name: "Failed", folderLinkId: 70)
        file.fileStatus = .failed
        vm.viewModels = [file]
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        
        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))
        
        XCTAssertFalse(vc.didNavigateToFolder)
        XCTAssertFalse(vc.didPresentViewController)
        XCTAssertFalse(vc.didRefreshCollectionView)
    }
    
    func testDidSelectItemAtFolderAlreadySelectedWithActionDoesNotNavigate() {
        let vc = TestableMainViewController()
        let vm = MockMyFilesViewModel()
        vc.viewModel = vm
        
        let folder = makeFolder(name: "Folder D", folderLinkId: 80)
        vm.viewModels = [folder]
        vm.selectedFiles = [folder]
        vm.fileAction = .move
        vm.isSelecting = false
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        vc.backButton = UIButton(type: .system)
        vc.directoryLabel = UILabel()
        
        vc.collectionView(collectionView, didSelectItemAt: IndexPath(row: 0, section: FileListType.synced.rawValue))
        
        XCTAssertFalse(vc.didNavigateToFolder)
    }

    func testTimerActionsSelectorRefreshesCurrentFolderPath() {
        let vc = TestableMainViewController()
        let vm = MyFilesViewModel()
        vm.navigationStack = [makeFolder(name: "Root", folderLinkId: 101)]
        vc.viewModel = vm
        
        _ = vc.perform(NSSelectorFromString("timerActions"))
        
        XCTAssertTrue(vc.didNavigateToFolder)
    }

    func testSelectButtonSelectorWhenSelectingAndNotAllSelectedSelectsAll() {
        let vc = MainViewController()
        let vm = MockMyFilesViewModel()
        vc.viewModel = vm

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        vc.fabView = FABView(frame: .zero)
        vc.backButton = UIButton(type: .system)

        let a = makeFolder(name: "A", folderLinkId: 201)
        let b = makeFolder(name: "B", folderLinkId: 202)
        vm.viewModels = [a, b]
        vm.selectedFiles = [a]
        vm.isSelecting = true

        _ = vc.perform(NSSelectorFromString("selectButtonWasPressed:"), with: UIButton(type: .system))

        XCTAssertEqual(vm.selectedFiles?.count, 2)
    }

    func testSelectButtonSelectorWhenSelectingAndAllSelectedDeselectsAll() {
        let vc = MainViewController()
        let vm = MockMyFilesViewModel()
        vc.viewModel = vm

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        vc.collectionView = collectionView
        vc.fabView = FABView(frame: .zero)
        vc.backButton = UIButton(type: .system)

        let a = makeFolder(name: "A", folderLinkId: 301)
        let b = makeFolder(name: "B", folderLinkId: 302)
        vm.viewModels = [a, b]
        vm.selectedFiles = [a, b]
        vm.isSelecting = true

        _ = vc.perform(NSSelectorFromString("selectButtonWasPressed:"), with: UIButton(type: .system))

        XCTAssertTrue(vm.selectedFiles?.isEmpty ?? false)
    }

    func testNavigationToShareFolderLinkWithoutStoredPayloadDoesNothing() {
        let vc = TestableMainViewController()
        vc.viewModel = MyFilesViewModel()
        vc.backButton = UIButton(type: .system)
        vc.directoryLabel = UILabel()
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.navigationToShareFolderLink)

        vc.navigationToShareFolderLink()

        XCTAssertFalse(vc.didNavigateToFolder)
    }

    func testPullToRefreshSelectorNavigatesToCurrentFolderAndInvalidatesTimer() {
        let vc = TestableMainViewController()
        let vm = TrackingMyFilesViewModel()
        vm.navigationStack = [makeFolder(name: "Root", folderLinkId: 401)]
        vc.viewModel = vm

        _ = vc.perform(NSSelectorFromString("pullToRefreshAction"))

        XCTAssertTrue(vc.didNavigateToFolder)
        XCTAssertTrue(vm.didInvalidateTimer)
    }

    func testNavigateToFolderUsesInjectedNavigateMinRequest() {
        let vc = MainViewController()
        vc.viewModel = MyFilesViewModel()
        let rootView = UIView(frame: .init(x: 0, y: 0, width: 390, height: 844))
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: UICollectionViewFlowLayout())
        let switchViewButton = UIButton(type: .system)
        let bottomView = BottomActionSheet(frame: .zero)
        let directoryLabel = UILabel()
        let backButton = UIButton(type: .system)
        let fabView = FABView(frame: .zero)
        [collectionView, switchViewButton, bottomView, directoryLabel, backButton, fabView].forEach { rootView.addSubview($0) }

        vc.view = rootView
        vc.collectionView = collectionView
        vc.switchViewButton = switchViewButton
        vc.fileActionBottomView = bottomView
        vc.directoryLabel = directoryLabel
        vc.backButton = backButton
        vc.fabView = fabView

        var called = false
        var capturedParams: NavigateMinParams?
        var capturedBack = false
        vc.navigateMinRequest = { params, backNavigation, completion in
            called = true
            capturedParams = params
            capturedBack = backNavigation
            completion(.success)
        }

        vc.navigateToFolder(withParams: ("0000", 123, nil), backNavigation: true, shouldDisplaySpinner: false)

        XCTAssertTrue(called)
        XCTAssertEqual(capturedParams?.archiveNo, "0000")
        XCTAssertEqual(capturedParams?.folderLinkId, 123)
        XCTAssertTrue(capturedBack)

        let errorVC = AlertTrackingMainViewController()
        errorVC.viewModel = MyFilesViewModel()
        errorVC.navigateMinRequest = { _, _, completion in
            completion(.error(message: "Network down"))
        }
        errorVC.navigateToFolder(withParams: ("0000", 99, nil), backNavigation: false, shouldDisplaySpinner: false)
        XCTAssertTrue(errorVC.didShowAlert)
        XCTAssertEqual(errorVC.lastAlertMessage, "Network down")
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
private final class TestableMainViewController: MainViewController {
    var didDismiss = false
    var dismissAnimatedValue: Bool?
    var didNavigateToFolder = false
    var lastNavigateParams: NavigateMinParams?
    var didRefreshCollectionView = false
    var didPresentViewController = false
    var lastPresentedViewController: UIViewController?

    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        didDismiss = true
        dismissAnimatedValue = flag
        completion?()
    }

    override func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, shouldDisplaySpinner: Bool = true, resetScroll: Bool = true, silenceErrors: Bool = false, then handler: VoidAction? = nil) {
        didNavigateToFolder = true
        lastNavigateParams = params
        handler?()
    }
    
    override func refreshCollectionView() {
        didRefreshCollectionView = true
    }
    
    override func present(_ viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)? = nil) {
        didPresentViewController = true
        lastPresentedViewController = viewControllerToPresent
        completion?()
    }
}

private final class PickerDelegateSpy: MyFilesViewModelPickerDelegate {
    var didPickFile = false
    
    func myFilesVMDidPickFile(viewModel: MyFilesViewModel, file: FileModel) {
        didPickFile = true
    }
}

private class MockMyFilesViewModel: MyFilesViewModel {
    private var _selectedFiles: [FileModel]? = []
    private var _fileAction: FileAction = .none

    override var selectedFiles: [FileModel]? {
        get { _selectedFiles }
        set { _selectedFiles = newValue }
    }
    
    override var fileAction: FileAction {
        get { _fileAction }
        set { _fileAction = newValue }
    }
}

private final class TrackingMyFilesViewModel: MockMyFilesViewModel {
    var didInvalidateTimer = false

    override func invalidateTimer() {
        didInvalidateTimer = true
        super.invalidateTimer()
    }
}

private final class AlertTrackingMainViewController: MainViewController {
    var didShowAlert = false
    var lastAlertTitle: String?
    var lastAlertMessage: String?

    override func showAlert(title: String?, message: String?) {
        didShowAlert = true
        lastAlertTitle = title
        lastAlertMessage = message
    }
}

private final class PermissionAwareMyFilesViewModel: MyFilesViewModel {
    var testArchivePermissions: [Permission] = [.read]

    override var archivePermissions: [Permission] {
        testArchivePermissions
    }
}
