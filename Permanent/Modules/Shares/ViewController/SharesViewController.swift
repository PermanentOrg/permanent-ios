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
    @IBOutlet var segmentedControl: SlidingTabControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var switchViewButton: UIButton!
    private let refreshControl = UIRefreshControl()
    @IBOutlet weak var bottomButtonHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var fileActionBottomView: BottomActionSheet!
    @IBOutlet var fabView: FABView!
    private lazy var mediaRecorder = MediaRecorder(presentationController: self, delegate: self)
    
    private let overlayView = UIView()
    let fileHelper = FileHelper()
    let documentInteractionController = UIDocumentInteractionController()
    
    var selectedIndex: Int = 0
    
    var selectedFileId: Int?
    
    var fileType: FileType?
    var sharedFolderArchiveNo: String = ""
    var sharedFolderLinkId: Int = -1
    /// Set by a share link, so the folder's own details can open it on the paged route.
    var sharedFolderId: Int?
    var sharedFolderName: String = ""
    var sharedRecordId: Int = -1
    var shareThumbnailURL: String?
    var shareAccessRole: String?

    var getSharesRequest: ((@escaping ServerResponse) -> Void)?
    var navigateMinRequest: ((NavigateMinParams, Bool, @escaping ServerResponse) -> Void)?
    var changeArchiveRequest: ((Int, String, @escaping (Bool) -> Void) -> Void)?
    
    private var isGridView = false
    private(set) lazy var sortMenu = SortMenu.make(
        current: { [weak self] in self?.viewModel?.activeSortOption ?? .nameAscending },
        onSelect: { [weak self] option in self?.applySort(option) }
    )
    private(set) lazy var stickyHeaderReveal = StickyHeaderReveal(list: collectionView, keepsShown: { [weak self] in
        self?.viewModel?.isSelecting == true
    })
    private lazy var folderHeader: FolderHeaderTransition? = {
        guard backButton != nil, directoryLabel != nil else { return nil }
        return FolderHeaderTransition(backButton: backButton, titleLabel: directoryLabel)
    }()
    /// How the last folder load ended, for flows that changed the header before it landed; nil while one runs.
    private var lastFolderLoadStatus: RequestStatus?
    private var backSwipe: FolderBackSwipe?
    private var backPreviewIsShareList = false
    private lazy var pagingSection = FileListPagingSection(collectionView: collectionView, viewModel: { [weak self] in self?.viewModel }, onChange: { [weak self] in self?.refreshCollectionView() })
    private let menuDeferral = ContextMenuDeferral()
    private lazy var fileDrag = FileListDrag(handlers: .init(
        draggableFile: { [weak self] indexPath in self?.draggableFile(at: indexPath) },
        folderRow: { [weak self] indexPath in self?.dropFolder(at: indexPath) },
        openFolder: { [weak self] in self?.openFolderForDrop },
        isUnderPinnedHeader: { [weak self] point in self?.isUnderPinnedHeader(point) ?? false },
        drop: { [weak self] files, destination in self?.startDroppedMove(files, to: destination) },
        dragDidEnd: { [weak self] in self?.dragDidEnd() },
        lookDidChange: { [weak self] in self?.showDragLookOnVisibleRows() }
    ))
    private lazy var dropProgress = DropProgressIsland(handlers: .init(
        open: { [weak self] in
            self?.showFloatingActionIsland(withLeftItems: [], rightItems: [], opensAsCircle: true)
            return self?.floatingActionIsland
        },
        current: { [weak self] in self?.floatingActionIsland },
        close: { [weak self] done in self?.dismissFloatingActionIsland(done) },
        hidePlusButton: { [weak self] in self?.fabView.setVisibility(hidden: true) },
        restore: { [weak self] in
            guard let self, let viewModel = self.viewModel else { return }
            // A Move or a selection that started while the circle showed gets its bar now.
            if viewModel.fileAction != FileAction.none {
                self.setupBottomActionSheet()
            } else if viewModel.isSelecting, !(viewModel.selectedFiles ?? []).isEmpty {
                self.setupBottomActionSheetForMultipleFiles()
            } else {
                self.updateFAB()
            }
        }
    ))
    /// Borrows the sheet's role refresh while a long-press menu is open, so the menu can follow the server's role.
    private var contextMenuRoleRefresh: FileMenuViewModel?
    private var sharesRefreshRequestId = UUID()
    /// Archive whose share list is loading right now, nil once it lands. A second fetch for the same archive
    /// would supersede this one in the view model, and the spinner would then wait on the duplicate.
    private var inFlightSharesArchiveId: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = SharedFilesViewModel()
        viewModel?.trackOpenFiles()
        
        let hasSavedFile = checkSavedFile()
        let hasSavedFolder = checkSavedFolder()
        
        configureUI()
        setupCollectionView()
        setupBottomActionSheet()
        setUpBackSwipe()
        setUpDrag()
        
        fabView.delegate = self
        
        if !hasSavedFolder && !hasSavedFile {
            getShares()
            if let fileType = fileType {
                self.fileType = nil
                if fileType.isFolder {
                    viewModel?.linkedFolderId = sharedFolderId
                    let navigateParams: NavigateMinParams = (sharedFolderArchiveNo, sharedFolderLinkId, nil)
                    let revertHeader = showHeaderWhileLoading(title: sharedFolderName, showsBack: true, entering: sharedFolderLinkId)
                    navigateToFolder(withParams: navigateParams, backNavigation: false, shouldDisplaySpinner: true, then: revertHeader)
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
            
            self?.reloadRows()
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
            self?.reloadRows()
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
            self?.archiveDidChange()
        }
        
        NotificationCenter.default.addObserver(forName: SettingsRouter.showMemberChecklistNotifName, object: nil, queue: nil) { [weak self] _ in
            self?.didTapChecklist()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        overlayView.frame = view.bounds

        // A non-fullscreen sheet dismissal can return the view to a window with no appear callback, but
        // layout always runs — so flush any relayout deferred from an off-window reload here.
        if needsCollectionViewReloadOnAppear, viewIfLoaded?.window != nil {
            needsCollectionViewReloadOnAppear = false
            collectionView.reloadData()
            configureCollectionViewBgView()
        }
    }
    
    fileprivate func configureUI() {
        navigationItem.title = .shares
        view.backgroundColor = .backgroundPrimary
        
        segmentedControl.titles = [.sharedByMe, .sharedWithMe]
        
        if let listType = ShareListType(rawValue: selectedIndex) {
            segmentedControl.selectedSegmentIndex = selectedIndex
            viewModel?.shareListType = listType
        }
        
        directoryLabel.font = TextFontStyle.style3.font
        directoryLabel.textColor = .primary
        // Over the share list's skeleton, not the storyboard's placeholder name.
        directoryLabel.text = "Shares".localized()
        backButton.tintColor = .primary
        backButton.isHidden = true
        _ = folderHeader
        
        fileActionBottomView.isHidden = true
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
        styleNavBar()
    }
    
    func setupCollectionView() {
        isGridView = viewModel?.isGridView ?? false
        switchViewButton.accessibilityIdentifier = "switchViewButton"
        switchViewButton.setImage(UIImage(systemName: isGridView ? "list.bullet" : "square.grid.2x2.fill"), for: .normal)
        
        collectionView.register(UINib(nibName: "FileCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "FileCell")
        collectionView.register(UINib(nibName: "FileCollectionViewGridCell", bundle: nil), forCellWithReuseIdentifier: "FileGridCell")
        collectionView.register(FileCollectionViewHeaderCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FileCollectionViewHeaderCell.identifier)
        _ = pagingSection
        
        collectionView.refreshControl = refreshControl
        collectionView.showsVerticalScrollIndicator = false
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: UIScreen.main.bounds.width - 40, right: 6)
        collectionView.collectionViewLayout = StickyHeaderFlowLayout.fileList()
        
        refreshControl.tintColor = .primary
        refreshControl.addTarget(self, action: #selector(pullToRefreshAction), for: .valueChanged)
    }
    
    fileprivate func configureCollectionViewBgView() {
        if let items = viewModel?.viewModels, items.isEmpty, viewModel?.isLoadingFirstPage == false,
           viewModel?.childrenPagingState == .complete {
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
    
    /// Which archive the displayed shares belong to. Comparing it against the session on the way in
    /// is immune to whichever lifecycle callbacks ran, unlike a flag set when a notification arrives.
    private var loadedArchiveId: Int?
    private var needsCollectionViewReloadOnAppear = false

    private var sessionArchiveId: Int? {
        AuthenticationManager.shared.session?.selectedArchive?.archiveID
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        syncSharesForCurrentArchive()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        menuDeferral.menuIsGone()
    }

    /// Refetch if the displayed shares belong to a different archive than the selected one;
    /// otherwise just make sure the layout is current.
    private func syncSharesForCurrentArchive() {
        guard viewModel != nil else { return }

        if Self.shouldFetchShares(loadedArchiveId: loadedArchiveId, sessionArchiveId: sessionArchiveId, inFlightArchiveId: inFlightSharesArchiveId) {
            getShares(shouldShowSpinner: true)
        } else if loadedArchiveId == sessionArchiveId, needsCollectionViewReloadOnAppear {
            needsCollectionViewReloadOnAppear = false
            collectionView.reloadData()
            configureCollectionViewBgView()
        }
    }

    /// Back to the share list of the archive just selected.
    func archiveDidChange() {
        viewModel?.navigationStack.removeAll()
        viewModel?.selectedFiles = []
        viewModel?.fileAction = .none

        if let listType = ShareListType(rawValue: segmentedControl.selectedSegmentIndex) {
            viewModel?.shareListType = listType
        }

        fileActionBottomView.isHidden = true
        fabView.setVisibility(hidden: true)
        folderHeader?.show(title: "Shares".localized(), showsBack: false)
        stickyHeaderReveal.show(animated: false)
        collectionView.setContentOffset(.zero, animated: false)
        refreshControl.endRefreshing()

        // Only fetch while on screen: a `reloadData()` with no window leaves cells un-laid-out and the
        // list renders blank. `loadedArchiveId` still points at the old archive, so it refetches later.
        guard viewIfLoaded?.window != nil else { return }
        getShares(shouldShowSpinner: true)
    }

    /// The list needs a fetch when it shows another archive than the selected one and no fetch for the
    /// selected archive is already in flight. `viewDidLoad` starts the first load; `viewWillAppear` must not repeat it.
    static func shouldFetchShares(loadedArchiveId: Int?, sessionArchiveId: Int?, inFlightArchiveId: Int?) -> Bool {
        loadedArchiveId != sessionArchiveId && inFlightArchiveId != sessionArchiveId
    }

    fileprivate func refreshCollectionView(_ completion: (() -> ())? = nil) {
        if menuDeferral.holdsReload({ [weak self] in self?.refreshCollectionView(completion) }) { return }
        if fileDrag.holdsReload(addingPage: pagingSection.isAddingPage, { [weak self] in self?.refreshCollectionView(completion) }) { return }
        pagingSection.prepareForReload()
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
        rightItems.append(FloatingActionImageItem(image: closeImage) { [weak self] _, _ in
            self?.cancelRelocate()
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
        if dropProgress.isShowing { shouldShowFAB = false }

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
                                let revertHeader = self?.showHeaderWhileLoading(title: navigationParams.folderName, showsBack: true, entering: navigationParams.folderLinkId)
                                self?.navigateToFolder(withParams: navigationParams, backNavigation: false) { revertHeader?() }
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
                    let revertHeader = showHeaderWhileLoading(title: navigationParams.folderName, showsBack: true, entering: navigationParams.folderLinkId)
                    navigateToFolder(withParams: navigationParams, backNavigation: false, then: revertHeader)
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
            navigateToFolder(withParams: params, backNavigation: true, shouldDisplaySpinner: shouldDisplaySpinner, isRefresh: true, silenceErrors: silenceErrors, then: handler)
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
    
    @IBAction func segmentedControlValueChanged(_ sender: SlidingTabControl) {
        guard let listType = ShareListType(rawValue: sender.selectedSegmentIndex) else {
            return
        }
        
        folderHeader?.show(title: "Shares".localized(), showsBack: false)
        self.fabView.setVisibility(hidden: true)
        self.fileActionBottomView.isHidden = true
        
        viewModel?.shareListType = listType
        refreshCollectionView()
        
        viewModel?.fileAction = .none
        viewModel?.selectedFiles = []
    }
    
    // MARK: - Back swipe

    private func setUpBackSwipe() {
        backSwipe = FolderBackSwipe(list: collectionView, in: view, handlers: .init(
            canGoBack: { [weak self] in self?.canSwipeBack ?? false },
            showParentPreview: { [weak self] in self?.showBackPreview() },
            previewStillApplies: { [weak self] in self?.viewModel?.backPreviewStillApplies ?? false },
            endParentPreview: { [weak self] in self?.endBackPreview() ?? false },
            goBack: { [weak self] in self?.goUpOneLevel() }
        ))
    }

    /// The back swipe and the VoiceOver escape gesture work only when the back arrow could be tapped.
    var canSwipeBack: Bool {
        guard let viewModel, !viewModel.isSelecting, !viewModel.isLoadingFirstPage, !viewModel.navigationStack.isEmpty,
              !isShowingPopup else { return false }
        // Leaving the shared folder in the middle of a move asks first, so the swipe stays out of it.
        if viewModel.navigationStack.count == 1 && viewModel.fileAction != .none { return false }
        return folderHeader?.current.showsBack == true && backButton.isUserInteractionEnabled
    }

    /// The spinner or a dialog covers the back arrow from inside this view.
    private var isShowingPopup: Bool {
        isShowingSpinner || actionDialog?.superview != nil
    }

    override func accessibilityPerformEscape() -> Bool {
        // An open popup closes first, as the gesture closes a system one.
        if let actionDialog, actionDialog.superview != nil {
            actionDialog.dismiss()
            return true
        }
        guard let viewModel, !viewModel.navigationStack.isEmpty else { return false }
        if canSwipeBack {
            backButtonAction(backButton)
            UIAccessibility.post(notification: .screenChanged, argument: directoryLabel)
        }
        return true
    }

    /// The skeleton rows the parent will load under, shown before the swipe decides.
    private func showBackPreview() {
        guard let viewModel else { return }
        // The share list loads without the sort header a folder has.
        backPreviewIsShareList = viewModel.navigationStack.count == 1
        viewModel.beginBackPreview()
        refreshCollectionView()
        let inset = collectionView.adjustedContentInset
        collectionView.setContentOffset(CGPoint(x: -inset.left, y: -inset.top), animated: false)
    }

    /// `true` when the folder's own rows came back.
    private func endBackPreview() -> Bool {
        backPreviewIsShareList = false
        guard let viewModel else { return false }
        // With no load of its own left, nothing may go on holding touches.
        let rowsBack = viewModel.endBackPreview()
        if rowsBack { hideTouchBlocker() }
        refreshCollectionView()
        return rowsBack
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
        } else if backSwipe?.slideBack() != true {
            // The arrow plays the back swipe through when the swipe could run now.
            goUpOneLevel()
        }
    }

    /// Up to the parent folder, or out of a top-level share to the share list.
    private func goUpOneLevel() {
        guard
            let viewModel = viewModel,
            let leftFolder = viewModel.removeCurrentFolderFromHierarchy()
        else {
            return
        }
        
        if let destinationFolder = viewModel.currentFolder {
            let revertHeader = showHeaderWhileLoading(title: destinationFolder.name, showsBack: !viewModel.currentFolderIsRoot)
            let navigateParams: NavigateMinParams = (destinationFolder.archiveNo, destinationFolder.folderLinkId, nil)
            navigateToFolder(withParams: navigateParams, backNavigation: true, then: {
                self.fileDrag.navigationDidEnd()
                // The folder left is still on screen, so it goes back on the history and keeps its header.
                guard self.folderLoadFailed(), viewModel.navigationStack.last?.folderLinkId == destinationFolder.folderLinkId else { return }
                viewModel.navigationStack.append(leftFolder)
                revertHeader()
            })
        } else {
            let revertHeader = showHeaderWhileLoading(title: "Shares".localized(), showsBack: false)
            getShares {
                // The folder left is still on screen, so it goes back on the history, and is listed again
                // because emptying the history ended its paging.
                guard self.folderLoadFailed(), viewModel.navigationStack.isEmpty else { return }
                viewModel.navigationStack.append(leftFolder)
                revertHeader()
                self.refreshCurrentFolder(shouldDisplaySpinner: false, silenceErrors: true)
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
            if viewModel.childrenPagingState != .complete {
                selectWholeFolder()
                return
            } else if viewModel.selectedFiles?.count == viewModel.viewModels.count {
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
    
    /// Select all means the whole folder, so the pages not loaded yet come in first.
    private func selectWholeFolder() {
        guard let viewModel, let folderLinkId = viewModel.currentFolder?.folderLinkId else { return }
        viewModel.timer?.invalidate()
        showSpinner()
        viewModel.listWholeFolder { [weak self] status in
            guard let self, let viewModel = self.viewModel else { return }
            self.hideSpinner()
            // Select mode may have ended, or the folder changed, while the rows were loading.
            guard viewModel.isSelecting, viewModel.currentFolder?.folderLinkId == folderLinkId else {
                return self.refreshCollectionView()
            }
            if case .error(let message) = status {
                self.showErrorAlert(message: message)
            } else if viewModel.childrenPagingState == .complete {
                viewModel.selectedFiles = viewModel.viewModels
            } else {
                self.showErrorAlert(message: .errorMessage)
            }
            self.refreshCollectionView()
        }
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
        // Restore the FAB through the permission gate, never unconditionally: leaving select mode in a
        // view-only folder must not conjure an upload button. Must run after the reset above.
        updateFAB()
        collectionView.reloadData()
    }
    
    @IBAction func switchViewButtonPressed(_ sender: Any) {
        isGridView.toggle()
        viewModel?.isGridView = isGridView
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 60, right: 6)
        
        switchViewButton.setImage(UIImage(systemName: isGridView ? "list.bullet" : "square.grid.2x2.fill"), for: .normal)
        
        collectionView.reloadData()
        collectionView.collectionViewLayout = StickyHeaderFlowLayout.fileList()
        collectionView.collectionViewLayout.invalidateLayout()
        stickyHeaderReveal.show(animated: false)
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

    private func generateMenuItems(for file: FileModel, atIndexPath indexPath: IndexPath) -> [FileMenuViewModel.MenuItem] {
        FileMenuItems.types(for: file, in: menuPlace).map { type in
            FileMenuViewModel.MenuItem(type: type, action: sheetAction(for: type, file: file, atIndexPath: indexPath))
        }
    }

    private func sheetAction(for type: FileMenuItems.ItemType, file: FileModel, atIndexPath indexPath: IndexPath) -> (() -> Void)? {
        switch type {
        case .shareToPermanent, .publish, .editMetadata: return nil
        case .shareToAnotherApp: return { [weak self] in self?.shareWithOtherApps(file: file) }
        case .rename: return { [weak self] in self?.renameAction(file: file, atIndexPath: indexPath) }
        case .download: return { [weak self] in self?.downloadAction(file: file) }
        case .copy: return { [weak self] in self?.relocateAction(files: [file], action: .copy) }
        case .move: return { [weak self] in self?.relocateAction(files: [file], action: .move) }
        case .unshare: return { [weak self] in self?.unshareAction(file: file, atIndexPath: indexPath) }
        case .delete: return { [weak self] in self?.deleteAction(file: file, atIndexPath: indexPath) }
        case .fileInformation: return { [weak self] in self?.showFileInformation(for: file) }
        }
    }

    private func showFileInformation(for file: FileModel) {
        present(FileDetailsViewController.navigation(for: file, delegate: self), animated: true)
    }

    private var menuPlace: FileMenuItems.Place {
        let isRoot = viewModel?.currentFolderIsRoot ?? true
        return viewModel?.shareListType == .sharedWithMe ? .sharedWithMe(isRoot: isRoot) : .sharedByMe(isRoot: isRoot)
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
        // The share list loads under skeleton rows, as a folder does.
        let showsSkeleton = shouldShowSpinner && collectionView != nil
        if showsSkeleton {
            setLoadingFirstPage(true, forShareList: true)
        }
        
        fabView.setVisibility(hidden: true)

        let runRequest: (@escaping ServerResponse) -> Void = getSharesRequest ?? { [weak self] handler in
            self?.viewModel?.getShares(then: handler)
        }

        let requestId = UUID()
        sharesRefreshRequestId = requestId
        inFlightSharesArchiveId = sessionArchiveId

        runRequest({ status in
            // The skeleton stays up for its minimum time, so it fades out rather than flickers.
            let settle = {
                if showsSkeleton { self.setLoadingFirstPage(false, forShareList: true) }
                self.applySharesResult(status, requestId: requestId, redraws: showsSkeleton, then: completion)
            }
            showsSkeleton ? self.pagingSection.afterSkeletonMinimumTime(settle) : settle()
        })
    }

    /// `redraws` brings back the rows the skeleton hid when the share list itself is not shown.
    private func applySharesResult(_ status: RequestStatus, requestId: UUID, redraws: Bool, then completion: (() -> Void)?) {
        guard self.sharesRefreshRequestId == requestId else {
            // A newer fetch may have redrawn under this one's skeleton rows, which this settle just ended.
            if redraws, self.viewModel?.isLoadingFirstPage == false { self.refreshCollectionView() }
            return
        }

        self.lastFolderLoadStatus = status
        self.inFlightSharesArchiveId = nil
        self.hideSpinner()
        switch status {
        case .success:
            // Stamp what is on screen so the sync can tell whether it still matches the selected archive.
            // Only on success: a failed refresh leaves the old data up, and lying would suppress the retry.
            self.loadedArchiveId = self.sessionArchiveId
            // A folder on screen, or one being entered, keeps its rows; the share list waits in its caches.
            guard self.viewModel?.showsShareList == true else {
                if redraws { self.refreshCollectionView() }
                break
            }
            self.refreshCollectionView {
                self.scrollToFileIfNeeded()
                
                self.folderHeader?.show(title: "Shares".localized(), showsBack: false)
                if let rootFolder = self.viewModel?.currentFolderIsRoot, rootFolder {
                    self.fileActionBottomView.isHidden = true
                }
            }
            
        case .error(let message):
            if redraws { self.refreshCollectionView() }
            self.showErrorAlert(message: message)
        }
        
        if let completion = completion {
            completion()
        }
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
                    // Refetch rather than insert the source models: a copy is a new server record, so the inserted
                    // row would carry the original's ids and deleting "the copy" would delete the original.
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
        // Downloads are a serial FIFO in section 0, so the active item is always at row 0. The file's
        // index in `viewModels` belongs to the synced section and points at the wrong cell.
        guard let downloadingCell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)) as? FileCollectionViewCell
        else {
            return
        }

        downloadingCell.updateProgress(withValue: value)
    }

    public func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, shouldDisplaySpinner: Bool = true, isRefresh: Bool = false, silenceErrors: Bool = false, then handler: VoidAction? = nil) {
        // Entering a folder shows skeleton rows; refreshing the one on screen keeps its rows under the spinner.
        let showsSkeleton = shouldDisplaySpinner && !isRefresh
        if showsSkeleton {
            setLoadingFirstPage(true)
        } else if shouldDisplaySpinner {
            showSpinner()
        }

        let runRequest: (NavigateMinParams, Bool, @escaping ServerResponse) -> Void = navigateMinRequest ?? { [weak self] requestParams, requestBackNavigation, completion in
            self?.viewModel?.navigateMin(params: requestParams, backNavigation: requestBackNavigation, then: completion)
        }

        runRequest(params, backNavigation, { status in
            // The skeleton stays up for its minimum time, so it fades out rather than flickers.
            let finish = {
                if showsSkeleton {
                    self.setLoadingFirstPage(false)
                    // On failure the previous rows come back from under the skeleton, with any share list that landed.
                    if status != .success, self.collectionView != nil {
                        self.viewModel?.showHeldBackShareList()
                        self.refreshCollectionView()
                    }
                }
                self.onFilesFetchCompletion(status, silenceErrors: silenceErrors)
                handler?()
            }
            showsSkeleton && self.collectionView != nil ? self.pagingSection.afterSkeletonMinimumTime(finish) : finish()
        })
        viewModel?.timer?.invalidate()
    }

    /// Names the folder being opened at once, over its skeleton rows. The returned closure puts the previous
    /// header back when the load failed, unless something else has changed the header since.
    private func showHeaderWhileLoading(title: String?, showsBack: Bool, entering folderLinkId: Int? = nil) -> VoidAction {
        let previous = folderHeader?.current
        folderHeader?.show(title: title, showsBack: showsBack)
        let revision = folderHeader?.revision
        lastFolderLoadStatus = nil
        return { [weak self] in
            guard let self, let previous, self.folderHeader?.revision == revision, self.folderLoadFailed(entering: folderLinkId) else { return }
            self.folderHeader?.show(title: previous.title, showsBack: previous.showsBack)
        }
    }

    /// An error, or a folder entry another load overtook, leaves the previous folder on screen.
    private func folderLoadFailed(entering folderLinkId: Int? = nil) -> Bool {
        guard let status = lastFolderLoadStatus else { return false }
        if status != .success { return true }
        guard let folderLinkId else { return false }
        return viewModel?.currentFolder?.folderLinkId != folderLinkId
    }

    /// `forShareList` is the share list itself loading, rather than a folder being entered.
    private func setLoadingFirstPage(_ isLoading: Bool, forShareList: Bool = false) {
        guard let viewModel else { return }
        guard isLoading else {
            guard forShareList ? viewModel.endShareListLoad() : viewModel.endFirstPageLoad() else { return }
            hideTouchBlocker()
            if collectionView != nil { pagingSection.skeletonWillDisappear() }
            return
        }
        forShareList ? viewModel.beginShareListLoad() : viewModel.beginFirstPageLoad()
        if !fileDrag.isDragging { showTouchBlocker() }
        guard collectionView != nil else { return }
        pagingSection.skeletonWillAppear()
        refreshCollectionView()
        let inset = collectionView.adjustedContentInset
        collectionView.setContentOffset(CGPoint(x: -inset.left, y: -inset.top), animated: false)
        stickyHeaderReveal.show(animated: false)
    }

    private func onFilesFetchCompletion(_ status: RequestStatus, silenceErrors: Bool = false) {
        lastFolderLoadStatus = status
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

    /// The pre-upload duplicate check — same semantics as `MainViewController`'s.
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

// MARK: - Long-press menu

extension SharesViewController {
    /// The row's file when its … button would open the sheet right now; otherwise the long press does nothing.
    private func contextMenuFile(at indexPath: IndexPath) -> FileModel? {
        guard let viewModel, indexPath.section == FileListType.synced.rawValue, indexPath.item < viewModel.syncedViewModels.count,
              !viewModel.isSelecting, !viewModel.isSelectingDestination, viewModel.fileAction == .none
        else { return nil }
        let file = viewModel.fileForRowAt(indexPath: indexPath)
        guard file.fileStatus == .synced, URL(string: file.thumbnailURL) != nil || file.canBeAccessed else { return nil }
        return file
    }

    private func fileContextMenu(for file: FileModel, atIndexPath indexPath: IndexPath) -> UIMenu {
        FileContextMenu.make(for: FileMenuItems.types(for: file, in: menuPlace)) { [weak self] type in
            self?.menuDeferral.run { self?.performMenuAction(type, on: file, atIndexPath: indexPath) }
        }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemsAt indexPaths: [IndexPath], point: CGPoint) -> UIContextMenuConfiguration? {
        guard indexPaths.count == 1, let indexPath = indexPaths.first, let file = contextMenuFile(at: indexPath),
              FileContextMenu.hasActions(for: FileMenuItems.types(for: file, in: menuPlace))
        else { return nil }
        let configuration = UIContextMenuConfiguration(identifier: FileContextMenu.identifier(for: file), previewProvider: nil) { [weak self] _ in
            self?.fileContextMenu(for: file, atIndexPath: indexPath)
        }
        // Delete stays last when the menu opens above the row, as in the Files app.
        configuration.preferredMenuElementOrder = .fixed
        return configuration
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfiguration configuration: UIContextMenuConfiguration, highlightPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
        collectionView.cellForItem(at: indexPath).map { FileContextMenu.preview(for: $0, in: collectionView) }
    }

    func collectionView(_ collectionView: UICollectionView, contextMenuConfiguration configuration: UIContextMenuConfiguration, dismissalPreviewForItemAt indexPath: IndexPath) -> UITargetedPreview? {
        collectionView.cellForItem(at: indexPath).map { FileContextMenu.preview(for: $0, in: collectionView) }
    }

    /// A tap on the lifted row opens it, as a tap on the row does.
    func collectionView(_ collectionView: UICollectionView, willPerformPreviewActionForMenuWith configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionCommitAnimating) {
        guard let row = contextMenuRow(for: configuration) else { return }
        animator.preferredCommitStyle = .dismiss
        animator.addCompletion { [weak self] in
            // The menu has closed, so the reloads it held land before a folder slides in.
            self?.menuDeferral.menuIsGone()
            self?.collectionView(collectionView, didSelectItemAt: IndexPath(item: row, section: FileListType.synced.rawValue))
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplayContextMenu configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        menuDeferral.menuWillShow()
        refreshRole(forMenu: configuration)
    }

    func collectionView(_ collectionView: UICollectionView, willEndContextMenuInteraction configuration: UIContextMenuConfiguration, animator: UIContextMenuInteractionAnimating?) {
        contextMenuRoleRefresh = nil
        menuDeferral.menuWillEnd(animator: animator)
    }

    private func contextMenuRow(for configuration: UIContextMenuConfiguration) -> Int? {
        guard let identifier = configuration.identifier as? NSString else { return nil }
        return viewModel?.syncedViewModels.firstIndex { FileContextMenu.identifier(for: $0) == identifier }
    }

    /// At the top of Shared with me the sheet asks the server for the caller's role as it opens; the open menu follows the answer.
    private func refreshRole(forMenu configuration: UIContextMenuConfiguration) {
        guard menuPlace == .sharedWithMe(isRoot: true), let row = contextMenuRow(for: configuration),
              let file = viewModel?.syncedViewModels[row]
        else { return }
        let indexPath = IndexPath(item: row, section: FileListType.synced.rawValue)
        let refresh = FileMenuViewModel(fileViewModel: file, menuItems: [], showArchiveInfo: true, onDismiss: {})
        refresh.setFileModelUpdateHandler { [weak self, weak refresh] updatedFile in
            // A late answer for a menu that has closed must not rewrite the next one.
            guard let self, let refresh, self.contextMenuRoleRefresh === refresh else { return }
            self.updateFileModelInDataSource(updatedFile)
            self.collectionView.contextMenuInteraction?.updateVisibleMenu { _ in
                self.fileContextMenu(for: updatedFile, atIndexPath: indexPath)
            }
        }
        contextMenuRoleRefresh = refresh
        refresh.fetchUpdatedAccessRole()
    }

    private func performMenuAction(_ type: FileMenuItems.ItemType, on file: FileModel, atIndexPath indexPath: IndexPath) {
        switch type {
        case .shareToPermanent: presentShareManagement(for: file)
        case .shareToAnotherApp: shareWithOtherApps(file: file)
        case .rename: renameAction(file: file, atIndexPath: indexPath)
        case .move: relocateAction(files: [file], action: .move)
        case .copy: relocateAction(files: [file], action: .copy)
        case .download: downloadAction(file: file)
        case .fileInformation: showFileInformation(for: file)
        case .delete: confirmMenuAction(.delete, on: file) { [weak self] in self?.deleteFile([file]) }
        case .unshare: confirmMenuAction(.leaveShare, on: file) { [weak self] in self?.unshareFile(file, atIndexPath: indexPath) }
        case .publish, .editMetadata: break
        }
    }

    private func confirmMenuAction(_ actionType: ConfirmationBottomAlertView.ActionType, on file: FileModel, then action: @escaping () -> Void) {
        let confirmation = FileActionConfirmationView.host(for: file, actionType, onConfirm: action, onDismiss: { [weak self] in
            self?.dismiss(animated: false)
        })
        present(confirmation, animated: false)
    }
}

// MARK: - Drag to move

extension SharesViewController {
    private func setUpDrag() {
        collectionView.dragDelegate = fileDrag
        collectionView.dropDelegate = fileDrag
        collectionView.isSpringLoaded = true
        // A drag never leaves its share: the arrow does not go up from the top shared folder.
        backButton.addInteraction(FileListDrag.springLoadedBackArrow(
            canGoUp: { [weak self] in
                guard let self, self.fileDrag.isDragging, let viewModel = self.viewModel else { return false }
                return viewModel.navigationStack.count > 1 && self.canSwipeBack
            },
            goUp: { [weak self] in
                guard let self else { return }
                self.fileDrag.navigationWillStart()
                self.backButtonAction(self.backButton)
            }
        ))
    }

    /// A row may be dragged when its menu offers Move, which the menu never does at the share list.
    private func draggableFile(at indexPath: IndexPath) -> FileModel? {
        guard let file = contextMenuFile(at: indexPath), FileMenuItems.types(for: file, in: menuPlace).contains(.move) else { return nil }
        return file
    }

    private func dropFolder(at indexPath: IndexPath) -> FileModel? {
        contextMenuFile(at: indexPath).flatMap { $0.type.isFolder ? $0 : nil }
    }

    /// The share list takes no drops.
    private var openFolderForDrop: FileModel? {
        guard let viewModel, !viewModel.navigationStack.isEmpty, !viewModel.isSelecting, !viewModel.isSelectingDestination,
              viewModel.fileAction == .none else { return nil }
        return viewModel.currentFolder
    }

    private func isUnderPinnedHeader(_ point: CGPoint) -> Bool {
        let path = IndexPath(item: 0, section: FileListType.synced.rawValue)
        guard let header = collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: path),
              !header.isHidden, header.alpha > 0 else { return false }
        return header.frame.contains(point)
    }

    /// Greys the folder under the finger, on the rows on screen now.
    private func showDragLookOnVisibleRows() {
        guard let viewModel, let collectionView else { return }
        for case let cell as FileCollectionViewCell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell), indexPath.section == FileListType.synced.rawValue,
                  indexPath.item < viewModel.syncedViewModels.count else { continue }
            fileDrag.showLook(on: cell, for: viewModel.fileForRowAt(indexPath: indexPath))
        }
    }

    /// A folder still loading when the finger lifts gets the touch cover it went without during the drag.
    private func dragDidEnd() {
        if viewModel?.isLoadingFirstPage == true { showTouchBlocker() }
    }

    /// A plain reload of the rows that still waits for an open menu or a drag.
    private func reloadRows() {
        if menuDeferral.holdsReload({ [weak self] in self?.reloadRows() }) { return }
        if fileDrag.holdsReload({ [weak self] in self?.reloadRows() }) { return }
        collectionView.reloadData()
    }

    /// Rows that leave the folder go at once, as in Files; files moved into the open folder show once the server lists them.
    /// Meanwhile the island shows the move's progress, as after Move Here.
    func startDroppedMove(_ files: [FileModel], to destination: FileModel) {
        guard let viewModel, let folder = viewModel.currentFolder else { return }
        let leaving = files.filter(viewModel.lists)
        if !leaving.isEmpty {
            viewModel.removeListedRows(of: leaving)
            refreshCollectionView()
        }
        dropProgress.moveStarted()
        viewModel.moveDropped(files, to: destination) { [weak self] status in
            guard let self else { return }
            // As after Move Here on this screen, the check shows when the server says yes.
            self.dropProgress.moveEnded(succeeded: status == .success)
            switch status {
            case .success:
                if !leaving.isEmpty {
                    self.settleMovedAway(leaving, from: folder, attemptsLeft: Self.movedAwaySettleAttempts)
                } else if destination.folderLinkId == folder.folderLinkId {
                    self.refreshCurrentFolder(shouldDisplaySpinner: false, silenceErrors: true)
                }
            case .error(let message):
                self.showErrorAlert(message: message)
                self.refreshCurrentFolder(shouldDisplaySpinner: false, silenceErrors: true)
            }
        }
    }

    /// Refetches before the rows count as gone anyway, about 10 s.
    private static let movedAwaySettleAttempts = 10

    /// The server still lists a moved row for a moment after it answers, so refetches keep it off the screen until it goes.
    private func settleMovedAway(_ files: [FileModel], from folder: FileModel, attemptsLeft: Int) {
        refreshCurrentFolder(shouldDisplaySpinner: false, silenceErrors: true) { [weak self] in
            guard let self, let viewModel = self.viewModel, viewModel.currentFolder?.folderLinkId == folder.folderLinkId else { return }
            let stillListed = files.filter(viewModel.lists)
            guard !stillListed.isEmpty else { return }
            viewModel.removeListedRows(of: stillListed)
            self.refreshCollectionView()
            guard attemptsLeft > 1 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + FilesViewModel.pastedItemsPollInterval) { [weak self] in
                self?.settleMovedAway(files, from: folder, attemptsLeft: attemptsLeft - 1)
            }
        }
    }

    func collectionView(_ collectionView: UICollectionView, shouldSpringLoadItemAt indexPath: IndexPath, with context: UISpringLoadedInteractionContext) -> Bool {
        fileDrag.shouldSpringLoad(indexPath)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension SharesViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.map { $0.numberOfSections + 1 } ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == pagingSection.sectionIndex { return pagingSection.numberOfItems(isGrid: isGridView) }
        return viewModel?.numberOfRowsInSection(section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = self.viewModel else {
            return UICollectionViewCell()
        }
        if indexPath.section == pagingSection.sectionIndex {
            return pagingSection.cell(at: indexPath, isGrid: isGridView)
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
        fileDrag.showLook(on: cell, for: file)
        let pendingInvitationCount = pendingInvitationBadgeCount(for: file)
        cell.setMoreButtonBadgeCount(cell.moreButton.isHidden ? 0 : pendingInvitationCount)
        
        cell.rightButtonTapAction = { [weak self] _ in
            self?.handleCellRightButtonAction(for: file, atIndexPath: indexPath)
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
        
        if indexPath.section == FileListType.synced.rawValue || indexPath.section == pagingSection.sectionIndex {
            return isGridView ? gridItemSize : listItemSize
        } else {
            return listItemSize
        }
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        pagingSection.willDisplayItem(at: indexPath)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        stickyHeaderReveal.listDidScroll()
    }

    /// A status-bar tap brings the row back as the list starts moving; the scroll itself is not the finger's.
    func scrollViewShouldScrollToTop(_ scrollView: UIScrollView) -> Bool {
        if scrollView === collectionView { stickyHeaderReveal.show(animated: true) }
        return true
    }

    func scrollViewDidScrollToTop(_ scrollView: UIScrollView) {
        guard scrollView === collectionView else { return }
        stickyHeaderReveal.show(animated: true)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section != pagingSection.sectionIndex
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel, indexPath.section != pagingSection.sectionIndex else { return }
        
        let file = viewModel.fileForRowAt(indexPath: indexPath)

        guard file.fileStatus == .synced && (file.thumbnailURL != nil || file.canBeAccessed) else { return }

        // Paste-destination mode is navigation-only: the relocate selection is fixed to the items being
        // copied, so a tap only drills into a folder.
        if viewModel.isSelectingDestination {
            guard file.type.isFolder, !(viewModel.selectedFiles?.contains(file) ?? false) else { return }
            viewModel.v2NavigationTarget = file
            enter(file, from: collectionView)
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
                // Seed the V2 forward-nav target so drill-in engages and children inherit this folder's
                // accessRole. Nil falls through to V1 safely.
                viewModel.v2NavigationTarget = file
                enter(file, from: collectionView)
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

    /// Slides the folder in, with its name in the header at once.
    private func enter(_ folder: FileModel, from list: UICollectionView) {
        let navigateParams: NavigateMinParams = (folder.archiveNo, folder.folderLinkId, nil)
        fileDrag.navigationWillStart()
        FolderOpenSlide.play(on: list) {
            let revertHeader = showHeaderWhileLoading(title: folder.name, showsBack: true, entering: folder.folderLinkId)
            navigateToFolder(withParams: navigateParams, backNavigation: false, then: { [weak self] in
                revertHeader()
                self?.fileDrag.navigationDidEnd()
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            return pagingSection.footer(at: indexPath)
        }
        let section = indexPath.section
        let title = viewModel?.title(forSection: section) ?? ""
        
        if kind == UICollectionView.elementKindSectionHeader && title.isNotEmpty {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FileCollectionViewHeaderCell.identifier, for: indexPath) as! FileCollectionViewHeaderCell
            headerView.leftButtonTitle = title
            headerView.configure(with: viewModel)
            headerView.sortMenu = viewModel?.shouldPerformAction(forSection: section) == true ? sortMenu : nil
            // The layout spans the synced header across the side insets, so its buttons move in by that much.
            headerView.gutterWidth = section == FileListType.synced.rawValue ? collectionView.contentInset.left : 0
            
            // Reset the reused header's Select button to visible; a previous dequeue may
            // have hidden it for a paste-destination section (see below).
            headerView.rightButton.isHidden = false

            if viewModel?.hasCancelButton(forSection: section) == true {
                headerView.rightButtonTitle = "Cancel All".localized()
                headerView.rightButtonAction = { [weak self] header in self?.cancelAllUploadsAction(UIButton()) }
            } else {
                if let selectWasPressed = viewModel?.isSelecting, selectWasPressed {
                    headerView.rightButtonTitle = "Select all".localized()
                } else if !fabView.isHidden {
                    if viewModel?.isSelectingDestination == true {
                        headerView.rightButtonTitle = nil
                    } else {
                        headerView.rightButtonTitle = "Select".localized()
                        headerView.showSelectIcon()
                    }
                }
                // A title-less button is still tappable, so hide it outright in paste mode — otherwise tapping
                // where Select used to be silently re-enters multi-select.
                headerView.rightButton.isHidden = viewModel?.isSelectingDestination ?? false

                headerView.rightButtonAction = { [weak self] header in self?.selectButtonWasPressed(UIButton()) }
                headerView.clearButtonAction = { [weak self] header in self?.clearButtonWasPressed(UIButton())}
            }
            
            return headerView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        guard section != pagingSection.sectionIndex else { return .zero }
        if backPreviewIsShareList && section == FileListType.synced.rawValue { return .zero }
        // The sort header stays over the skeleton rows while a folder's first page loads.
        let showsSortHeader = section == FileListType.synced.rawValue && viewModel?.isLoadingFirstPage == true
        let hasRows = showsSortHeader || viewModel?.numberOfRowsInSection(section) != 0
        let height: CGFloat = hasRows && (viewModel?.title(forSection: section) ?? "").isNotEmpty ? FileCollectionViewHeaderCell.height : 0
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard section == pagingSection.sectionIndex else { return .zero }
        return pagingSection.footerSize(width: collectionView.bounds.width - collectionView.adjustedContentInset.left - collectionView.adjustedContentInset.right)
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

    /// The X on the Move or Copy bar drops the picked files. The plus button is asked last:
    /// it stays hidden while a folder for the files is being picked.
    func cancelRelocate() {
        dismissFloatingActionIsland()
        viewModel?.selectedFiles = []
        viewModel?.fileAction = .none
        viewModel?.isSelectingDestination = false
        updateFAB()
        collectionView?.reloadData()
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
        // File information opens the details straight from the list, so no preview is there to close them.
        if filePreviewNavigationVC is FileDetailsViewController {
            filePreviewNavigationVC.dismiss(animated: true)
        }
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

// MARK: - Sorting
extension SharesViewController {
    /// Saves the pick, then lists the folder in the new order from its top.
    func applySort(_ option: SortOption) {
        guard let viewModel = viewModel else { return }
        if viewModel.currentFolder != nil { showSpinner() }
        viewModel.saveSortOption(option) { [weak self] _ in
            // The refresh's own guard would leave the spinner up if the folder is gone by now.
            self?.hideSpinner()
            // A folder's refreshed rows are drawn on a later main-queue turn; scrolling first would lay out rows now gone.
            self?.refreshCurrentFolder(then: { [weak self] in DispatchQueue.main.async { self?.scrollListToTop() } })
        }
    }

    /// The row stays on screen deep in a list, so a new order would otherwise open mid-list.
    private func scrollListToTop() {
        guard let collectionView else { return }
        let inset = collectionView.adjustedContentInset
        collectionView.setContentOffset(CGPoint(x: -inset.left, y: -inset.top), animated: false)
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
        
        // Hide the FAB through the same API that shows it: the permission gate only manages `isHidden`,
        // so a hand-faded alpha leaves it invisible after any menu action.
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
    
    /// Upload destination for the Live Activity's folder card. Anything reached through
    /// Shares sits in the Shared workspace.
    private func uploadDestination(_ folder: FileModel) -> FolderInfo {
        FolderInfo(
            folderId: folder.folderId,
            folderLinkId: folder.folderLinkId,
            name: folder.name,
            // The loaded rows are the folder's size only once every page is in.
            itemCount: viewModel?.childrenPagingState == .complete ? viewModel?.viewModels.count : nil,
            isShared: true
        )
    }

    private func processUpload(toFolder folder: FileModel, forURLS urls: [URL], loadInMemory: Bool = false) {
        let folderInfo = uploadDestination(folder)

        let files = FileInfo.createFiles(from: urls, parentFolder: folderInfo, loadInMemory: loadInMemory)
        upload(files: files)
    }

    private func processUpload(toFolder folder: FileModel, selectedFiles: [SelectedUploadFile], loadInMemory: Bool = false) {
        let folderInfo = uploadDestination(folder)

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
        // Resolve the destination here, on main, where the view model's listing is
        // safe to read — not inside the background block below.
        let folderInfo = uploadDestination(currentFolder)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
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
