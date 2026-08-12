//
//  MainViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import MobileCoreServices
import Photos
import UIKit
import WebKit
import SwiftUI

class MainViewController: BaseViewController<MyFilesViewModel> {
    @IBOutlet var directoryLabel: UILabel!
    @IBOutlet var backButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var fabView: FABView!
    @IBOutlet var fileActionBottomView: BottomActionSheet!
    @IBOutlet weak var switchViewButton: UIButton!
    @IBOutlet weak var bottomButtonsConstrainHeight: NSLayoutConstraint!
    
    private var isGridView = false
    
    private let overlayView = UIView()
    private let refreshControl = UIRefreshControl()
    private let screenLockManager = ScreenLockManager()

    private var sortActionSheet: SortActionSheet?
    private lazy var mediaRecorder = MediaRecorder(presentationController: self, delegate: self)
    
    let fileHelper = FileHelper()
    let documentInteractionController = UIDocumentInteractionController()
    var navParams: NavigateMinParams? = nil
    var makeSearchViewController: (() -> SearchViewController?) = {
        UIViewController.create(withIdentifier: .search, from: .main) as? SearchViewController
    }
    var presentSearchController: ((UIViewController, Bool) -> Void)?
    var getRootRequest: ((@escaping ServerResponse) -> Void)?
    var navigateMinRequest: ((NavigateMinParams, Bool, @escaping ServerResponse) -> Void)?
    var displayController: ((UIViewController) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        initUI()
        setupCollectionView()
        setupBottomActionSheet()

        fabView.delegate = self

        getRootFolder()

        // Cold launch: the notification can fire before this observer exists, so the persisted nav data
        // is what says a deep link is queued. Spinner now, for feedback during the settle and fetch.
        if let _: NavigationDataForShareFolderLink = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.navigationToShareFolderLink) {
            showSpinner()
        }
        
        NotificationCenter.default.addObserver(forName: UploadManager.didRefreshQueueNotification, object: nil, queue: nil) { [weak self] notif in
            if (self?.viewModel?.refreshUploadQueue() ?? false) && (self?.viewModel?.queueItemsForCurrentFolder.count ?? 0 > 0) {
                self?.refreshCollectionView()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UploadManager.quotaExceededNotification, object: nil, queue: nil) { [weak self] notif in
            let alertVC = UIAlertController(title: "Quota Exceeded".localized(), message: "Do you want to add more storage?".localized(), preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: "Add Storage", style: .default, handler: { action in
                let newRootVC = UIViewController.create(withIdentifier: .donate, from: .donate)
                AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            })
            )
            self?.present(alertVC, animated: true, completion: nil)
        }
        
