//
//  SharesViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import SwiftUI
import UIKit
import Photos
import MobileCoreServices

class SharesViewController: BaseViewController<SharedFilesViewModel> {
    @IBOutlet var directoryLabel: UILabel!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var switchViewButton: UIButton!
    private let refreshControl = UIRefreshControl()
    @IBOutlet weak var bottomButtonHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var fileActionBottomView: BottomActionSheet!
    @IBOutlet var fabView: FABView!
    private lazy var mediaRecorder = MediaRecorder(presentationController: self, delegate: self)
    
    private var fileActionSheet: SharedFileActionSheet?
    
    private let overlayView = UIView()
    let fileHelper = FileHelper()
    let documentInteractionController = UIDocumentInteractionController()
    
    var selectedIndex: Int = 0
    
    var selectedFileId: Int?
    
    var fileType: FileType?
    var sharedFolderArchiveNo: String = ""
    var sharedFolderLinkId: Int = -1
    var sharedFolderName: String = ""
    var sharedRecordId: Int = -1
    var shareThumbnailURL: String?
    var shareAccessRole: String?

    var getSharesRequest: ((@escaping ServerResponse) -> Void)?
    var navigateMinRequest: ((NavigateMinParams, Bool, @escaping ServerResponse) -> Void)?
    var changeArchiveRequest: ((Int, String, @escaping (Bool) -> Void) -> Void)?
    
    private var isGridView = false
    private var sortActionSheet: SortActionSheet?
    private var sharesRefreshRequestId = UUID()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = SharedFilesViewModel()
        viewModel?.trackOpenFiles()
        
        let hasSavedFile = checkSavedFile()
        let hasSavedFolder = checkSavedFolder()
        
        configureUI()
        setupCollectionView()
        setupBottomActionSheet()
        
        fabView.delegate = self
        
        if !hasSavedFolder && !hasSavedFile {
            getShares()
            if let fileType = fileType {
                self.fileType = nil
                if fileType.isFolder {
                    let navigateParams: NavigateMinParams = (sharedFolderArchiveNo, sharedFolderLinkId, nil)
                    navigateToFolder(withParams: navigateParams, backNavigation: false, shouldDisplaySpinner: true, then: {
                        self.backButton.isHidden = false
                        self.directoryLabel.text = self.sharedFolderName
                    })
                } else {
                    let sharedFile = ShareNotificationPayload(name: sharedFolderName, recordId: sharedRecordId, folderLinkId: sharedFolderLinkId, archiveNbr: sharedFolderArchiveNo, type: FileType.image.rawValue, toArchiveId: viewModel?.currentArchive?.archiveID ?? -1, toArchiveNbr: viewModel?.currentArchive?.archiveNbr ?? "", toArchiveName: viewModel?.currentArchive?.fullName ?? "", accessRole: shareAccessRole ?? "viewer")
                    self.presentFileDetails(sharedFile: sharedFile, sharedFileThumbnailURL: shareThumbnailURL)
                }
            }
        }
        
        NotificationCenter.default.addObserver(forName: UploadManager.didRefreshQueueNotification, object: nil, queue: nil) { [weak self] notif in
            if (self?.viewModel?.refreshUploadQueue() ?? false) && (self?.viewModel?.queueItemsForCurrentFolder.count ?? 0 > 0) {
                self?.refreshCollectionView()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UploadOperation.uploadFinishedNotification, object: nil, queue: nil) { [weak self] notif in
            guard let operation = notif.object as? UploadOperation else { return }
            // if the upload is in this screen's list, refresh the list of models
            if self?.viewModel?.currentFolder?.folderLinkId == operation.file.folder.folderLinkId {
                if (notif.userInfo?["error"] == nil), let uploadedFile = operation.uploadedFile {
                    self?.viewModel?.uploadQueue.removeAll(where: { $0 == operation.file })
                    let newModel = FileModel(model: uploadedFile, archiveThumbnailURL: "", permissions: [], accessRole: self?.viewModel?.currentFolder?.accessRole ?? .viewer)
                    let alreadyExists = self?.viewModel?.viewModels.contains(where: {
                        $0.folderLinkId == newModel.folderLinkId && $0.name == newModel.name
                    }) ?? false
                    if !alreadyExists {
                        self?.viewModel?.viewModels.insert(newModel, at: 0)
                    }
                    self?.refreshCollectionView()
                    
                    if let queueUploadCount = self?.viewModel?.queueItemsForCurrentFolder.count,
                        queueUploadCount == 0 {
                        self?.viewModel?.timer = Timer.scheduledTimer(timeInterval: 9, target: self as Any, selector: #selector(self?.timerActions), userInfo: nil, repeats: true)
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
            self?.viewModel?.viewModels[index].fileStatus = shareLinkVM.fileViewModel.fileStatus
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
        
        NotificationCenter.default.addObserver(forName: SharedFilesViewModel.didSelectFilesNotifName, object: nil, queue: nil) { [weak self] notif in
            guard let showFloatingIsland = notif.userInfo?["showFloatingIsland"] as? Bool else { return }
            if showFloatingIsland {
                self?.setupBottomActionSheetForMultipleFiles()
            } else {
                self?.dismissFloatingActionIsland()
            }
        }

        NotificationCenter.default.addObserver(forName: ArchivesViewModel.didChangeArchiveNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self = self else { return }

            self.viewModel?.navigationStack.removeAll()
            self.viewModel?.selectedFiles = []
            self.viewModel?.fileAction = .none

            if let listType = ShareListType(rawValue: self.segmentedControl.selectedSegmentIndex) {
                self.viewModel?.shareListType = listType
            }

            self.fileActionBottomView.isHidden = true
            self.fabView.setVisibility(hidden: true)
            self.backButton.isHidden = true
            self.directoryLabel.text = "Shares".localized()
            self.collectionView.setContentOffset(.zero, animated: false)
            self.refreshControl.endRefreshing()

            // Only fetch if this screen is actually on screen. Fetching while hidden is what made
            // the list render blank: the archive switch auto-dismisses the settings sheet, so Shares
            // reappears at the same time as the response lands, and a `reloadData()` that runs with
            // no window leaves its cells un-laid-out. Racing that transition is unwinnable, so don't
            // enter it — `loadedArchiveId` still points at the previous archive, which makes
            // `syncSharesForCurrentArchive` fetch on the way in, with a spinner, on a screen that is
            // already visible.
            guard self.viewIfLoaded?.window != nil else { return }
            self.getShares(shouldShowSpinner: true)
        }
        
        NotificationCenter.default.addObserver(forName: SettingsRouter.showMemberChecklistNotifName, object: nil, queue: nil) { [weak self] _ in
            self?.didTapChecklist()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        overlayView.frame = view.bounds

        // The view can return to a window without an appear callback (non-fullscreen sheet
        // dismissal), but layout always runs — so flush any relayout deferred from an off-window
        // reload here. See `loadedArchiveId` for why this is checked rather than assumed.
        if needsCollectionViewReloadOnAppear, viewIfLoaded?.window != nil {
            needsCollectionViewReloadOnAppear = false
            collectionView.reloadData()
            configureCollectionViewBgView()
        }
    }
    
    fileprivate func configureUI() {
        navigationItem.title = .shares
        view.backgroundColor = .backgroundPrimary
        
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: TextFontStyle.style11.font], for: .selected)
        segmentedControl.setTitleTextAttributes([.font: TextFontStyle.style8.font], for: .normal)
        segmentedControl.setTitle(.sharedByMe, forSegmentAt: 0)
        segmentedControl.setTitle(.sharedWithMe, forSegmentAt: 1)
        
        if let listType = ShareListType(rawValue: selectedIndex) {
            segmentedControl.selectedSegmentIndex = selectedIndex
            viewModel?.shareListType = listType
        }
        segmentedControl.selectedSegmentTintColor = .primary
        
        directoryLabel.font = TextFontStyle.style3.font
        directoryLabel.textColor = .primary
        backButton.tintColor = .primary
        backButton.isHidden = true
        
        fileActionBottomView.isHidden = true
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
        styleNavBar()
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
    
    fileprivate func configureCollectionViewBgView() {
        if let items = viewModel?.viewModels, items.isEmpty {
            // The two segments need different copy: "you haven't shared anything" is wrong when the
            // user is looking at what OTHERS have shared with them.
            let isSharedWithMe = viewModel?.shareListType == .sharedWithMe
            let emptyView = EmptyFolderView(title: isSharedWithMe ? .shareWithMeActionMessage : .shareActionMessage,
                                            image: .shares)
            emptyView.frame = collectionView.bounds
            collectionView.backgroundView = emptyView
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    /// The archive the currently displayed shares were loaded for, and whether the last reload ran
    /// while this screen was off-window.
    ///
    /// Two separate failures produced the same "blank Shares list, not even an empty-state message"
    /// report, and both are lifecycle-dependent, so both are handled by checking state on the way in
    /// rather than by trusting a notification to arrive at a convenient moment:
    ///
    /// - The archive-change refresh lands while the archives sheet covers Shares, so `reloadData()`
    ///   runs on a collection view with no window and its cells are never laid out. A device trace
    ///   showed `viewModels=3 cvItems=3 bgViewNil=true` on a screen rendering nothing — and
    ///   `bgViewNil` is why there was no message either: the data was not empty, so the empty view
    ///   was correctly absent.
    /// - Whether `viewWillAppear` even fires on the way back depends on how the sheet was dismissed
    ///   and on its presentation style, so a flag set at notification time can be missed entirely.
    ///
    /// Comparing `loadedArchiveId` against the session is immune to both: if what is on screen
    /// belongs to a different archive than the one now selected, it is refetched, no matter which
    /// lifecycle callbacks ran. `viewDidLayoutSubviews` flushes a pending relayout for the case
    /// where the view returns to a window without an appear callback.
    private var loadedArchiveId: Int?
    private var needsCollectionViewReloadOnAppear = false

    private var sessionArchiveId: Int? {
        AuthenticationManager.shared.session?.selectedArchive?.archiveID
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncSharesForCurrentArchive()
    }

    /// Refetch if the displayed shares belong to a different archive than the selected one;
    /// otherwise just make sure the layout is current.
    private func syncSharesForCurrentArchive() {
        guard viewModel != nil else { return }

        if loadedArchiveId != sessionArchiveId {
            getShares(shouldShowSpinner: true)
        } else if needsCollectionViewReloadOnAppear {
            needsCollectionViewReloadOnAppear = false
            collectionView.reloadData()
            configureCollectionViewBgView()
        }
    }

    fileprivate func refreshCollectionView(_ completion: (() -> ())? = nil) {
        collectionView.reloadData()
        configureCollectionViewBgView()
        // A reload that ran on-screen supersedes any pending one, hence the plain assignment.
        needsCollectionViewReloadOnAppear = viewIfLoaded?.window == nil
        completion?()
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
                
                self?.relocate(files: selectedFiles, to: destination)
            },
        ]
        if #available(iOS 26, *) {
            rightItems.append(FloatingActionImageItem(image: UIColor.clear.imageWithColor(width: 0, height: 0), action: nil))
        }
        rightItems.append(FloatingActionImageItem(image: closeImage) { [weak self] vc, item in
            self?.dismissFloatingActionIsland()
            self?.updateFAB()

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
                    
                    self?.updateFAB()
                    if let backButtonIsHidden = self?.backButton.isHidden, !backButtonIsHidden {
                        self?.backButton.isUserInteractionEnabled = true
                        self?.backButton.layer.opacity = 1
                    }
                    
                    self?.viewModel?.isSelecting = false
                    self?.setupBottomActionSheet()
                })
            }),
            FloatingActionImageItem(image: blankImage, action: nil),
            FloatingActionImageItem(image: UIImage(named: "floatingMove")!, action: {
                [weak self] _,_  in
                self?.dismissFloatingActionIsland({ [weak self] in
                    self?.viewModel?.fileAction = FileAction.move
                    self?.relocateAction(files: self?.viewModel?.selectedFiles, action: .move)
                    
                    self?.updateFAB()
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
        let shouldDisableButton = viewModel?.selectedFiles?.first?.parentFolderId == viewModel?.currentFolder?.folderId && action == .move

        if let currentFolderPermissions = viewModel?.currentFolder?.permissions,
            currentFolderPermissions.contains(.upload) == true {
            fileActionBottomView.toggleActionButton(enabled: true)
        } else {
            fileActionBottomView.toggleActionButton(enabled: false)
        }
        
        fileActionBottomView.toggleActionButton(enabled: !shouldDisableButton)
    }
    
    /// Internal (not private) so tests can assert the permission gate directly.
    func updateFAB() {
        let currentFolderPermissions = viewModel?.currentFolder?.permissions
        
        viewModel?.showMemberChecklist({ [weak self]  showChecklist in
            self?.fabView.showsChecklistButton = showChecklist ?? false
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
                self?.bottomButtonHeightConstraint.constant = showChecklist ?? false ? 140 : 64
                self?.view.layoutIfNeeded()
            })
        })

        var shouldShowFAB = currentFolderPermissions?.contains(.create) == true
            && currentFolderPermissions?.contains(.upload) == true
        if !fileActionBottomView.isHidden { shouldShowFAB = false }
        // Multi-select owns the screen while active; restore paths route through this gate.
        if viewModel?.isSelecting == true { shouldShowFAB = false }
        // Hide the create/upload FAB (and its checklist sub-button) while picking a copy/move
        // destination — you're choosing where to paste, not adding new files here.
        if viewModel?.isSelectingDestination == true { shouldShowFAB = false }

        // setVisibility fades the buttons back in (see FABView) — hiding them for paste mode
        // created a real hide→show transition that used to not exist.
        fabView.setVisibility(hidden: !shouldShowFAB)
    }

    private func performChangeArchive(withArchiveId archiveId: Int, archiveNbr: String, completion: @escaping (Bool) -> Void) {
        if let changeArchiveRequest {
            changeArchiveRequest(archiveId, archiveNbr, completion)
        } else {
            viewModel?.changeArchive(withArchiveId: archiveId, archiveNbr: archiveNbr, completion: completion)
        }
    }
    
    func checkSavedFile() -> Bool {
        var hasSavedFile = false
        if let sharedFile: ShareNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.sharedFileKey) {
            hasSavedFile = true
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.sharedFileKey)
            
            selectedIndex = ShareListType.sharedWithMe.rawValue
            
            let currentArchive: ArchiveVOData? = viewModel?.currentArchive
            if currentArchive?.archiveNbr != sharedFile.toArchiveNbr {
                let action = { [weak self] in
                    self?.actionDialog?.dismiss()
                    
                    self?.performChangeArchive(withArchiveId: sharedFile.toArchiveId, archiveNbr: sharedFile.toArchiveNbr, completion: { success in
                        if success {
                            self?.getShares {
                                self?.presentFileDetails(sharedFile: sharedFile)
                            }
                        }
                    })
                }
                
                let title = "Switch to The <ARCHIVE_NAME> Archive?".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: sharedFile.toArchiveName)
                let description = "In order to access this content you need to switch to The <ARCHIVE_NAME> Archive.".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: sharedFile.toArchiveName)
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
                getShares {
                    self.presentFileDetails(sharedFile: sharedFile)
                }
            }
        }
        
        return hasSavedFile
    }
    