        NotificationCenter.default.addObserver(forName: UploadManager.didCreateMobileUploadsFolderNotification, object: nil, queue: nil) { [weak self] notif in
            guard let folder = notif.userInfo?["folder"] as? MinFolderVO else { return }
            
            if self?.viewModel?.currentFolder?.folderId == folder.parentFolderID {
                self?.refreshCurrentFolder()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UploadOperation.uploadFinishedNotification, object: nil, queue: nil) { [weak self] notif in
            guard let operation = notif.object as? UploadOperation else { return }
            // if the upload is in this screen's list, refresh the list of models
            if self?.viewModel?.currentFolder?.folderLinkId == operation.file.folder.folderLinkId {
                if (notif.userInfo?["error"] == nil), let uploadedFile = operation.uploadedFile {
                    self?.viewModel?.uploadQueue.removeAll(where: { $0 == operation.file })
                    let newModel = FileModel(model: uploadedFile, archiveThumbnailURL: "", permissions: [], accessRole: self?.viewModel?.archiveAccessRole ?? .viewer)
                    let alreadyExists = self?.viewModel?.viewModels.contains(where: {
                        $0.folderLinkId == newModel.folderLinkId && $0.name == newModel.name
                    }) ?? false
                    if !alreadyExists {
                        self?.viewModel?.viewModels.insert(newModel, at: 0)
                    }
                    self?.refreshCollectionView()
                    
                    if let queueUploadCount = self?.viewModel?.queueItemsForCurrentFolder.count,
                        queueUploadCount == 0 {
                        // Kick the thumbnail poll chain: refetch until the upload's server-side thumbnails land.
                        // The chain stops on its own once the items settle.
                        self?.viewModel?.timerRunCount = 0
                        self?.scheduleNextThumbnailPoll()
                    }
                } else {
                    self?.viewModel?.refreshUploadQueue()
                    self?.refreshCollectionView()
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UploadOperation.uploadProgressNotification, object: nil, queue: nil) { [weak self] notif in
            guard let operation = notif.object as? UploadOperation else { return }
            if self?.viewModel?.currentFolder?.folderLinkId == operation.file.folder.folderLinkId {
                if self?.viewModel?.timer != nil {
                    self?.viewModel?.timer?.invalidate()
                    self?.viewModel?.timerRunCount = 0
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: ShareLinkViewModel.didUpdateSharesNotifName, object: nil, queue: nil) { [weak self] notif in
            guard let shareLinkVM = notif.object as? ShareLinkViewModel,
                  let index = self?.viewModel?.viewModels.firstIndex(where: {
                      $0.recordId == shareLinkVM.fileViewModel.recordId &&
                      $0.folderLinkId == shareLinkVM.fileViewModel.folderLinkId
                  })
            else {
                return
            }
            
            self?.viewModel?.viewModels[index].accessRole = shareLinkVM.fileViewModel.accessRole
            self?.viewModel?.viewModels[index].minArchiveVOS = shareLinkVM.fileViewModel.minArchiveVOS
            
            self?.collectionView.reloadData()
        }

        NotificationCenter.default.addObserver(forName: ShareItemViewModel.didUpdateSharesNotifName, object: nil, queue: nil) { [weak self] notif in
            guard let updatedFileModel = notif.userInfo?["fileModel"] as? FileModel,
                  let index = self?.viewModel?.viewModels.firstIndex(where: {
                      $0.recordId == updatedFileModel.recordId &&
                      $0.folderLinkId == updatedFileModel.folderLinkId
                  }) else {
                return
            }

            self?.viewModel?.viewModels[index].accessRole = updatedFileModel.accessRole
            self?.viewModel?.viewModels[index].minArchiveVOS = updatedFileModel.minArchiveVOS
            self?.collectionView.reloadData()
        }
        
        NotificationCenter.default.addObserver(forName: MyFilesViewModel.didSelectFilesNotifName, object: nil, queue: nil) { [weak self] notif in
            guard let showFloatingIsland = notif.userInfo?["showFloatingIsland"] as? Bool else { return }
            if showFloatingIsland {
                self?.setupBottomActionSheetForMultipleFiles()
            } else {
                self?.dismissFloatingActionIsland()
            }
        }
        
        NotificationCenter.default.addObserver(forName: ArchivesViewModel.didChangeArchiveNotification, object: nil, queue: nil) { [weak self] _ in
            guard let _ = self?.viewModel?.removeCurrentFolderFromHierarchy() else { return }
            
            // Reset collection view scroll position and refresh control state
            self?.resetCollectionViewState()
            
            // Update FAB view visibility based on new archive permissions
            self?.updateFABViewVisibility()
            
            // Refresh member checklist button as permissions might have changed
            self?.showMemberChecklistButton()
            
            // Update navigation title with new archive name
            self?.navigationItem.title = self?.viewModel?.rootFolderName
            
            // Refresh workspace to new archive's root
            self?.getRootFolder()
            self?.backButton.isHidden = true
            self?.directoryLabel.text = self?.viewModel?.rootFolderName
            
            // Additional delayed reset to ensure refresh control works after data loading
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self?.resetCollectionViewState()
            }
        }

        NotificationCenter.default.addObserver(forName: AppDelegate.navigateToFolderNotifName, object: nil, queue: nil) { [weak self] _ in
            self?.navigationToShareFolderLink()
        }

        // Spinner for the gap between a Live Activity tap and the folder opening, posted the instant a
        // deep link is queued so the settle delay and fetch don't look like a freeze.
        NotificationCenter.default.addObserver(forName: AppDelegate.willNavigateToFolderNotifName, object: nil, queue: .main) { [weak self] _ in
            self?.showSpinner()
        }
        
        NotificationCenter.default.addObserver(forName: SettingsRouter.showMemberChecklistNotifName, object: nil, queue: nil) { [weak self] _ in
            self?.didTapChecklist()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            // Skip refresh while uploads are in progress to avoid resetting upload progress UI
            guard UploadManager.shared.uploadQueue.operationCount == 0 else { return }
            
            // Skip the refresh while a Live Activity is visible: a tap on it delivers a deep link that
            // navigates itself, and refreshing here would race with and overwrite that.
            if UploadLiveActivityManager.shared.hasVisibleActivity {
                return
            }
            
            self?.refreshCurrentFolder(shouldDisplaySpinner: false, silenceErrors: true)
        }

        showBanner()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }

    // MARK: - UI Related

    fileprivate func initUI() {
        view.backgroundColor = .white
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.title = viewModel?.rootFolderName
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .white

        if let rightBarItem = navigationItem.rightBarButtonItem, viewModel!.isPickingImage == false {
            var searchButton = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .plain, target: self, action: #selector(searchButtonPressed(_:)))
            if #available(iOS 26.0, *) {
                searchButton = UIBarButtonItem(image: UIImage(systemName: "magnifyingglass"), style: .prominent, target: self, action: #selector(searchButtonPressed(_:)))
                searchButton.tintColor = .darkBlue
            }
            searchButton.accessibilityIdentifier = "searchButton"
            navigationItem.rightBarButtonItems = [rightBarItem, searchButton]
        }
        
        if viewModel!.isPickingImage {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
            navigationItem.leftBarButtonItem = cancelButton
        }
        
        styleNavBar()
        
        directoryLabel.font = TextFontStyle.style3.font
        directoryLabel.textColor = .primary
        directoryLabel.text = viewModel?.rootFolderName
        backButton.tintColor = .primary
        backButton.isHidden = true
        
        fileActionBottomView.isHidden = true
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
        showMemberChecklistButton()

        updateFABViewVisibility()
        
        viewModel?.trackOpenFiles()
    }
    
    fileprivate func setupCollectionView() {
        isGridView = viewModel?.isGridView ?? false
        switchViewButton.accessibilityIdentifier = "switchViewButton"
        switchViewButton.setImage(UIImage(systemName: isGridView ? "list.bullet" : "square.grid.2x2.fill"), for: .normal)
        
        collectionView.register(UINib(nibName: "FileCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "FileCell")
        collectionView.register(UINib(nibName: "FileCollectionViewGridCell", bundle: nil), forCellWithReuseIdentifier: "FileGridCell")
        collectionView.register(FileCollectionViewHeaderCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FileCollectionViewHeaderCell.identifier)
        collectionView.refreshControl = refreshControl
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: UIScreen.main.bounds.width - 40, right: 6)
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 6
        flowLayout.minimumLineSpacing = 0
        flowLayout.estimatedItemSize = .zero
        collectionView.collectionViewLayout = flowLayout
        
        refreshControl.tintColor = .primary
        refreshControl.addTarget(self, action: #selector(pullToRefreshAction), for: .valueChanged)
    }
    
    func refreshCollectionView() {
        handleTableBackgroundView()
        collectionView.reloadData()
        #if DEBUG
        // Surface which navigation path served the current listing so UI parity tests can
        // confirm a "V2" run actually used Stela (not the silent V1 failsafe). DEBUG-only.
        collectionView.accessibilityIdentifier = "files-nav-source-\(FilesViewModel.lastNavigationSource)"
        #endif
    }
    
    func handleTableBackgroundView() {
        guard viewModel?.shouldDisplayBackgroundView == false else {
            let emptyView = EmptyFolderView(title: .emptyFolderMessage, image: .emptyFolder)
            emptyView.frame = collectionView.bounds
            collectionView.backgroundView = emptyView
            
            return
        }

        collectionView.backgroundView = nil
    }
    
    fileprivate func setupBottomActionSheet() {
        guard let selectedFiles = viewModel?.selectedFiles,
              let action = viewModel?.fileAction,
              !selectedFiles.isEmpty else {
            viewModel?.selectedFiles = []
            return
        }

        fabView.setVisibility(hidden: true)

        guard floatingActionIsland == nil else { return }

        let fileIconItem: FloatingActionImageItem
        if selectedFiles.count == 1, let source = selectedFiles.first {
            if let url = URL(string: source.thumbnailURL), !source.type.isFolder {
                fileIconItem = FloatingActionImageItem(url: url, contentMode: .scaleAspectFill, action: nil)
            } else {
                fileIconItem = FloatingActionImageItem(image: UIImage(named: "folderIconFigma")!, action: nil)
            }
        } else {
            fileIconItem = FloatingActionImageItem(image: UIImage(named: "Copy")!, action: nil)
        }

        let actionTitle = action == .copy ? "COPYING".localized() : "MOVING".localized()
        let subtitle = selectedFiles.count == 1 ? selectedFiles.first!.name : "\(selectedFiles.count) files"
        let leftItems = [
            fileIconItem,
            FloatingActionTextSubtitleItem(text: actionTitle, subtitle: subtitle, action: nil),
        ]

        let closeImage = UIImage(named: "xMarkToolbarIcon")!
        let pasteTitle = action == .copy ? "Paste Here".localized() : "Move Here".localized()
        var rightItems: [FloatingActionItem] = [
            FloatingActionImageTextItem(text: pasteTitle, image: UIImage(named: "pasteToolbarIcon")!) { [weak self] _, _ in
                guard let destination = self?.viewModel?.currentFolder else {
                    self?.showErrorAlert(message: .errorMessage)
                    return
                }
                
                if self?.viewModel is PublicFilesViewModel {
                    let title = ""
                    let description = "You are about to \(action == .copy ? "copy" : "move") files to a public folder. This will make them accessible to others. Are you sure you want to proceed?".localized()
                    let confirmButtonText = action == .copy ? "Copy Here".localized() : "Move Here".localized()

                    self?.showActionDialog(
                        styled: .simpleWithDescription,
                        withTitle: title,
                        description: description,
                        positiveButtonTitle: confirmButtonText,
                        positiveAction: { [weak self] in
                            self?.view.dismissPopup(
                                self?.actionDialog,
                                overlayView: self?.overlayView,
                                completion: { _ in
                                    self?.actionDialog?.removeFromSuperview()
                                    self?.actionDialog = nil
                                    
                                    self?.relocate(files: selectedFiles, to: destination)
                                }
                            )
                        },
                        cancelButtonTitle: "Cancel".localized(),
                        overlayView: self?.overlayView
                    )
                } else {
                    self?.relocate(files: selectedFiles, to: destination)
                }
            },
        ]
        // On iOS 26 the toolbar is transparent so items sit flush; add a gap before the X.
        // Pre-iOS 26 the white pill layout looks correct without an extra gap.
        if #available(iOS 26, *) {
            rightItems.append(FloatingActionImageItem(image: UIColor.clear.imageWithColor(width: 0, height: 0), action: nil))
        }
        rightItems.append(FloatingActionImageItem(image: closeImage) { [weak self] vc, item in
            self?.dismissFloatingActionIsland()
            self?.updateFABViewVisibility()

            self?.viewModel?.selectedFiles = []
            self?.viewModel?.fileAction = .none
            self?.viewModel?.isSelectingDestination = false

            self?.collectionView?.reloadData()
        })

        if viewModel?.fileAction != FileAction.none {
            showFloatingActionIsland(withLeftItems: leftItems, rightItems: rightItems)
            viewModel?.isSelectingDestination = true
        } else {
            viewModel?.isSelectingDestination = false
        }

        collectionView?.reloadData()
    }
    
    func showMemberChecklistButton() {
        viewModel?.showMemberChecklist({ [weak self] showChecklist in
            self?.fabView.showsChecklistButton = showChecklist ?? false
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self?.bottomButtonsConstrainHeight.constant = showChecklist ?? false ? 140 : 64
                self?.view.layoutIfNeeded()
            })
        })
    }
    
    func updateFABViewVisibility() {
        // Update FAB view visibility based on current archive permissions
        guard let viewModel = viewModel else { return }

        let hasCreatePermission = viewModel.archivePermissions.contains(.create)
        let hasUploadPermission = viewModel.archivePermissions.contains(.upload)
        // Hide the FAB while picking a paste destination — you are choosing where to paste, not adding
        // files — or it reappears on every navigation during paste mode.
        let shouldShowFAB = hasCreatePermission && hasUploadPermission && !viewModel.isPickingImage
            && !viewModel.isSelectingDestination
            // Multi-select owns the screen while active; the FAB comes back via the
            // restore paths below, which all route through this gate.
            && !viewModel.isSelecting

        // `setVisibility` fades the buttons back in: paste mode created a real hide→show transition,
        // and an instant reveal reads as a pop-in.
        fabView.setVisibility(hidden: !shouldShowFAB)
    }
    
    func resetCollectionViewState() {
        // Reset collection view scroll position to top
        collectionView.setContentOffset(.zero, animated: false)
        
        // End any ongoing refresh control animation
        if refreshControl.isRefreshing {
            refreshControl.endRefreshing()
        }
        
        // Completely re-establish refresh control connection
        collectionView.refreshControl = nil
        collectionView.refreshControl = refreshControl
        
        // Ensure refresh control is enabled and ready
        refreshControl.isEnabled = true
        
        // Reset collection view properties that might affect pull-to-refresh
        collectionView.alwaysBounceVertical = true
        collectionView.isScrollEnabled = true
        collectionView.showsVerticalScrollIndicator = false
        
        // Force collection view layout update
        collectionView.setNeedsLayout()
        collectionView.layoutIfNeeded()
        
        // Re-establish content insets to ensure proper scroll behavior
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: UIScreen.main.bounds.width, right: 6)
    }
    
    fileprivate func setupBottomActionSheetForMultipleFiles() {
        let itemsNumber: FloatingActionTextItem
        let blankImage = UIColor.clear.imageWithColor(width: 0, height: 0)
        let numberOfItems = viewModel?.selectedFiles?.count ?? 0
        let itemsText = numberOfItems > 1 ? "Items".localized() : "Item".localized()
        itemsNumber = FloatingActionTextItem(text: "<COUNT> \(itemsText)".localized().replacingOccurrences(of: "<COUNT>" , with: String(numberOfItems)), action: nil)
        itemsNumber.barButtonItem?.tintColor = .middleGray

        let leftItems = [itemsNumber]
        let rightItems = [
            FloatingActionImageItem(image: UIImage(named: "floatingCopy")!, action: { [weak self] _,_  in
                self?.dismissFloatingActionIsland({ [weak self] in
                    self?.viewModel?.fileAction = FileAction.copy
                    self?.relocateAction(files: self?.viewModel?.selectedFiles, action: .copy)

                    // FAB stays hidden in paste-destination mode (see updateFABViewVisibility).
                    if let backButtonIsHidden = self?.backButton.isHidden, !backButtonIsHidden {
                        self?.backButton.isUserInteractionEnabled = true
                        self?.backButton.layer.opacity = 1
                    }
                    
                    self?.viewModel?.isSelecting = false
                    self?.setupBottomActionSheet()
                })
            }),
            FloatingActionImageItem(image: blankImage, action: nil),
            FloatingActionImageItem(image: UIImage(named: "floatingMove")!, action: { [weak self] _,_  in
                self?.dismissFloatingActionIsland({ [weak self] in
                    self?.viewModel?.fileAction = FileAction.move
                    self?.relocateAction(files: self?.viewModel?.selectedFiles, action: .move)

                    // FAB stays hidden in paste-destination mode (see updateFABViewVisibility).
                    if let backButtonIsHidden = self?.backButton.isHidden, !backButtonIsHidden {
                        self?.backButton.isUserInteractionEnabled = true
                        self?.backButton.layer.opacity = 1
                    }

                    self?.viewModel?.isSelecting = false
                    self?.setupBottomActionSheet()
                })
            }),
            FloatingActionImageItem(image: blankImage, action: nil),
            FloatingActionImageItem(image: (UIImage(named: "floatingMore")?.templated!)!, action: { [weak self] _,_  in
                self?.showFileActionSheetForSelection()
            })
        ]
        
        if floatingActionIsland == nil {
            showFloatingActionIsland(withLeftItems: leftItems, rightItems: rightItems)
        } else {
            floatingActionIsland?.leftItems = leftItems
        }
    }
    
    fileprivate func toggleFileAction(_ action: FileAction?) {
        // If we try to move file in the same folder, disable the button
        guard let selectedFile = viewModel?.selectedFiles?.first else { return }
        let shouldDisableButton = selectedFile.parentFolderId == viewModel?.currentFolder?.folderId && action == .move
        fileActionBottomView.toggleActionButton(enabled: !shouldDisableButton)
    }
    
    @objc func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction
    func backButtonAction(_ sender: UIButton) {
        guard
            let viewModel = viewModel,
            let _ = viewModel.removeCurrentFolderFromHierarchy(),
            let destinationFolder = viewModel.currentFolder
        else {
            return
        }
        
        let navigateParams: NavigateMinParams = (destinationFolder.archiveNo, destinationFolder.folderLinkId, nil)
        navigateToFolder(withParams: navigateParams, backNavigation: true, then: {
            self.directoryLabel.text = destinationFolder.name
            
            // If we got to the root, hide the back button.
            if viewModel.currentFolderIsRoot {
                self.backButton.isHidden = true
                self.directoryLabel.text = viewModel.rootFolderName
            }
        })
    }
    
    private func refreshCurrentFolder(shouldDisplaySpinner: Bool = true, silenceErrors: Bool = false, then handler: VoidAction? = nil) {
        guard
            let viewModel = viewModel,
            let currentFolder = viewModel.currentFolder else { return }

        viewModel.refreshUploadQueue()

        let params: NavigateMinParams = (
            currentFolder.archiveNo,
            currentFolder.folderLinkId,
            nil
        )

        // Back navigation set to `true` so it's not considered a in-depth navigation.
        // resetScroll false to preserve scroll position when refreshing the same folder.
        navigateToFolder(withParams: params, backNavigation: true, shouldDisplaySpinner: shouldDisplaySpinner, resetScroll: false, silenceErrors: silenceErrors, then: handler)
    }
    
    @objc
    private func pullToRefreshAction() {
        refreshCurrentFolder(
            shouldDisplaySpinner: false,
            silenceErrors: true,
            then: {
                self.refreshControl.endRefreshing()
            }
        )
        viewModel?.invalidateTimer()
    }
    
    private func handleProgress(withValue value: Float, listSection section: FileListType) {
        let indexPath = IndexPath(row: 0, section: section.rawValue)
        
        guard let uploadingCell = collectionView.cellForItem(at: indexPath) as? FileCollectionViewCell else {
            return
        }

        uploadingCell.updateProgress(withValue: value)
    }
    
    @objc
    private func headerButtonAction(_ sender: UIButton) {
        showSortActionSheetDialog()
    }
    
    @objc
    private func cancelAllUploadsAction(_ sender: UIButton) {
        let confirmationView = CancelUploadsConfirmationView(
            onConfirm: { [weak self] in
                self?.viewModel?.cancelUploadsInFolder()
                if self?.viewModel?.refreshUploadQueue() == true {
                    self?.refreshCollectionView()
                }
            },
            onDismiss: { [weak self] in
                self?.dismiss(animated: false)
            }
        )

        let hosting = UIHostingController(rootView: confirmationView)
        hosting.modalPresentationStyle = .overFullScreen
        hosting.view.backgroundColor = .clear
        // animated: false lets SwiftUI own the full slide-up/down animation
        present(hosting, animated: false)
    }

    @objc
    /// Internal (not private) so tests can drive the select-mode transitions directly —
    /// the FAB permission-gate regression lived exactly on this path.
    func selectButtonWasPressed(_ sender: UIButton) {
        guard let viewModel = viewModel else { return }
        // Can't (re)enter multi-select while choosing a paste destination — that mode owns
        // the fixed relocate selection. Belt-and-suspenders with hiding the button below.
        guard !viewModel.isSelectingDestination else { return }
        fabView.setVisibility(hidden: true)
        if !backButton.isHidden {
            backButton.isUserInteractionEnabled = false
            backButton.layer.opacity = 0.3
        }

        if viewModel.isSelecting {
            if viewModel.selectedFiles?.count == viewModel.viewModels.count {
                // Deselect all files
                viewModel.selectedFiles = []
            } else {
                // Select all files
                viewModel.selectedFiles = viewModel.viewModels
            }
        } else {
            viewModel.isSelecting = true
        }

        refreshCollectionView()
    }
    
    @objc
    /// Internal (not private) so tests can drive the select-mode transitions directly —
    /// the FAB permission-gate regression lived exactly on this path.
    func clearButtonWasPressed(_ sender: UIButton) {
        if !backButton.isHidden {
            backButton.isUserInteractionEnabled = true
            backButton.layer.opacity = 1
        }

        viewModel?.selectedFiles = []
        viewModel?.isSelecting = false
        // Restore the FAB through the permission gate, never unconditionally: on a viewer-role archive,
        // leaving select mode must not conjure an upload button. Must run after the reset above.
        updateFABViewVisibility()
        collectionView.reloadData()
    }
    
    @IBAction func switchViewButtonPressed(_ sender: Any) {
        isGridView.toggle()
        viewModel?.isGridView = isGridView
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 60, right: 6)
    
        switchViewButton.setImage(UIImage(systemName: isGridView ? "list.bullet" : "square.grid.2x2.fill"), for: .normal)
        
        collectionView.reloadData()
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 6
        flowLayout.minimumLineSpacing = 0
        flowLayout.estimatedItemSize = .zero
        collectionView.collectionViewLayout = flowLayout
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    @objc func searchButtonPressed(_ sender: Any) {
        guard let searchVC = makeSearchViewController() else {
            return
        }
        
        let navController = NavigationController(rootViewController: searchVC)
        navController.modalPresentationStyle = .fullScreen
        if let presenter = presentSearchController {
            presenter(navController, false)
        } else {
            present(navController, animated: false)
        }
    }
    
    func showBanner() {
        var bannerType = BannerType.noBanner
        if bannerType.shouldShowBanner() {
            let bannerView = BannerView(type: bannerType)
            bannerView.dismissAction = {
                bannerView.removeFromSuperview()
            }
            
            bannerView.action = {[weak self] in
                self?.showLegacy()
                bannerView.removeFromSuperview()
            }
            
            view.addSubview(bannerView)
            
            bannerView.translatesAutoresizingMaskIntoConstraints = false
            let padding: CGFloat = 12
            bannerView.topAnchor.constraint(equalTo: view.topAnchor, constant: padding).isActive = true
            bannerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: padding).isActive = true
            bannerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -padding).isActive = true
        }
    }
    
    func showLegacy() {
        if let legacyPlanningLoadingVC = UIViewController.create(withIdentifier: .legacyPlanningLoading, from: .legacyPlanning) as? LegacyPlanningLoadingViewController {
            legacyPlanningLoadingVC.viewModel = LegacyPlanningViewModel()
            legacyPlanningLoadingVC.viewModel?.account = AuthenticationManager.shared.session?.account
            let customNavController = NavigationController(rootViewController: legacyPlanningLoadingVC)
            customNavController.modalPresentationStyle = .fullScreen
            self.present(customNavController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Network Related
    
    private func getRootFolder() {
        showSpinner()

        let runRequest: (@escaping ServerResponse) -> Void = getRootRequest ?? { [weak self] completion in
            self?.viewModel?.getRoot(then: completion)
        }

        runRequest({ status in
            self.onFilesFetchCompletion(status)
            self.checkForSavedUniversalLink()
            self.checkForRequestShareAccess()
        })
    }
    
    func navigationToShareFolderLink() {
        if let navParamsOptional: NavigationDataForShareFolderLink? = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.navigationToShareFolderLink),
           let navParams = navParamsOptional  {
            backButton.isHidden = false
            
            // Standard navigation to shared folder
            navigateToFolder(withParams: NavigateMinParams(archiveNo: navParams.archiveNo, folderLinkId: navParams.folderLinkId, folderName: navParams.folderName), backNavigation: false, shouldDisplaySpinner: true, then: { [weak self] in
                // Ensure the folder name is preserved even after navigation completes
                if let folderName = navParams.folderName, !folderName.isEmpty {
                    self?.directoryLabel.text = folderName
                } else {
                    // Fallback to current folder name if available
                    self?.directoryLabel.text = self?.viewModel?.currentFolder?.name ?? "Folder"
                }
            })
            
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.navigationToShareFolderLink)
        }
    }
    
    func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, shouldDisplaySpinner: Bool = true, resetScroll: Bool = true, silenceErrors: Bool = false, then handler: VoidAction? = nil) {
        shouldDisplaySpinner ? showSpinner() : nil

        let runRequest: (NavigateMinParams, Bool, @escaping ServerResponse) -> Void = navigateMinRequest ?? { [weak self] requestParams, requestBackNavigation, completion in
            self?.viewModel?.navigateMin(params: requestParams, backNavigation: requestBackNavigation, then: completion)
        }

        runRequest(params, backNavigation, { status in
            self.onFilesFetchCompletion(status, resetScroll: resetScroll, silenceErrors: silenceErrors)
            handler?()
        })
        viewModel?.timer?.invalidate()
    }

    private func onFilesFetchCompletion(_ status: RequestStatus, resetScroll: Bool = false, silenceErrors: Bool = false) {
        DispatchQueue.main.async {
            self.hideSpinner()

            // Ensure refresh control is properly ended
            if self.refreshControl.isRefreshing {
                self.refreshControl.endRefreshing()
            }
        }

        viewModel?.refreshUploadQueue()

        switch status {
        case .success:
            refreshCollectionView()
            if resetScroll {
                let inset = collectionView.adjustedContentInset
                collectionView.setContentOffset(CGPoint(x: -inset.left, y: -inset.top), animated: false)
            }
            toggleFileAction(viewModel?.fileAction)
            updateFABViewVisibility()
            navigationToShareFolderLink()

        case .error(let message):
            if !silenceErrors {
                showErrorAlert(message: message)
            }
        }
    }
    
    fileprivate func checkForSavedUniversalLink() {
        guard
            let token: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.shareURLToken)
        else {
            return
        }
        
        let viewController: UIViewController
        let hostingController = SharePreviewHostingController(shareToken: token)
        hostingController.navigateTo = { [weak self] params in
            self?.navigateToFolder(withParams: params, backNavigation: false)
        }
        hostingController.wireCallbacks()
        viewController = hostingController
        
        if let displayController {
            displayController(viewController)
        } else {
            navigationController?.display(viewController: viewController)
        }
    }
    
    func checkForRequestShareAccess() {
        guard
            let sharedFilePayload: RequestLinkAccessNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.requestLinkAccess)
        else {
            return
        }
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.requestLinkAccess)
        
        func _presentShare() {
            let fileType = sharedFilePayload.isFolder ? FileType.privateFolder.rawValue : FileType.miscellaneous.rawValue
            let file = FileModel(name: sharedFilePayload.name, recordId: sharedFilePayload.recordId, folderLinkId: sharedFilePayload.folderLinkId, archiveNbr: "0", type: fileType, permissions: viewModel!.archivePermissions)
            
            if sharedFilePayload.isFolder {
                // For folders, show share management
                presentShareManagement(for: file)
            } else {
                // For records/files, open in file preview with proper navigation and close button
                let filePreviewVC = FilePreviewListViewController(nibName: nil, bundle: nil)
                filePreviewVC.modalPresentationStyle = .fullScreen
                filePreviewVC.viewModel = self.viewModel
                filePreviewVC.currentFile = file
                filePreviewVC.isFromNotification = true
                
                let navController = FilePreviewNavigationController(rootViewController: filePreviewVC)
                navController.filePreviewNavDelegate = self
                navController.modalPresentationStyle = .fullScreen
                
                self.present(navController, animated: true)
            }
        }
        
        let currentArchive: ArchiveVOData? = viewModel?.currentArchive
        if currentArchive?.archiveNbr != sharedFilePayload.toArchiveNbr {
            let action = { [weak self] in
                self?.actionDialog?.dismiss()
                
                self?.viewModel?.changeArchive(withArchiveId: sharedFilePayload.toArchiveId, archiveNbr: sharedFilePayload.toArchiveNbr, completion: { success in
                    self?.getRootFolder()
                    _presentShare()
                })
                
                self?.actionDialog = nil
            }
            
            let title = "Switch to The <ARCHIVE_NAME> Archive?".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: sharedFilePayload.toArchiveName)
            let description = "In order to access this content you need to switch to The <ARCHIVE_NAME> Archive.".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: sharedFilePayload.toArchiveName)
            showActionDialog(
                styled: .simpleWithDescription,
                withTitle: title,
                description: description,
                positiveButtonTitle: "Switch".localized(),
                positiveAction: action,
                cancelButtonTitle: "Cancel".localized(),
                overlayView: overlayView
            )
        } else {
            _presentShare()
        }
    }
    
    private func upload(files: [FileInfo], completion: ((Bool) -> Void)? = nil) {
        viewModel?.uploadFiles(files, completion: completion)
    }

    /// Surfaces a name conflict before any bytes leave the device. The caller shows the spinner and
    /// hides it in `completion`; it is hidden while the alert is up so it can't obscure the choice.
    private func checkDuplicatesThenUpload(
        files: [FileInfo],
        in folder: FileModel,
        completion: @escaping ((Bool) -> Void)
    ) {
        let archiveNo = PermSession.currentSession?.selectedArchive?.archiveNbr ?? ""
        UploadManager.shared.findExistingRecords(
            archiveNo: archiveNo,
            folderLinkId: folder.folderLinkId,
            forFiles: files
        ) { [weak self] duplicates in
            guard let self = self else { return }
            if duplicates.isEmpty {
                self.upload(files: files, completion: completion)
                return
            }
            // Hide the spinner so the alert isn't obscured; re-show only if
            // the user opts into an upload path.
            self.hideSpinner()
            let duplicateIds = Set(duplicates.map { $0.file.id })
            let duplicateNames = duplicates.map { $0.file.name }
            self.promptDuplicateUploadDecision(
                total: files.count,
                duplicateFileNames: duplicateNames
            ) { [weak self] choice in
                guard let self = self else { return }
                switch choice {
                case .skipDuplicates:
                    let filtered = files.filter { !duplicateIds.contains($0.id) }
                    self.showSpinner()
                    self.upload(files: filtered, completion: completion)
                case .uploadAll:
                    self.showSpinner()
                    self.upload(files: files, completion: completion)
                case .cancel:
                    completion(false)
                }
            }
        }
    }
    
    private func createNewFolder(named name: String) {
        guard
            let viewModel = viewModel,
            let currentFolder = viewModel.currentFolder else { return }

        let params: NewFolderParams = (name, currentFolder.folderLinkId)

        showSpinner()
        viewModel.createNewFolder(params: params, then: { status in
            self.hideSpinner()

            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.refreshCollectionView()
                    self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "Folder successfully created".localized())
                }

            case .error(_):
                self.view.showNotificationBanner(title: .errorMessage, backgroundColor: .deepRed, textColor: .white)
            }
        })
    }
    
    func deleteFile(_ files: [FileModel]?) {
        showSpinner()
        viewModel?.delete(files, then: { status in
            self.hideSpinner()

            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.viewModel?.removeSyncedFiles(files)
                    self.refreshCollectionView()
                }

            case .error(_):
                DispatchQueue.main.async {
                    self.showErrorAlert(message: .deleteError) {
                        self.refreshCurrentFolder()
                        self.updateFABViewVisibility()
                    }
                }
            }
        })
    }

    func rename(_ file: FileModel, _ name: String, atIndexPath indexPath: IndexPath) {
        showSpinner()
        viewModel?.rename(file: file, name: name, then: { status in
            switch status {
            case .success:
                self.refreshCurrentFolder(shouldDisplaySpinner: false, then: {
                    self.hideSpinner()
                    if file.type.isFolder {
                        self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "Folder rename was successful".localized())
                    } else {
                        self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "File rename was successful".localized())
                    }
                })
                
            case .error( _):
                self.hideSpinner()
                self.view.showNotificationBanner(title: .errorMessage, backgroundColor: .deepRed, textColor: .white)
            }
        })
    }
    
    func relocate(files: [FileModel], to destination: FileModel) {
        let isInvalidDestination = destination.folderId == files.first?.parentFolderId
        if isInvalidDestination && viewModel?.fileAction == .move {
            showErrorAlert(message: "Please select a different destination folder.".localized())
            return
        }

        if !isInvalidDestination || viewModel?.fileAction != .move {
            floatingActionIsland?.showActivityIndicator()
            viewModel?.relocate(files: files, to: destination, then: { status in
                switch status {
                case .success:
                    // Refetch rather than insert the source models: a copy is a new server record, so the inserted
                    // row would carry the original's ids and deleting "the copy" would delete the original.
                    self.viewModel?.expectPastedItems(files, destination: destination)
                    self.settlePastedItems(attemptsLeft: MainViewController.pastedItemsSettleAttempts) { [weak self] in
                        self?.floatingActionIsland?.hideActivityIndicator()
                        self?.floatingActionIsland?.showDoneCheckmark() {
                            self?.dismissFloatingActionIsland({ [weak self] in
                                self?.fabView?.setVisibility(hidden: false)
                                self?.viewModel?.isSelectingDestination = false
                                // Fully exit selection mode: the single-file Copy entry keeps `isSelecting` on through the
                                // paste, so the list would re-render with checkboxes afterwards.
                                self?.viewModel?.isSelecting = false

                                // Hand any remaining wait (a copy's thumbnails, or rows that
                                // still haven't surfaced) to the background poll.
                                self?.viewModel?.timerRunCount = 0
                                self?.scheduleNextThumbnailPoll()
                            })
                        }
                    }

                case .error(_):
                    self.floatingActionIsland?.hideActivityIndicator()
                    self.dismissFloatingActionIsland()
                    self.showErrorAlert(message: .relocateError) {
                        self.refreshCurrentFolder()
                        self.fabView?.setVisibility(hidden: false)
                        self.viewModel?.isSelectingDestination = false
                    }
                }
            })
        }
    }

    /// Refetch attempts before a paste completes anyway, bounding the spinner to ~10s. A record copy
    /// lands first try, but a V1 folder copy needs most of that budget before its row appears.
    private static let pastedItemsSettleAttempts = 10

    /// Refetches the destination until the pasted rows are listed, since the server commits a
    /// relocate asynchronously. Always completes: on success, on giving up, or on navigating away.
    private func settlePastedItems(attemptsLeft: Int, then completion: @escaping () -> Void) {
        refreshCurrentFolder(shouldDisplaySpinner: false, silenceErrors: true, then: { [weak self] in
            guard let self = self, let viewModel = self.viewModel else {
                completion()
                return
            }
            guard viewModel.isAwaitingPastedItems, attemptsLeft > 0 else {
                completion() // rows are on screen (or we've waited long enough)
                return
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + FilesViewModel.pastedItemsPollInterval) { [weak self] in
                guard let self = self else {
                    completion()
                    return
                }
                self.settlePastedItems(attemptsLeft: attemptsLeft - 1, then: completion)
            }
        })
    }

    func publish(file: FileModel) {
        showSpinner()
        viewModel?.publish(files: [file], then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                if file.type.isFolder {
                    self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "Folder published successfully".localized())
                } else {
                    self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "File published successfully".localized())
                }
                
            case .error(let message):
                self.showErrorAlert(message: message)
            }
        })
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension MainViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel?.numberOfSections ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.numberOfRowsInSection(section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = self.viewModel else {
            return UICollectionViewCell()
        }
        
        let reuseIdentifier: String
        if indexPath.section == FileListType.synced.rawValue {
            reuseIdentifier = isGridView ? "FileGridCell" : "FileCell"
        } else {
            reuseIdentifier = "FileCell"
        }

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FileCollectionViewCell
        let file = viewModel.fileForRowAt(indexPath: indexPath)
        let isFileSelected = viewModel.selectedFiles?.contains(file) ?? false
        
        cell.updateCell(model: file, fileAction: viewModel.fileAction, isGridCell: isGridView, isSearchCell: false, isSelecting: viewModel.isSelecting, isFileSelected: isFileSelected)
        
        cell.moreButton.isHidden = cell.moreButton.isHidden || viewModel.isPickingImage
        cell.rightButtonImageView.isHidden = cell.rightButtonImageView.isHidden || viewModel.isPickingImage
        let pendingInvitationCount = pendingInvitationBadgeCount(for: file)
        cell.setMoreButtonBadgeCount(cell.moreButton.isHidden ? 0 : pendingInvitationCount)
        
        cell.rightButtonTapAction = { _ in
            self.handleCellRightButtonAction(for: file, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let listItemSize = CGSize(width: UIScreen.main.bounds.width, height: 74)
        // Horizontal layout: |-6-cell-6-cell-6-|. 6*3/2 = 9
        // Vertical size: 30 is the height of the title label
        let gridItemSize = CGSize(width: UIScreen.main.bounds.width / 2 - 9, height: UIScreen.main.bounds.width / 2 + 30)
        
        if indexPath.section == FileListType.synced.rawValue {
            return isGridView ? gridItemSize : listItemSize
        } else {
            return listItemSize
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel else { return }
        
        let file = viewModel.fileForRowAt(indexPath: indexPath)

        guard file.fileStatus == .synced && (file.thumbnailURL != nil || file.canBeAccessed) else { return }

        // While picking a paste destination the list is navigation-only: the selection set is fixed to
        // the items being relocated, so a tap only drills into an eligible folder.
        if viewModel.isSelectingDestination {
            guard file.type.isFolder, !(viewModel.selectedFiles?.contains(file) ?? false) else { return }
            viewModel.v2NavigationTarget = file
            let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, nil)
            navigateToFolder(withParams: navigateParams, backNavigation: false, then: {
                self.backButton.isHidden = false
                self.directoryLabel.text = file.name
            })
            return
        }

        if viewModel.isSelecting {
            if let index = viewModel.selectedFiles?.firstIndex(of: file) {
                viewModel.selectedFiles?.remove(at: index)
            } else {
                viewModel.selectedFiles?.append(file)
            }
            self.refreshCollectionView()
        } else {
            if file.type.isFolder {
                let isFolderSelected = viewModel.selectedFiles?.contains(file) ?? false
                
                if !isFolderSelected || viewModel.fileAction.action.isEmpty {
                    viewModel.isSelecting = false
                    // Seed the V2 navigation target (no-op when Stela nav is off): V2 needs
                    // the String folderId, which lives on the tapped FileModel.
                    viewModel.v2NavigationTarget = file
                    let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, nil)
                    navigateToFolder(withParams: navigateParams, backNavigation: false, then: {
                        self.backButton.isHidden = false
                        self.directoryLabel.text = file.name
                    })
                }
            } else {
                if viewModel.isPickingImage {
                    handleImagePickerSelection(file: file)
                } else {
                    handlePreviewSelection(file: file)
                }
            }
        }
    }
    
    func handleImagePickerSelection(file: FileModel) {
        guard let viewModel = viewModel else { return }
        
        viewModel.pickerDelegate?.myFilesVMDidPickFile(viewModel: viewModel, file: file)
    }
    
    private func pendingInvitationBadgeCount(for file: FileModel) -> Int {
        file.minArchiveVOS.filter {
            ArchiveVOData.Status(rawValue: $0.shareStatus) == .pending
        }.count
    }
    
    func handlePreviewSelection(file: FileModel) {
        let listPreviewVC = FilePreviewListViewController(nibName: nil, bundle: nil)
        listPreviewVC.modalPresentationStyle = .fullScreen
        listPreviewVC.viewModel = viewModel
        listPreviewVC.currentFile = file
        
        let fileDetailsNavigationController = FilePreviewNavigationController(rootViewController: listPreviewVC)
        fileDetailsNavigationController.filePreviewNavDelegate = self
        fileDetailsNavigationController.modalPresentationStyle = .fullScreen
        
        present(fileDetailsNavigationController, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let section = indexPath.section
            
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FileCollectionViewHeaderCell.identifier, for: indexPath) as! FileCollectionViewHeaderCell
            headerView.leftButtonTitle = viewModel?.title(forSection: section)
            headerView.configure(with: viewModel, isPickingProfilePicture: viewModel!.isPickingImage)
            if viewModel?.shouldPerformAction(forSection: section) == true {
                headerView.leftButtonAction = { [weak self] header in self?.headerButtonAction(UIButton()) }
            } else {
                headerView.leftButtonAction = nil
            }
            
            // Reset the reused header's Select button to visible; a previous dequeue may
            // have hidden it for a paste-destination section (see below).
            headerView.rightButton.isHidden = false

            if viewModel?.hasCancelButton(forSection: section) == true {
                headerView.rightButtonTitle = "Cancel All".localized()
                headerView.rightButtonAction = { [weak self] header in self?.cancelAllUploadsAction(UIButton()) }
            } else {
                if let selectWasPressed = viewModel?.isSelecting, selectWasPressed {
                    headerView.rightButtonTitle = "Select all  ".localized()
                } else {
                    headerView.rightButtonTitle = (viewModel?.isSelectingDestination ?? false) ? nil : "Select".localized()
                }
                // A title-less button is still tappable, so hide it outright in paste mode — otherwise tapping
                // where Select used to be silently re-enters multi-select.
                headerView.rightButton.isHidden = viewModel?.isSelectingDestination ?? false

                headerView.rightButtonAction = { [weak self] header in self?.selectButtonWasPressed(UIButton())}
                headerView.clearButtonAction = { [weak self] header in self?.clearButtonWasPressed(UIButton())}
            }
            
            return headerView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let height: CGFloat = viewModel?.numberOfRowsInSection(section) != 0 ? 40 : 0
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }
    
    @objc
    private func timerActions() {
        // Re-arm only after the refetch commits: the gate reads `viewModels`, so scheduling earlier
        // tests the previous list. Not via `pullToRefreshAction`, whose invalidate would cancel the chain.
        refreshCurrentFolder(shouldDisplaySpinner: false, silenceErrors: true, then: { [weak self] in
            self?.scheduleNextThumbnailPoll()
        })
    }

    /// Polls the current folder while any item is still processing server-side. Stops on its own
    /// once the folder settles or the run cap is hit; navigation or a manual pull cancels it.
    private func scheduleNextThumbnailPoll() {
        guard let viewModel = viewModel else { return }
        guard viewModel.hasItemsAwaitingProcessing || viewModel.isAwaitingPastedItems else {
            viewModel.timerRunCount = 0 // settled — leave the counter fresh for the next kick
            viewModel.clearPastedItemsExpectation()
            return
        }
        guard viewModel.timerRunCount < FilesViewModel.thumbnailPollMaxRuns else {
            viewModel.clearPastedItemsExpectation() // gave up waiting; don't re-arm on the next kick
            return
        }
        viewModel.timerRunCount += 1
        // Three waits, three cadences: a missing row is a ~1s commit race, an item mid copy/move takes
        // seconds to tens of seconds, and the thumbnail settle genuinely takes minutes.
        let isRaceForMissingRows = viewModel.isAwaitingPastedItems
            && viewModel.timerRunCount <= FilesViewModel.pastedItemsFastRuns
        let interval: TimeInterval
        if isRaceForMissingRows {
            interval = FilesViewModel.pastedItemsPollInterval
        } else if viewModel.hasItemsInTransientState {
            interval = FilesViewModel.transientStatePollInterval
        } else {
            interval = FilesViewModel.thumbnailPollInterval
        }
        // Never stack chains: kill any pending fire before scheduling the next one.
        viewModel.timer?.invalidate()
        viewModel.timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            // Clear before refetching, so the fired timer reads as "no pending chain" — otherwise
            // `invalidateTimer` zeroes the run count on every fire and the chain never terminates.
            self?.viewModel?.timer = nil
            self?.timerActions()
        }
    }
}