    func checkSavedFolder() -> Bool {
        var hasSavedFolder = false
        if let sharedFolder: ShareNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.sharedFolderKey) {
            hasSavedFolder = true
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.sharedFolderKey)
            
            selectedIndex = ShareListType.sharedWithMe.rawValue
            
            let navigationParams = (archiveNo: sharedFolder.archiveNbr, folderLinkId: sharedFolder.folderLinkId, folderName: sharedFolder.name)
            
            let currentArchive: ArchiveVOData? = viewModel?.currentArchive
            if currentArchive?.archiveNbr != sharedFolder.toArchiveNbr {
                let action = { [weak self] in
                    self?.actionDialog?.dismiss()
                    
                    self?.performChangeArchive(withArchiveId: sharedFolder.toArchiveId, archiveNbr: sharedFolder.toArchiveNbr, completion: { success in
                        if success {
                            self?.getShares {
                                self?.navigateToFolder(withParams: navigationParams, backNavigation: false) {
                                    self?.backButton.isHidden = false
                                    self?.directoryLabel.text = navigationParams.folderName
                                }
                            }
                        }
                    })
                    
                    self?.actionDialog = nil
                }
                
                let title = "Switch to The <ARCHIVE_NAME> Archive?".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: sharedFolder.toArchiveName)
                let description = "In order to access this content you need to switch to The <ARCHIVE_NAME> Archive.".localized().replacingOccurrences(of: "<ARCHIVE_NAME>", with: sharedFolder.toArchiveName)
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
                getShares { [self] in
                    navigateToFolder(withParams: navigationParams, backNavigation: false) {
                        self.backButton.isHidden = false
                        self.directoryLabel.text = navigationParams.folderName
                    }
                }
            }
        }
        
        return hasSavedFolder
    }
    
    func refreshCurrentFolder(shouldDisplaySpinner: Bool = true, silenceErrors: Bool = false, then handler: VoidAction? = nil) {
        guard let viewModel = viewModel else { return }

        if let currentFolder = viewModel.currentFolder {
            let params: NavigateMinParams = (currentFolder.archiveNo, currentFolder.folderLinkId, nil)

            // Back navigation set to `true` so it's not considered a in-depth navigation.
            navigateToFolder(withParams: params, backNavigation: true, shouldDisplaySpinner: shouldDisplaySpinner, silenceErrors: silenceErrors, then: handler)
        } else {
            getShares(shouldShowSpinner: false, completion: handler)
        }
    }
    
    func presentFileDetails(sharedFile: ShareNotificationPayload, sharedFileThumbnailURL: String? = nil) {
        let currentArchive: ArchiveVOData? = viewModel?.currentArchive
        let permissions = ArchiveVOData.permissions(forAccessRole: sharedFile.accessRole)
        let fileVM = FileModel(name: sharedFile.name, recordId: sharedFile.recordId, folderLinkId: sharedFile.folderLinkId, archiveNbr: sharedFile.archiveNbr, type: sharedFile.type, permissions: permissions, thumbnailURL2000: sharedFileThumbnailURL)
        let filePreviewVC = UIViewController.create(withIdentifier: .filePreview, from: .main) as! FilePreviewViewController
        filePreviewVC.file = fileVM
        
        // Add close action for modal presentation
        filePreviewVC.closeAction = { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        
        let fileDetailsNavigationController = FilePreviewNavigationController(rootViewController: filePreviewVC)
        fileDetailsNavigationController.filePreviewNavDelegate = self
        fileDetailsNavigationController.modalPresentationStyle = .fullScreen
        present(fileDetailsNavigationController, animated: true)
        
        // This has to be done after presentation, filePreviewVC has to have it's view loaded
        filePreviewVC.loadVM()
    }
    
    @objc private func pullToRefreshAction() {
        refreshCurrentFolder(
            shouldDisplaySpinner: false,
            silenceErrors: true,
            then: {
                self.refreshControl.endRefreshing()
            }
        )
        viewModel?.invalidateTimer()
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        guard let listType = ShareListType(rawValue: sender.selectedSegmentIndex) else {
            return
        }
        
        self.directoryLabel.text = "Shares".localized()
        self.backButton.isHidden = true
        self.fabView.setVisibility(hidden: true)
        self.fileActionBottomView.isHidden = true
        
        viewModel?.shareListType = listType
        refreshCollectionView()
        
        viewModel?.fileAction = .none
        viewModel?.selectedFiles = []
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        let fileTypeString: String = FileType(rawValue: self.viewModel?.selectedFiles?.first?.type.rawValue ?? "")?.isFolder ?? false ? "folder" : "file"
        if let navigationStackCount = viewModel?.navigationStack.count,
            navigationStackCount <= 1 && viewModel?.fileAction != FileAction.none {
            showActionDialog(
                styled: .simpleWithDescription,
                withTitle: "Cancel Move?".localized(),
                description: "Moving files or folders outside of the shared folder in which they are currently located is not permitted at this time. You can cancel this move action or continue to choose a destination for the selected \(fileTypeString).".localized(),
                positiveButtonTitle: "Continue".localized(),
                positiveAction: { [weak self] in
                    self?.actionDialog?.dismiss()
                    self?.viewModel?.fileAction = .none
                    self?.viewModel?.selectedFiles = []
                    self?.backButtonAction(UIButton())
                    self?.dismiss(animated: false)
                    
                    self?.dismissFloatingActionIsland()
                    self?.viewModel?.selectedFiles = []
                    self?.viewModel?.fileAction = .none
                    self?.viewModel?.isSelectingDestination = false
                },
                cancelButtonTitle: "Cancel Move".localized(),
                cancelButtonColor: .gray,
                overlayView: overlayView
            )
        } else {
            guard
                let viewModel = viewModel,
                let _ = viewModel.removeCurrentFolderFromHierarchy()
            else {
                return
            }
            
            if let destinationFolder = viewModel.currentFolder {
                let navigateParams: NavigateMinParams = (destinationFolder.archiveNo, destinationFolder.folderLinkId, nil)
                navigateToFolder(withParams: navigateParams, backNavigation: true, then: {
                    self.directoryLabel.text = destinationFolder.name
                    
                    // If we got to the root, hide the back button.
                    if viewModel.currentFolderIsRoot {
                        self.backButton.isHidden = true
                    }
                })
            } else {
                getShares()
            }
        }
    }
    
    @objc private func timerActions() {
        pullToRefreshAction()
        viewModel?.updateTimerCount()
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
        // Restore the FAB through the permission gate, never unconditionally: leaving
        // select mode in a folder you can only view must NOT conjure the create/upload
        // button (the gate reads isSelecting, so this must run after the reset above).
        updateFAB()
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
    
    @objc private func headerButtonAction(_ sender: UIButton) {
        showSortActionSheetDialog()
    }
    
    @objc private func cancelAllUploadsAction(_ sender: UIButton) {
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

    func showSortActionSheetDialog() {
        // Safety measure, in case the user taps to show sheet, but the previously shown one
        // has not finished dimissing and being deallocated.
        guard fileActionSheet == nil else { return }
        
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
    
    private func generateMenuItems(for file: FileModel, atIndexPath indexPath: IndexPath) -> [FileMenuViewModel.MenuItem] {
        var menuItems: [FileMenuViewModel.MenuItem] = []
        
        if file.permissions.contains(.share) {
            if file.permissions.contains(.ownership) {
                menuItems.append(FileMenuViewModel.MenuItem(type: .shareToPermanent, action: nil))
            }
        }
        
        // Share to another app - for files with share permission (not folders)
        if file.permissions.contains(.share) && file.type.isFolder == false {
            menuItems.append(FileMenuViewModel.MenuItem(type: .shareToAnotherApp, action: { [self] in
                shareWithOtherApps(file: file)
            }))
        }

        if file.permissions.contains(.edit) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .rename, action: { [self] in
                renameAction(file: file, atIndexPath: indexPath)
            }))
        }
        
        if file.permissions.contains(.read) && file.type.isFolder == false {
            menuItems.append(FileMenuViewModel.MenuItem(type: .download, action: { [self] in
                downloadAction(file: file)
            }))
        }
        
        if let currentFolderIsRoot = viewModel?.currentFolderIsRoot, file.permissions.contains(.create) && !currentFolderIsRoot {
            menuItems.append(FileMenuViewModel.MenuItem(type: .copy, action: { [self] in
                relocateAction(files: [file], action: .copy)
            }))
        }
        
        if let currentFolderIsRoot = viewModel?.currentFolderIsRoot, file.permissions.contains(.move) && !currentFolderIsRoot {
            menuItems.append(FileMenuViewModel.MenuItem(type: .move, action: { [self] in
                relocateAction(files: [file], action: .move)
            }))
        }
        
        // Add unshare (leave share) or delete as the last item with separator
        if let currentFolderIsRoot = viewModel?.currentFolderIsRoot, currentFolderIsRoot && self.segmentedControl.selectedSegmentIndex == 1 {
            menuItems.append(FileMenuViewModel.MenuItem(type: .unshare, action: { [self] in
                unshareAction(file: file, atIndexPath: indexPath)
            }))
        } else if file.permissions.contains(.delete) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .delete, action: { [self] in
                deleteAction(file: file, atIndexPath: indexPath)
            }))
        }
        
        return menuItems
    }
    
    private func updateFileModelInDataSource(_ updatedFile: FileModel) {
        guard let viewModel = self.viewModel else { return }
        
        if viewModel.shareListType == .sharedByMe {
            if let index = viewModel.sharedByMeViewModels.firstIndex(where: { $0.recordId == updatedFile.recordId && $0.folderLinkId == updatedFile.folderLinkId }) {
                viewModel.sharedByMeViewModels[index] = updatedFile
                if let activeIndex = viewModel.viewModels.firstIndex(where: { $0.recordId == updatedFile.recordId && $0.folderLinkId == updatedFile.folderLinkId }) {
                    viewModel.viewModels[activeIndex] = updatedFile
                }
            }
        } else {
            if let index = viewModel.sharedWithMeViewModels.firstIndex(where: { $0.recordId == updatedFile.recordId && $0.folderLinkId == updatedFile.folderLinkId }) {
                viewModel.sharedWithMeViewModels[index] = updatedFile
                if let activeIndex = viewModel.viewModels.firstIndex(where: { $0.recordId == updatedFile.recordId && $0.folderLinkId == updatedFile.folderLinkId }) {
                    viewModel.viewModels[activeIndex] = updatedFile
                }
            }
        }
    }
    
    func showFileActionSheet(file: FileModel, atIndexPath indexPath: IndexPath) {
        let menuItems = generateMenuItems(for: file, atIndexPath: indexPath)
        
        // Determine if we should show archive info (only in Shared With Me tab, and at root level)
        let isSharedWithMe = viewModel?.shareListType == .sharedWithMe
        let isAtRootLevel = viewModel?.currentFolderIsRoot ?? true
        let shouldShowArchiveInfo = isSharedWithMe && isAtRootLevel
        
        let swiftUIView = FileMoreMenuView(
            fileViewModel: file,
            menuItems: menuItems,
            showArchiveInfo: shouldShowArchiveInfo,
            onDismiss: { [weak self] in
                self?.dismiss(animated: true)
            },
            onShareManagementRequested: { [weak self] file in
                self?.dismiss(animated: true, completion: {
                    self?.presentShareManagement(for: file)
                })
            },
            onRenameRequested: { [weak self] file in
                // TODO: Implement rename functionality
                self?.dismiss(animated: true, completion: {
                    // Rename action will be implemented here
                })
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
                            
                        case .error(let message):
                            self?.showErrorAlert(message: message)
                        }
                    })
                })
            },
            onLeaveShareConfirmed: { [weak self] file in
                self?.dismiss(animated: true, completion: {
                    self?.showSpinner()
                    self?.viewModel?.unshare(file, then: { status in
                        self?.hideSpinner()
                        
                        switch status {
                        case .success:
                            DispatchQueue.main.async {
                                self?.viewModel?.removeSyncedFiles([file])
                                self?.refreshCollectionView()
                            }
                            
                        case .error(let message):
                            self?.showErrorAlert(message: message)
                        }
                    })
                })
            },
            downloadHandler: { [weak self] file, completion in
                self?.viewModel?.download(
                    file,
                    onDownloadStart: {
                        // No specific action needed
                    },
                    onFileDownloaded: { url, error in
                        DispatchQueue.main.async {
                            completion(url, error)
                        }
                    },
                    progressHandler: nil
                )
            },
            menuItemsGenerator: { [weak self] updatedFile in
                guard let self = self else { return [] }
                return self.generateMenuItems(for: updatedFile, atIndexPath: indexPath)
            },
            fileModelUpdateHandler: { [weak self] (updatedFile: FileModel) in
                self?.updateFileModelInDataSource(updatedFile)
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
        
        let isNotAtRootLevel = !(viewModel?.currentFolderIsRoot ?? true)
        if file.permissions.contains(.edit) && isNotAtRootLevel {
            let hasFolder = viewModel?.selectedFiles?.contains(where: { $0.type.isFolder }) ?? false
            let hasEditorOrHigherRole = file.accessRole.rawValue <= AccessRole.editor.rawValue
            if !hasFolder && hasEditorOrHigherRole {
                menuItems.append(FileMenuViewModel.MenuItem(type: .editMetadata, action: { [weak self] in
                    self?.presentMetadataEditView { hasUpdates in
                        if hasUpdates {
                            self?.refreshShares()
                        }
                    }
                }))
            }
        }
        
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
        
        if file.permissions.contains(.move) {
            menuItems.append(FileMenuViewModel.MenuItem(type: .move, action: { [weak self] in
                self?.dismissFloatingActionIsland({ [weak self] in
                    self?.viewModel?.fileAction = FileAction.move
                    self?.relocateAction(files: self?.viewModel?.selectedFiles, action: .move)
                    
                    self?.updateFAB()
                    if let backButtonIsHidden = self?.backButton.isHidden, !backButtonIsHidden {
                        self?.backButton.isUserInteractionEnabled = true
                        self?.backButton.layer.opacity = 1
                    }
                    
                    self?.viewModel?.isSelecting = false
                    self?.setupBottomActionSheet()
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
                self?.dismiss(animated: true, completion: {
                    self?.presentShareManagement(for: file)
                })
            },
            onRenameRequested: { [weak self] file in
                // TODO: Implement rename functionality
                self?.dismiss(animated: true, completion: {
                    // Rename action will be implemented here
                })
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
                            
                        case .error(let message):
                            self?.showErrorAlert(message: message)
                        }
                    })
                })
            },
            onLeaveShareConfirmed: { [weak self] file in
                self?.dismiss(animated: true, completion: {
                    self?.showSpinner()
                    self?.viewModel?.unshare(file, then: { status in
                        self?.hideSpinner()
                        
                        switch status {
                        case .success:
                            DispatchQueue.main.async {
                                self?.viewModel?.removeSyncedFiles([file])
                                self?.refreshCollectionView()
                            }
                            
                        case .error(let message):
                            self?.showErrorAlert(message: message)
                        }
                    })
                })
            },
            downloadHandler: { [weak self] file, completion in
                self?.viewModel?.download(
                    file,
                    onDownloadStart: {
                        // No specific action needed
                    },
                    onFileDownloaded: { url, error in
                        DispatchQueue.main.async {
                            completion(url, error)
                        }
                    },
                    progressHandler: nil
                )
            },
            fileModelUpdateHandler: { [weak self] (updatedFile: FileModel) in
                // Update the file in the data source when its role/permissions change
                self?.updateFileModelInDataSource(updatedFile)
            }
        )
        
        let hostingController = UIHostingController(rootView: swiftUIView)
        hostingController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        hostingController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        hostingController.view.backgroundColor = UIColor.clear
        
        present(hostingController, animated: true)
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
    
    func unshareAction(file: FileModel, atIndexPath indexPath: IndexPath) {
        didTapUnshare(forFile: file, atIndexPath: indexPath)
    }
    
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
        let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        
        // For iPad support
        if let popover = activityViewController.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
            popover.permittedArrowDirections = []
        }
        
        present(activityViewController, animated: true)
    }

    fileprivate func getShares(shouldShowSpinner: Bool = true, completion: (() -> Void)? = nil) {
        if shouldShowSpinner {
            showSpinner()
        }
        
        fabView.setVisibility(hidden: true)

        let runRequest: (@escaping ServerResponse) -> Void = getSharesRequest ?? { [weak self] handler in
            self?.viewModel?.getShares(then: handler)
        }

        let requestId = UUID()
        sharesRefreshRequestId = requestId

        runRequest({ status in
            guard self.sharesRefreshRequestId == requestId else { return }

            self.hideSpinner()
            switch status {
            case .success:
                // Stamp what is now on screen, so `syncSharesForCurrentArchive` can tell whether it
                // still matches the selected archive. Only on success: a failed refresh leaves the
                // previous archive's data visible, and claiming otherwise would suppress the retry.
                self.loadedArchiveId = self.sessionArchiveId
                self.refreshCollectionView {
                    self.scrollToFileIfNeeded()
                    
                    self.directoryLabel.text = "Shares".localized()
                    self.backButton.isHidden = true
                    if let rootFolder = self.viewModel?.currentFolderIsRoot, rootFolder {
                        self.fileActionBottomView.isHidden = true
                    }
                }
                
            case .error(let message):
                self.showErrorAlert(message: message)
            }
            
            if let completion = completion {
                completion()
            }
        })
    }

    private func download(_ file: FileModel) {
        viewModel?.download(file, onDownloadStart: {
            DispatchQueue.main.async {
                self.refreshCollectionView()
            }
        }, onFileDownloaded: { url, error in
            DispatchQueue.main.async {
                self.onFileDownloaded(url: url, name: file.name, error: error)
            }
        }, progressHandler: { progress in
            DispatchQueue.main.async {
                self.handleProgress(forFile: file, withValue: progress)
            }
        })
    }
    
    fileprivate func onFileDownloaded(url: URL?, name: String?, error: Error?) {
        self.refreshCollectionView()
        
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
                self.floatingActionIsland?.hideActivityIndicator()

                switch status {
                case .success:
                    // Refetch instead of inserting the SOURCE models: a copy creates a
                    // NEW record server-side, so the inserted row would carry the
                    // ORIGINAL's ids — deleting/renaming "the copy" would hit the
                    // original record (data loss). A move can change link ids too.
                    self.floatingActionIsland?.showDoneCheckmark() {
                        self.dismissFloatingActionIsland({ [weak self] in
                            self?.fabView?.setVisibility(hidden: false)
                            self?.viewModel?.isSelectingDestination = false
                            // Fully exit selection mode after the paste (parity with
                            // MainViewController) — otherwise checkboxes can reappear.
                            self?.viewModel?.isSelecting = false

                            self?.refreshCurrentFolder(shouldDisplaySpinner: false)
                        })
                    }
                    
                case .error(let message):
                    self.dismissFloatingActionIsland()
                    self.showErrorAlert(message: message)
                }
            })
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
    
    private func didTapUnshare(forFile file: FileModel, atIndexPath indexPath: IndexPath) {
        let title = String(format: "\(String("Unshare").localized()) \"%@\"?", file.name)
        
        self.showActionDialog(
            styled: .simple,
            withTitle: title,
            positiveButtonTitle: "Unshare".localized(),
            positiveAction: {
                self.actionDialog?.dismiss()
                self.unshareFile(file, atIndexPath: indexPath)
            }, positiveButtonColor: .brightRed,
            cancelButtonColor: .primary,
            overlayView: self.overlayView
        )
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
                
            case .error(let message):
                self.showErrorAlert(message: message)
            }
        })
    }
    
    func unshareFile(_ file: FileModel, atIndexPath indexPath: IndexPath) {
        showSpinner()
        viewModel?.unshare(file, then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.viewModel?.removeSyncedFiles([file])
                    self.refreshCollectionView()
                }
                
            case .error(let message):
                self.showErrorAlert(message: message)
            }
        })
    }
    
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
                collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
                let currentFile = viewModel?.viewModels[indexPath.row] ?? file
                showFileActionSheet(file: currentFile, atIndexPath: indexPath)
            }

        case .downloading:
            viewModel?.cancelDownload()
            
            if let index = viewModel?.viewModels.firstIndex(where: { $0.recordId == file.recordId }) {
                viewModel?.viewModels[index].fileStatus = .synced
            }
            
            collectionView.reloadData()
            
        case .uploading, .waiting, .failed:
            viewModel?.removeFromQueue(indexPath.row)
            
            if viewModel?.refreshUploadQueue() == true {
                refreshCollectionView()
            }
        }
    }
    
    private func handleProgress(forFile file: FileModel, withValue value: Float) {
        // Downloads are a serial FIFO in the downloads section (0), so the active item is always
        // at row 0. The previous lookup used the file's index in `viewModels` (the synced
        // section), which pointed at the wrong cell — or none. Mirror MainViewController.
        guard let downloadingCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FileCollectionViewCell
        else {
            return
        }

        downloadingCell.updateProgress(withValue: value)
    }

    public func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, shouldDisplaySpinner: Bool = true, silenceErrors: Bool = false, then handler: VoidAction? = nil) {
        shouldDisplaySpinner ? showSpinner() : nil

        let runRequest: (NavigateMinParams, Bool, @escaping ServerResponse) -> Void = navigateMinRequest ?? { [weak self] requestParams, requestBackNavigation, completion in
            self?.viewModel?.navigateMin(params: requestParams, backNavigation: requestBackNavigation, then: completion)
        }

        runRequest(params, backNavigation, { status in
            self.onFilesFetchCompletion(status, silenceErrors: silenceErrors)
            handler?()
        })
        viewModel?.timer?.invalidate()
    }

    private func onFilesFetchCompletion(_ status: RequestStatus, silenceErrors: Bool = false) {
        DispatchQueue.main.async {
            self.hideSpinner()
        }

        switch status {
        case .success:
            DispatchQueue.main.async {
                self.refreshCollectionView()

                self.updateFAB()
                self.setupBottomActionSheet()
            }

        case .error(let message):
            if !silenceErrors {
                showErrorAlert(message: message)
            }
        }
    }
    
    private func upload(files: [FileInfo], completion: ((Bool) -> Void)? = nil) {
        viewModel?.uploadFiles(files, completion: completion)
    }

    /// Guard 0: same semantics as `MainViewController.checkDuplicatesThenUpload`.
    /// See that doc-comment for full behaviour notes.
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
                    self.refreshCurrentFolder()
                    self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "Folder successfully created".localized())
                }

            case .error(_):
                self.view.showNotificationBanner(title: .errorMessage, backgroundColor: .deepRed, textColor: .white)
            }
        })
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension SharesViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
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
        let pendingInvitationCount = pendingInvitationBadgeCount(for: file)
        cell.setMoreButtonBadgeCount(cell.moreButton.isHidden ? 0 : pendingInvitationCount)
        
        cell.rightButtonTapAction = { _ in
            self.handleCellRightButtonAction(for: file, atIndexPath: indexPath)
        }
        
        return cell
    }

    private func pendingInvitationBadgeCount(for file: FileModel) -> Int {
        file.minArchiveVOS.filter {
            ArchiveVOData.Status(rawValue: $0.shareStatus) == .pending
        }.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let listItemHeight: CGFloat = 70  // Consistent height for all list items
        let gridItemHeight: CGFloat = UIScreen.main.bounds.width / 2 + 50
        
        let listItemSize = CGSize(width: UIScreen.main.bounds.width, height: listItemHeight)
        // Horizontal layout: |-6-cell-6-cell-6-|. 6*3/2 = 9
        // Vertical size: 30 is the height of the title label
        let gridItemSize = CGSize(width: UIScreen.main.bounds.width / 2 - 9, height: gridItemHeight)
        
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

        // Paste-destination mode is navigation-only (same rationale as MainViewController):
        // tap a folder to drill into it; items can't be (re)selected while the relocate
        // selection is fixed to the items being copied/moved.
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
                // Seed the V2 forward-nav target so Stela drill-in engages and its children
                // inherit this folder's accessRole (see SharedFilesViewModel.v2ChildContext).
                // Nil when the flag is off / no V2 → navigateMin falls through to V1 safely.
                viewModel.v2NavigationTarget = file
                let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, nil)
                navigateToFolder(withParams: navigateParams, backNavigation: false, then: {
                    self.backButton.isHidden = false
                    self.directoryLabel.text = file.name
                })
            } else {
                let listPreviewVC = FilePreviewListViewController(nibName: nil, bundle: nil)
                listPreviewVC.modalPresentationStyle = .fullScreen
                listPreviewVC.viewModel = viewModel
                listPreviewVC.currentFile = file
                
                let fileDetailsNavigationController = FilePreviewNavigationController(rootViewController: listPreviewVC)
                fileDetailsNavigationController.filePreviewNavDelegate = self
                fileDetailsNavigationController.modalPresentationStyle = .fullScreen
                
                present(fileDetailsNavigationController, animated: true)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = indexPath.section
        let title = viewModel?.title(forSection: section) ?? ""
        
        if kind == UICollectionView.elementKindSectionHeader && title.isNotEmpty {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FileCollectionViewHeaderCell.identifier, for: indexPath) as! FileCollectionViewHeaderCell
            headerView.leftButtonTitle = title
            headerView.configure(with: viewModel)
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
                    if !fabView.isHidden {
                        headerView.rightButtonTitle = (viewModel?.isSelectingDestination ?? false) ? nil : "Select".localized()
                    }
                }
                // A title-less button still occupies a tappable area, so in paste-destination
                // mode hide it outright — otherwise tapping where "Select" used to be silently
                // re-enters multi-select and lets items be reselected instead of navigating.
                headerView.rightButton.isHidden = viewModel?.isSelectingDestination ?? false

                headerView.rightButtonAction = { [weak self] header in self?.selectButtonWasPressed(UIButton()) }
                headerView.clearButtonAction = { [weak self] header in self?.clearButtonWasPressed(UIButton())}
            }
            
            return headerView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let height: CGFloat = viewModel?.numberOfRowsInSection(section) != 0 && (viewModel?.title(forSection: section) ?? "").isNotEmpty ? 40 : 0
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }
}

// MARK: - CollectionView Related
extension SharesViewController {
    func scrollToFileIfNeeded() {
        guard
            let folderLinkId = selectedFileId,
            let index = viewModel?.viewModels.firstIndex(where: { $0.folderLinkId == folderLinkId })
        else {
            return
        }
        
        guard index >= 0 && index < collectionView.numberOfItems(inSection: 0) else {
            // Handle the case where the index is out of bounds
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
    }
}

// MARK: - SharedFileActionSheetDelegate
extension SharesViewController: SharedFileActionSheetDelegate {
    func downloadAction(file: FileModel) {
        download(file)
    }
    
    func getShareLinkAction(file: FileModel) {
        let shareViewModel = ShareLinkViewModel(fileViewModel: file)
        
        // Check if the file already has a share link
        shareViewModel.getShareLink(option: .retrieve) { [weak self] shareVO, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                
                if let shareVO = shareVO,
                   shareVO.sharebyURLID != nil,
                   let shareURLString = shareVO.shareURL,
                   let shareURL = URL(string: shareURLString) {
                    // File has an existing share link, dismiss menu first then share it directly
                    self.dismiss(animated: true) {
                        let activityViewController = UIActivityViewController(
                            activityItems: [shareURL], 
                            applicationActivities: []
                        )
                        activityViewController.popoverPresentationController?.sourceView = self.view
                        self.present(activityViewController, animated: true, completion: nil)
                    }
                } else {
                    // File doesn't have a share link, dismiss menu first then open ShareManagement to create one
                    self.dismiss(animated: true) {
                        self.presentShareManagement(for: file)
                    }
                }
            }
        }
    }
    