// MARK: - Table View Delegates

extension MainViewController {
    private func handleCellRightButtonAction(for file: FileModel, atIndexPath indexPath: IndexPath) {
        switch file.fileStatus {
        case .synced:
            if let isSelecting = viewModel?.isSelecting, isSelecting {
                if let index = viewModel?.selectedFiles?.firstIndex(of: file) {
                    viewModel?.selectedFiles?.remove(at: index)
                } else {
                    viewModel?.selectedFiles?.append(file)
                }
                self.refreshCollectionView()
            } else {
                showFileActionSheet(file: file, atIndexPath: indexPath)
            }
            
        case .downloading:
            viewModel?.cancelDownload()
            
            self.collectionView.reloadData()
            
        case .uploading, .waiting, .failed:
            viewModel?.removeFromQueue(indexPath.row)
            
            if viewModel?.refreshUploadQueue() == true {
                refreshCollectionView()
            }
        }
    }
    
    private func didTapDelete(forFile file: FileModel, atIndexPath indexPath: IndexPath) {
        let title = String(format: "\(String.delete) \"%@\"?", file.name)
    
            self.showActionDialog(
                styled: .simple,
                withTitle: title,
                positiveButtonTitle: .delete,
                positiveAction: {
                    self.actionDialog?.dismiss()
                    self.deleteFile([file])
                }, positiveButtonColor: .brightRed,
                cancelButtonColor: .primary,
                overlayView: self.overlayView
            )
        }
    