    func relocateAction(files: [FileModel]?, action: FileAction) {
        viewModel?.selectedFiles = files
        viewModel?.fileAction = action

        setupBottomActionSheet()
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
    
    // MARK: - Metadata Edit
    func presentMetadataEditView(completion: @escaping (Bool) -> Void) {
        guard let selectedFiles = self.viewModel?.selectedFiles else { return }
        
        let hostingController = UIHostingController(rootView: MetadataEditView(viewModel: FilesMetadataViewModel(files: selectedFiles)))
        hostingController.modalPresentationStyle = .fullScreen
        
        self.present(hostingController, animated: true, completion: nil)
        
        self.dismissFloatingActionIsland()
        self.clearButtonWasPressed(UIButton())
        
        hostingController.rootView.dismissAction = { hasUpdates in
            hostingController.dismiss(animated: true, completion: {
                completion(hasUpdates)
            })
        }
    }
    
    private func refreshShares() {
        getShares(shouldShowSpinner: false)
    }
}

// MARK: - FilePreviewNavigationControllerDelegate
extension SharesViewController: FilePreviewNavigationControllerDelegate {
    func filePreviewNavigationControllerWillClose(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        if hasChanges {
            refreshCurrentFolder()
        }
    }
    
    func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
    }
    
    func filePreviewNavigationControllerRequestsDownload(_ filePreviewNavigationVC: UIViewController, file: FileModel) {
        downloadAction(file: file)
    }
}