    private func didTapPublish(source: FileModel) {
        let presentPublishView: () -> Void = { [weak self] in
            guard let self = self else { return }
            
            var hostingController: UIHostingController<PublishView>?
            
            let publishView = PublishView(
                fileName: source.name,
                isFolder: source.type.isFolder,
                thumbnailURL: source.thumbnailURL,
                thumbnailURL2000: source.thumbnailURL2000,
                onPublish: { [weak self] in
                    hostingController?.dismiss(animated: false) {
                        self?.publish(file: source)
                    }
                },
                onDismiss: {
                    hostingController?.dismiss(animated: false)
                }
            )
            
            hostingController = UIHostingController(rootView: publishView)
            hostingController?.modalPresentationStyle = .overFullScreen
            hostingController?.modalTransitionStyle = .crossDissolve
            hostingController?.view.backgroundColor = .clear
            
            if let controller = hostingController {
                self.present(controller, animated: false)
            }
        }
        
        if let presented = presentedViewController {
            presented.dismiss(animated: true) {
                DispatchQueue.main.async {
                    presentPublishView()
                }
            }
        } else {
            presentPublishView()
        }
    }

    private func download(_ file: FileModel) {
        viewModel?.download(
            file,
            
            onDownloadStart: {
                DispatchQueue.main.async {
                    self.refreshCollectionView()
                }
            },
            
            onFileDownloaded: { url, error in
                DispatchQueue.main.async {
                    self.onFileDownloaded(url: url, name: file.name, error: error)
                }
            },
            
            progressHandler: { progress in
                DispatchQueue.main.async {
                    self.handleProgress(withValue: progress, listSection: FileListType.downloading)
                }
            }
        )
    }
    
    fileprivate func onFileDownloaded(url: URL?, name: String?, error: Error?) {
        refreshCollectionView()
        
        guard url != nil else {
            let apiError = (error as? APIError) ?? .unknown
            
            if apiError == .cancelled {
                view.showNotificationBanner(height: Constants.Design.bannerHeight, title: .downloadCancelled)
            } else {
                showErrorAlert(message: apiError.message)
            }
            return
        }
        let name = name ?? "File"
        view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "'\(name)' " + "download completed".localized(), animationDelayInSeconds: Constants.Design.longNotificationBarAnimationDuration)
    }
}

// MARK: - FABViewDelegate

extension MainViewController: FABViewDelegate {
    func didTap() {
        let fabMenuView = FABMenuView(
            onCreateFolder: { [weak self] in
                self?.didTapNewFolder()
            },
            onTakePhoto: { [weak self] in
                self?.handleUploadAction {
                    self?.openCamera()
                }
            },
            onUploadPhotos: { [weak self] in
                self?.handleUploadAction {
                    self?.openPhotoLibrary()
                }
            },
            onBrowseFiles: { [weak self] in
                self?.handleUploadAction {
                    self?.openFileBrowser()
                }
            },
            onDismiss: { [weak self] in
                self?.dismiss(animated: false, completion: {
                    // Restore through the permission gate — a viewer-role archive must not
                    // get the FAB back just because the menu closed. setVisibility animates.
                    self?.updateFABViewVisibility()
                })
            }
        )
        
        let hostingController = UIHostingController(rootView: fabMenuView)
        hostingController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        hostingController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        hostingController.view.backgroundColor = UIColor.clear
        
        present(hostingController, animated: true)
        
        // Hide the FAB through the same API that shows it: the permission gate only manages `isHidden`,
        // so hand-fading alpha here left the FAB invisible after any menu action.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.fabView.setVisibility(hidden: true)
        }
        