// MARK: - SortActionSheetDelegate
extension SharesViewController: SortActionSheetDelegate {
    func didSelectOption(_ option: SortOption) {
        viewModel?.activeSortOption = option
        refreshCurrentFolder()
    }
}

// MARK: - FABViewDelegate
extension SharesViewController: FABViewDelegate {
    func didTap() {
        let fabMenuView = FABMenuView(
            onCreateFolder: { [weak self] in
                self?.didTapNewFolder()
            },
            onTakePhoto: { [weak self] in
                self?.openCamera()
            },
            onUploadPhotos: { [weak self] in
                self?.openPhotoLibrary()
            },
            onBrowseFiles: { [weak self] in
                self?.openFileBrowser()
            },
            onDismiss: { [weak self] in
                self?.dismiss(animated: false, completion: {
                    // Restore through the permission gate — a view-only folder must not get
                    // the FAB back just because the menu closed. setVisibility animates.
                    self?.updateFAB()
                })
            }
        )
        
        let hostingController = UIHostingController(rootView: fabMenuView)
        hostingController.modalPresentationStyle = UIModalPresentationStyle.overFullScreen
        hostingController.modalTransitionStyle = UIModalTransitionStyle.crossDissolve
        hostingController.view.backgroundColor = UIColor.clear
        
        present(hostingController, animated: true)
        
        // Hide the FAB through the same API that shows it (see MainViewController) — a
        // hand-faded alpha is not undone by the permission gate, so the FAB returned
        // invisible after any menu action.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.fabView.setVisibility(hidden: true)
        }
    }
    
    func didTapChecklist() {
        let checklistView = UIHostingController(rootView: ChecklistBottomMenuView(viewModel: StateObject(wrappedValue: ChecklistBottomMenuViewModel(showsChecklistButton: self.fabView.showsChecklistButton)), dismissAction: { [weak self] in
            self?.fabView.showsChecklistButton = false
            UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseOut, animations: { [weak self] in
                self?.bottomButtonHeightConstraint.constant = 64
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
extension SharesViewController: FABActionSheetDelegate {
    func didTapUpload() {
        // This is kept for backwards compatibility but no longer used
        showActionSheet()
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
    
    func showActionSheet() {
        let cameraAction = UIAlertAction(title: .takePhotoOrVideo, style: .default) { _ in self.openCamera() }
        let photoLibraryAction = UIAlertAction(title: .photoLibrary, style: .default) { _ in self.openPhotoLibrary() }
        let browseAction = UIAlertAction(title: .browse, style: .default) { _ in self.openFileBrowser() }
        let cancelAction = UIAlertAction(title: .cancel, style: .cancel, handler: nil)

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addActions([cameraAction, photoLibraryAction, browseAction, cancelAction])
        
        present(actionSheet, animated: true, completion: nil)
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
        let docPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String, kUTTypeContent as String], in: .import)
        
        docPicker.delegate = self
        docPicker.allowsMultipleSelection = true
        present(docPicker, animated: true, completion: nil)
    }
    
    private func processUpload(toFolder folder: FileModel, forURLS urls: [URL], loadInMemory: Bool = false) {
        let folderInfo = FolderInfo(folderId: folder.folderId, folderLinkId: folder.folderLinkId)
        
        let files = FileInfo.createFiles(from: urls, parentFolder: folderInfo, loadInMemory: loadInMemory)
        upload(files: files)
    }

    private func processUpload(toFolder folder: FileModel, selectedFiles: [SelectedUploadFile], loadInMemory: Bool = false) {
        let folderInfo = FolderInfo(folderId: folder.folderId, folderLinkId: folder.folderLinkId)

        let files = FileInfo.createFiles(from: selectedFiles, parentFolder: folderInfo, loadInMemory: loadInMemory)
        upload(files: files)
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
}

// MARK: - MediaRecorderDelegate
extension SharesViewController: MediaRecorderDelegate {
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

// MARK: - Document Picker Delegate
extension SharesViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let currentFolder = viewModel?.currentFolder else {
            return showErrorAlert(message: .cannotUpload)
        }

        showSpinner()
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let folderInfo = FolderInfo(folderId: currentFolder.folderId, folderLinkId: currentFolder.folderLinkId)
            let files = FileInfo.createFiles(from: urls, parentFolder: folderInfo, loadInMemory: false)
            DispatchQueue.main.async {
                self?.checkDuplicatesThenUpload(files: files, in: currentFolder) { _ in
                    self?.hideSpinner()
                }
            }
        }
    }
}

// MARK: - UIAdaptivePresentationControllerDelegate
extension SharesViewController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        // Show FAB buttons when menu is dismissed
        updateFAB()
    }
}