        viewModel?.trackEvent(action: RecordEventAction.initiateUpload)
    }
    
    private func handleUploadAction(action: @escaping () -> Void) {
        if viewModel is PublicFilesViewModel {
            let confirmationView = PublicFolderUploadConfirmationView(
                onConfirm: action,
                onDismiss: { [weak self] in
                    self?.dismiss(animated: false)
                }
            )
            let hosting = UIHostingController(rootView: confirmationView)
            hosting.modalPresentationStyle = .overFullScreen
            hosting.view.backgroundColor = .clear
            present(hosting, animated: false)
        } else {
            action()
        }
    }
    
    func didTapChecklist() {
        let checklistView = UIHostingController(rootView: ChecklistBottomMenuView(viewModel: StateObject(wrappedValue: ChecklistBottomMenuViewModel(showsChecklistButton: self.fabView.showsChecklistButton)), dismissAction: { [weak self] in
            self?.fabView.showsChecklistButton = false
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                self?.bottomButtonsConstrainHeight.constant = 64
                self?.view.layoutIfNeeded()
            })
        })
            .edgesIgnoringSafeArea(.all)
        )
        
        checklistView.modalPresentationStyle = .formSheet
        checklistView.view.backgroundColor = .clear
        checklistView.sheetPresentationController?.detents = [.large()]
        
        present(checklistView, animated: true)
    }
}

// MARK: - FABActionSheetDelegate (kept for backwards compatibility)
extension MainViewController: FABActionSheetDelegate {
    func didTapUpload() {
        // This is kept for backwards compatibility but no longer used
        handleUploadAction {
            self.showActionSheet()
        }
    }
    
    func didTapNewFolder() {
        var hostingController: UIHostingController<CreateNewFolderView>?
        
        let createFolderView = CreateNewFolderView(
            onCreateFolder: { [weak self] folderName in
                hostingController?.dismiss(animated: false) {
                    self?.createNewFolder(named: folderName)
                }
            },
            onDismiss: {
                hostingController?.dismiss(animated: false)
            }
        )
        
        hostingController = UIHostingController(rootView: createFolderView)
        hostingController?.modalPresentationStyle = .overFullScreen
        hostingController?.modalTransitionStyle = .crossDissolve
        hostingController?.view.backgroundColor = .clear
        
        if let controller = hostingController {
            present(controller, animated: false)
        }
    }
    
    func showSortActionSheetDialog() {
        guard
            sortActionSheet == nil,
            let viewModel = viewModel else { return }
        
        sortActionSheet = SortActionSheet(
            frame: CGRect(origin: CGPoint(x: 0, y: view.bounds.height), size: view.bounds.size),
            selectedOption: viewModel.activeSortOption,
            onDismiss: {
                self.view.dismissPopup(
                    self.sortActionSheet,
                    overlayView: self.overlayView,
                    completion: { _ in
                        self.sortActionSheet?.removeFromSuperview()
                        self.sortActionSheet = nil
                    }
                )
            }
        )
        
        sortActionSheet?.delegate = self
        view.addSubview(sortActionSheet!)
        view.presentPopup(sortActionSheet, overlayView: overlayView)
    }

    func showFileActionSheet(file: FileModel, atIndexPath indexPath: IndexPath) {
        var menuItems: [FileMenuViewModel.MenuItem] = []
        if file.permissions.contains(.ownership) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .shareToPermanent, action: nil))
        }
        
        // Share to another app - for files with share permission (not folders)
        if file.permissions.contains(.share) && file.type.isFolder == false {
            menuItems.append(FileMenuViewModel.MenuItem(type: .shareToAnotherApp, action: { [self] in
                shareWithOtherApps(file: file)
            }))
        }
        
        if file.permissions.contains(.delete) && viewModel is PublicFilesViewModel == false {
            menuItems.append(FileMenuViewModel.MenuItem(type: .publish, action: { [self] in
                publishAction(file: file)
            }))
        }
        
        if file.permissions.contains(.edit) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .rename, action: { [self] in
                renameAction(file: file, atIndexPath: indexPath)
            }))
        }
        
        if file.permissions.contains(.delete) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .delete, action: { [self] in
                deleteAction(file: file, atIndexPath: indexPath)
            }))
        }
        
        if file.permissions.contains(.move) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .move, action: { [self] in
                relocateAction(files: [file], action: .move)
            }))
        }
        
        if file.permissions.contains(.create) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .copy, action: { [self] in
                relocateAction(files: [file], action: .copy)
            }))
        }
        
        if file.permissions.contains(.read) && file.type.isFolder == false {
            menuItems.append(FileMenuViewModel.MenuItem(type: .download, action: { [self] in
                downloadAction(file: file)
            }))
        }
        
        let swiftUIView = FileMoreMenuView(
            fileViewModel: file,
            menuItems: menuItems,
            onDismiss: { [weak self] in
                self?.dismiss(animated: true)
            },
            onShareManagementRequested: { [weak self] file in
                // Dismiss the menu first, then present ShareManagement
                self?.dismiss(animated: true, completion: {
                    self?.presentShareManagement(for: file)
                })
            },
            onRenameRequested: { [weak self] file in
                self?.dismiss(animated: true)
            },
            onDeleteConfirmed: { [weak self] files in
                self?.dismiss(animated: true, completion: {
                    self?.showSpinner()
                    self?.viewModel?.delete(files, then: { status in
                        self?.hideSpinner()

                        switch status {
                        case .success:
                            DispatchQueue.main.async {
                                self?.viewModel?.removeSyncedFiles(files)
                                self?.refreshCollectionView()
                            }

                        case .error(_):
                            DispatchQueue.main.async {
                                self?.showErrorAlert(message: .deleteError) {
                                    self?.refreshCurrentFolder()
                                    self?.updateFABViewVisibility()
                                }
                            }
                        }
                    })
                })
            },
            onLeaveShareConfirmed: nil,
            downloadHandler: { [weak self] file, completion in
                self?.viewModel?.download(
                    file,
                    onDownloadStart: {

                    },
                    onFileDownloaded: { url, error in
                        DispatchQueue.main.async {
                            completion(url, error)
                        }
                    },
                    progressHandler: nil
                )
            }
        )
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        hostingController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        hostingController.view.backgroundColor = UIColor.clear
        
        present(hostingController, animated: true)
    }
    
    func showFileActionSheetForSelection() {
        guard let file = viewModel?.selectedFiles?.first else { return }
        var menuItems: [FileMenuViewModel.MenuItem] = []
        
        if file.permissions.contains(.delete) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .delete, action: { [weak self] in
                self?.showActionDialog(
                    styled: .simple,
                    withTitle: "Delete selected items?".localized(),
                    positiveButtonTitle: .delete,
                    positiveAction: { [weak self] in
                        self?.actionDialog?.dismiss()
                        self?.deleteFile(self?.viewModel?.selectedFiles)
                        
                        self?.dismissFloatingActionIsland()
                        self?.clearButtonWasPressed(UIButton())
                    }, positiveButtonColor: .brightRed,
                    cancelButtonColor: .primary,
                    overlayView: self?.overlayView
                )
            }))
        }
        
        if file.permissions.contains(.edit) {
            let hasFolder = viewModel?.selectedFiles?.contains(where: { $0.type.isFolder }) ?? false
            if !hasFolder {
                menuItems.append(FileMenuViewModel.MenuItem(type: .editMetadata, action: { [weak self] in
                    self?.presentMetadataEditView { hasUpdates in
                        if hasUpdates {
                            self?.refreshCurrentFolder()
                        }
                    }
                }))
            }
        }
        
        if file.permissions.contains(.move) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .move, action: { [weak self] in
                self?.dismissFloatingActionIsland({ [weak self] in
                    self?.viewModel?.fileAction = FileAction.move
                    self?.relocateAction(files: self?.viewModel?.selectedFiles, action: .move)

                    // FAB stays hidden in paste-destination mode (see updateFABViewVisibility).
                    if let backButtonIsHidden = self?.backButton.isHidden, !backButtonIsHidden {
                        self?.backButton.isUserInteractionEnabled = true
                        self?.backButton.layer.opacity = 1
                    }
                    
                    self?.viewModel?.selectedFiles = nil
                    self?.viewModel?.isSelecting = false
                    self?.setupBottomActionSheet()
                })
            }))
        }
        
        if file.permissions.contains(.create) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .copy, action: { [weak self] in
                self?.dismissFloatingActionIsland({ [weak self] in
                    self?.viewModel?.fileAction = FileAction.copy
                    // Leave selection mode before building the paste island, or checkboxes stay up through paste
                    // mode and reappear afterwards.
                    self?.viewModel?.isSelecting = false
                    self?.relocateAction(files: self?.viewModel?.selectedFiles, action: .copy)

                    // FAB stays hidden in paste-destination mode (see updateFABViewVisibility).
                    if let backButtonIsHidden = self?.backButton.isHidden, !backButtonIsHidden {
                        self?.backButton.isUserInteractionEnabled = true
                        self?.backButton.layer.opacity = 1
                    }
                })
            }))
        }
        
        let swiftUIView = FileMoreMenuView(
            fileViewModel: file,
            menuItems: menuItems,
            selectedItemCount: viewModel?.selectedFiles?.count,
            selectedFiles: viewModel?.selectedFiles,
            onDismiss: { [weak self] in
                self?.dismiss(animated: true)
            },
            onShareManagementRequested: { [weak self] file in
                // Dismiss the menu first, then present ShareManagement
                self?.dismiss(animated: true, completion: {
                    self?.presentShareManagement(for: file)
                })
            },
            onRenameRequested: { [weak self] file in
                self?.dismiss(animated: true)
            },
            onDeleteConfirmed: { [weak self] files in
                self?.dismiss(animated: true, completion: {
                    self?.showSpinner()
                    self?.viewModel?.delete(files, then: { status in
                        self?.hideSpinner()

                        switch status {
                        case .success:
                            DispatchQueue.main.async {
                                self?.viewModel?.removeSyncedFiles(files)
                                self?.refreshCollectionView()
                                self?.dismissFloatingActionIsland()
                                self?.clearButtonWasPressed(UIButton())
                            }

                        case .error(_):
                            DispatchQueue.main.async {
                                self?.showErrorAlert(message: .deleteError) {
                                    self?.refreshCurrentFolder()
                                    self?.dismissFloatingActionIsland()
                                    self?.clearButtonWasPressed(UIButton())
                                }
                            }
                        }
                    })
                })
            },
            onLeaveShareConfirmed: nil,
            downloadHandler: { [weak self] file, completion in
                self?.viewModel?.download(
                    file,
                    onDownloadStart: {
                    },
                    onFileDownloaded: { url, error in
                        DispatchQueue.main.async {
                            completion(url, error)
                        }
                    },
                    progressHandler: nil
                )
            }
        )
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = .overFullScreen
        hostingController.modalTransitionStyle = .crossDissolve
        hostingController.view.backgroundColor = .clear
        
        present(hostingController, animated: true)
    }
    
    func showActionSheet() {
        let cameraAction = UIAlertAction(title: .takePhotoOrVideo, style: .default) { _ in self.openCamera() }
        let photoLibraryAction = UIAlertAction(title: .photoLibrary, style: .default) { _ in self.openPhotoLibrary() }
        let browseAction = UIAlertAction(title: .browse, style: .default) { _ in self.openFileBrowser() }
        let cancelAction = UIAlertAction(title: .cancel, style: .cancel, handler: nil)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addActions([cameraAction, photoLibraryAction, browseAction, cancelAction])
        
        // Configure for iPad
        if let popover = actionSheet.popoverPresentationController {
            // Present from the FAB view
            popover.sourceView = fabView
            popover.sourceRect = CGRect(x: fabView.bounds.midX, y: fabView.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = [.up, .down]
        }
        
        present(actionSheet, animated: true, completion: nil)
        viewModel?.trackEvent(action: RecordEventAction.initiateUpload)
    }
    
    func openCamera() {
        mediaRecorder.present()
    }
    
    func openPhotoLibrary() {
        var hostingController: UIHostingController<PhotoLibraryPickerView>?

        let pickerView = PhotoLibraryPickerView(
            onCompletion: { [weak self] selectedFiles in
                hostingController?.dismiss(animated: true) {
                    guard let self else {
                        return
                    }

                    guard let currentFolder = self.viewModel?.currentFolder else {
                        self.showErrorAlert(message: .cannotUpload)
                        return
                    }

                    guard selectedFiles.isEmpty == false else {
                        self.showErrorAlert(message: .cannotUpload)
                        return
                    }

                    self.processUpload(toFolder: currentFolder, selectedFiles: selectedFiles)
                }
            },
            onCancel: {
                hostingController?.dismiss(animated: true)
            }
        )

        hostingController = UIHostingController(rootView: pickerView)
        hostingController?.modalPresentationStyle = .overFullScreen
        hostingController?.view.backgroundColor = .clear

        if let hostingController {
            present(hostingController, animated: true)
        }
    }
    
    func openFileBrowser() {
        let docPicker: UIDocumentPickerViewController
        
        if #available(iOS 14.0, *) {
            docPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.item, .content], asCopy: true)
        } else {
            docPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String, kUTTypeContent as String], in: .import)
        }
        
        docPicker.delegate = self
        docPicker.allowsMultipleSelection = true
        present(docPicker, animated: true, completion: nil)
    }
    
    /// Upload destination for the Live Activity's folder card. My Files is always Private;
    /// the count is the listing on screen, which the activity adds completions to.
    private func uploadDestination(_ folder: FileModel) -> FolderInfo {
        FolderInfo(
            folderId: folder.folderId,
            folderLinkId: folder.folderLinkId,
            name: folder.name,
            itemCount: viewModel?.viewModels.count,
            isShared: false
        )
    }

    private func processUpload(toFolder folder: FileModel, forURLS urls: [URL], loadInMemory: Bool = false) {
        let folderInfo = uploadDestination(folder)

        let files = FileInfo.createFiles(from: urls, parentFolder: folderInfo, loadInMemory: loadInMemory)
        upload(files: files)
        viewModel?.trackEvent(action: RecordEventAction.submit)
    }

    private func processUpload(toFolder folder: FileModel, selectedFiles: [SelectedUploadFile], loadInMemory: Bool = false) {
        let folderInfo = uploadDestination(folder)

        let files = FileInfo.createFiles(from: selectedFiles, parentFolder: folderInfo, loadInMemory: loadInMemory)
        upload(files: files)
        viewModel?.trackEvent(action: RecordEventAction.submit)
    }
    
    private func newFolderAction() {
        guard
            let folderName = actionDialog?.fieldsInput.first,
            folderName.isNotEmpty
        else {
            return
        }

        actionDialog?.dismiss()
        createNewFolder(named: folderName)
    }
    
    func presentMetadataEditView(completion: @escaping (Bool) -> Void) {
        guard let selectedFiles = self.viewModel?.selectedFiles else { return }
        
        let hostingController = UIHostingController(rootView: MetadataEditView(viewModel: FilesMetadataViewModel(files: selectedFiles)))
        hostingController.modalPresentationStyle = .fullScreen
        
        self.present(hostingController, animated: true, completion: nil)
        
        self.dismissFloatingActionIsland()
        self.clearButtonWasPressed(UIButton())
        
        // Add a way to call the completion block when the view is dismissed.
        hostingController.rootView.dismissAction = { hasUpdates in
            hostingController.dismiss(animated: true, completion: {
                completion(hasUpdates)
            })
        }
    }
}

// MARK: - Document Picker Delegate
extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let currentFolder = viewModel?.currentFolder else {
            controller.dismiss(animated: true)
            return showErrorAlert(message: .cannotUpload)
        }

        // Dismiss the picker first, then enumerate off-main: reading attributes on iCloud Drive URLs can
        // block on file I/O and freeze the dismiss animation.
        controller.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.showSpinner()
            // Resolve the destination here, on main, where the view model's listing
            // is safe to read — not inside the background block below.
            let folderInfo = self.uploadDestination(currentFolder)
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                let files = FileInfo.createFiles(from: urls, parentFolder: folderInfo, loadInMemory: false)
                DispatchQueue.main.async {
                    self?.checkDuplicatesThenUpload(files: files, in: currentFolder) { _ in
                        self?.hideSpinner()
                    }
                    self?.viewModel?.trackEvent(action: RecordEventAction.submit)
                }
            }
        }
    }
}

// MARK: - MediaRecorderDelegate
extension MainViewController: MediaRecorderDelegate {
    func didSelect(url: URL?, isLocal: Bool) {
        guard
            let mediaUrl = url,
            let currentFolder = viewModel?.currentFolder
        else {
            return showErrorAlert(message: .cameraErrorMessage)
        }
        
        processUpload(toFolder: currentFolder, forURLS: [mediaUrl], loadInMemory: isLocal)
        
        if isLocal {
            mediaRecorder.clearTemporaryFile(withURL: mediaUrl)
        }
    }
}

// MARK: - FileActionSheetDelegate
extension MainViewController {
    func shareWithOtherApps(file: FileModel) {
        if let localURL = fileHelper.url(forFileNamed: FileHelper.recordScopedName(file.uploadFileName, recordId: file.recordId)) {
            share(url: localURL)
        } else {
            let preparingAlert = UIAlertController(title: "Preparing File..".localized(), message: nil, preferredStyle: .alert)
            preparingAlert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: { _ in
                self.viewModel?.cancelDownload() })
            )
            present(preparingAlert, animated: true) {
                self.viewModel?.download(file, onDownloadStart: { }, onFileDownloaded: { url, errorMessage in
                    if let url = url {
                        self.dismiss(animated: true) {
                            self.share(url: url)
                        }
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                }, progressHandler: nil)
            }
        }
    }
    
    private func share(url: URL) {
        viewModel?.trackEvent(action: AccountEventAction.openShareModal)
        
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // For iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }
    
    func renameAction(file: FileModel, atIndexPath indexPath: IndexPath) {
        let presentRenameView: () -> Void = { [weak self] in
            guard let self = self else { return }
            
            var hostingController: UIHostingController<RenameView>?
            
            let renameView = RenameView(
                currentName: file.name,
                isFolder: file.type.isFolder,
                thumbnailURL: file.thumbnailURL,
                onRename: { [weak self] newName in
                    hostingController?.dismiss(animated: false) {
                        self?.rename(file, newName, atIndexPath: indexPath)
                    }
                },
                onDismiss: {
                    hostingController?.dismiss(animated: false)
                }
            )
            
            hostingController = UIHostingController(rootView: renameView)
            hostingController?.modalPresentationStyle = .overFullScreen
            hostingController?.modalTransitionStyle = .crossDissolve
            hostingController?.view.backgroundColor = .clear
            
            if let controller = hostingController {
                self.present(controller, animated: false)
            }
        }
        
        // Dismiss any currently presented view controller first
        if let presented = presentedViewController {
            presented.dismiss(animated: true) {
                DispatchQueue.main.async {
                    presentRenameView()
                }
            }
        } else {
            presentRenameView()
        }
    }
    
    func deleteAction(file: FileModel, atIndexPath indexPath: IndexPath) {
        didTapDelete(forFile: file, atIndexPath: indexPath)
    }
    
    func downloadAction(file: FileModel) {
        download(file)
    }
    
    func relocateAction(files: [FileModel]?, action: FileAction) {
        viewModel?.selectedFiles = files
        viewModel?.fileAction = action

        setupBottomActionSheet()
    }
    
    func publishAction(file: FileModel) {
        didTapPublish(source: file)
    }
    
    func getPublicLinkAction(file: FileModel) {
        // Generate the public URL for the file in public workspace
        guard let publicFilesVM = viewModel as? PublicFilesViewModel,
              let publicURL = publicFilesVM.publicURL(forFile: file) else {
            return
        }
        
        // Dismiss the current menu first, then present the activity controller
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }

            let activityViewController = UIActivityViewController(
                activityItems: [publicURL], 
                applicationActivities: nil
            )
            activityViewController.popoverPresentationController?.sourceView = self.view
            self.present(activityViewController, animated: true, completion: nil)
        }
    }
    
    // MARK: - Share Management
    private func presentShareManagement(for file: FileModel) {
        let shareContainerView = ShareContainerView(fileModel: file)
        let hostingController = UIHostingController(rootView: shareContainerView)
        
        hostingController.modalPresentationStyle = UIModalPresentationStyle.pageSheet
        if #available(iOS 15.0, *) {
            hostingController.sheetPresentationController?.detents = [UISheetPresentationController.Detent.large()]
            hostingController.sheetPresentationController?.prefersGrabberVisible = false
        }
        
        present(hostingController, animated: true)
    }
    
    // MARK: - Helper Methods
    private func formatFileSize(_ size: Int64) -> String {
        size.readableFileSize
    }
}

// MARK: - SortActionSheetDelegate
extension MainViewController: SortActionSheetDelegate {
    func didSelectOption(_ option: SortOption) {
        viewModel?.activeSortOption = option
        refreshCurrentFolder()
    }
}

// MARK: - FilePreviewNavigationControllerDelegate
extension MainViewController: FilePreviewNavigationControllerDelegate {
    func filePreviewNavigationControllerWillClose(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        if hasChanges {
            refreshCurrentFolder()
        }
    }
    
    func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        if hasChanges {
            refreshCurrentFolder(shouldDisplaySpinner: false)
        }
    }
    
    func filePreviewNavigationControllerRequestsDownload(_ filePreviewNavigationVC: UIViewController, file: FileModel) {
        downloadAction(file: file)
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension MainViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Show FAB buttons when menu is dismissed
        updateFABViewVisibility()
    }
}
