//
//  SharesViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

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
    
    @IBOutlet weak var fileActionBottomView: BottomActionSheet!
    @IBOutlet var fabView: FABView!
    private lazy var mediaRecorder = MediaRecorder(presentationController: self, delegate: self)
    
    private var fileActionSheet: SharedFileActionSheet?
    
    private let overlayView = UIView()
    
    var selectedIndex: Int = 0
    
    var selectedFileId: Int?
    
    var fileType: FileType?
    var sharedFolderArchiveNo: String = ""
    var sharedFolderLinkId: Int = -1
    var sharedFolderName: String = ""
    var sharedRecordId: Int = -1
    var shareThumbnailURL: String?
    var shareAccessRole: String?
    
    private var isGridView = false
    private var sortActionSheet: SortActionSheet?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = SharedFilesViewModel()
        
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
                    self?.viewModel?.viewModels.insert(FileViewModel(model: uploadedFile, archiveThumbnailURL: "", permissions: [], accessRole: self?.viewModel?.currentFolder?.accessRole ?? .viewer), at: 0)
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
                  let index = self?.viewModel?.viewModels.firstIndex(where: { $0.recordId == shareLinkVM.fileViewModel.recordId })
            else {
                return
            }
            self?.viewModel?.viewModels[index].fileStatus = shareLinkVM.fileViewModel.fileStatus
            self?.viewModel?.viewModels[index].accessRole = shareLinkVM.fileViewModel.accessRole
            self?.viewModel?.viewModels[index].minArchiveVOS = shareLinkVM.fileViewModel.minArchiveVOS
            
            self?.collectionView.reloadData()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    fileprivate func configureUI() {
        navigationItem.title = .shares
        view.backgroundColor = .backgroundPrimary
        
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: Text.style11.font], for: .selected)
        segmentedControl.setTitleTextAttributes([.font: Text.style8.font], for: .normal)
        segmentedControl.setTitle(.sharedByMe, forSegmentAt: 0)
        segmentedControl.setTitle(.sharedWithMe, forSegmentAt: 1)
        
        if let listType = ShareListType(rawValue: selectedIndex) {
            segmentedControl.selectedSegmentIndex = selectedIndex
            viewModel?.shareListType = listType
        }
        
        if #available(iOS 13.0, *) {
            segmentedControl.selectedSegmentTintColor = .primary
        }
        
        directoryLabel.font = Text.style3.font
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
        if #available(iOS 13.0, *) {
            switchViewButton.setImage(UIImage(systemName: isGridView ? "list.bullet" : "square.grid.2x2.fill"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        
        collectionView.register(UINib(nibName: "FileCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "FileCell")
        collectionView.register(UINib(nibName: "FileCollectionViewGridCell", bundle: nil), forCellWithReuseIdentifier: "FileGridCell")
        
        collectionView.refreshControl = refreshControl
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 60, right: 6)
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
            let emptyView = EmptyFolderView(title: .shareActionMessage, image: .shares)
            emptyView.frame = collectionView.bounds
            collectionView.backgroundView = emptyView
        } else {
            collectionView.backgroundView = nil
        }
    }
    
    fileprivate func refreshCollectionView(_ completion: (() -> ())? = nil) {
        collectionView.reloadData()
        configureCollectionViewBgView()
        completion?()
    }
    
    fileprivate func setupBottomActionSheet() {
        setupUIForAction(viewModel?.fileAction ?? .none)
        
        fileActionBottomView.closeAction = {
            self.setupUIForAction(.none)
        }
        
        fileActionBottomView.fileAction = {
            guard
                let source = self.viewModel?.selectedFile,
                let destination = self.viewModel?.currentFolder
            else {
                self.showErrorAlert(message: .errorMessage)
                return
            }

            self.didTapRelocate(source: source, destination: destination)
        }
    }
    
    fileprivate func setupUIForAction(_ action: FileAction) {
        viewModel?.fileAction = action
        
        switch action {
        case .none:
            fileActionBottomView.isHidden = true
            
        case .move, .copy:
            fileActionBottomView.isHidden = false
            if let rootFolder = viewModel?.currentFolderIsRoot, rootFolder {
                fileActionBottomView.isHidden = true
            }
            
            fileActionBottomView.setActionTitle(action.title)
            toggleFileAction(action)
        }
        updateFAB()
        
        DispatchQueue.main.async {
            self.refreshCollectionView()
        }
    }
    
    fileprivate func toggleFileAction(_ action: FileAction?) {
        // If we try to move file in the same folder, disable the button
        let shouldDisableButton = viewModel?.selectedFile?.parentFolderId == viewModel?.currentFolder?.folderId && action == .move

        if let currentFolderPermissions = viewModel?.currentFolder?.permissions,
            currentFolderPermissions.contains(.upload) == true {
            fileActionBottomView.toggleActionButton(enabled: true)
        } else {
            fileActionBottomView.toggleActionButton(enabled: false)
        }
        
        fileActionBottomView.toggleActionButton(enabled: !shouldDisableButton)
    }
    
    fileprivate func updateFAB() {
        let currentFolderPermissions = viewModel?.currentFolder?.permissions

        if currentFolderPermissions?.contains(.create) == true && currentFolderPermissions?.contains(.upload) == true {
            fabView.isHidden = false
        } else {
            fabView.isHidden = true
        }
        if !fileActionBottomView.isHidden {
            fabView.isHidden = true
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
                    
                    self?.viewModel?.changeArchive(withArchiveId: sharedFile.toArchiveId, archiveNbr: sharedFile.toArchiveNbr, completion: { success in
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
                    
                    self?.viewModel?.changeArchive(withArchiveId: sharedFolder.toArchiveId, archiveNbr: sharedFolder.toArchiveNbr, completion: { success in
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
    
    func refreshCurrentFolder(shouldDisplaySpinner: Bool = true, then handler: VoidAction? = nil) {
        guard let viewModel = viewModel else { return }
        
        if let currentFolder = viewModel.currentFolder {
            let params: NavigateMinParams = (currentFolder.archiveNo, currentFolder.folderLinkId, nil)
            
            // Back navigation set to `true` so it's not considered a in-depth navigation.
            navigateToFolder(withParams: params, backNavigation: true, shouldDisplaySpinner: shouldDisplaySpinner, then: handler)
        } else {
            getShares(shouldShowSpinner: false, completion: handler)
        }
    }
    
    func presentFileDetails(sharedFile: ShareNotificationPayload, sharedFileThumbnailURL: String? = nil) {
        let currentArchive: ArchiveVOData? = viewModel?.currentArchive
        let permissions = ArchiveVOData.permissions(forAccessRole: sharedFile.accessRole)
        let fileVM = FileViewModel(name: sharedFile.name, recordId: sharedFile.recordId, folderLinkId: sharedFile.folderLinkId, archiveNbr: sharedFile.archiveNbr, type: sharedFile.type, permissions: permissions, thumbnailURL2000: sharedFileThumbnailURL)
        let filePreviewVC = UIViewController.create(withIdentifier: .filePreview, from: .main) as! FilePreviewViewController
        filePreviewVC.file = fileVM
        
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
        self.fabView.isHidden = true
        self.fileActionBottomView.isHidden = true
        
        viewModel?.shareListType = listType
        refreshCollectionView()
        
        viewModel?.fileAction = .none
        viewModel?.selectedFile = nil
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        let fileTypeString: String = FileType(rawValue: self.viewModel?.selectedFile?.type.rawValue ?? "")?.isFolder ?? false ? "folder" : "file"
        if let navigationStackCount = viewModel?.navigationStack.count,
            navigationStackCount <= 1 && viewModel?.fileAction != FileAction.none {
            showActionDialog(
                styled: .simpleWithDescription,
                withTitle: "Cancel Move?".localized(),
                description: "Moving files or folders outside of the shared folder in which they are currently located is not permitted at this time. You can cancel this move action or continue to choose a destination for the selected \(fileTypeString).".localized(),
                positiveButtonTitle: "Continue".localized(),
                positiveAction: {
                    self.actionDialog?.dismiss()
                    self.viewModel?.fileAction = .none
                    self.viewModel?.selectedFile = nil
                    self.backButtonAction(UIButton())
                    self.dismiss(animated: false)
                },cancelButtonTitle: "Cancel Move".localized(),
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
    
    @IBAction func switchViewButtonPressed(_ sender: Any) {
        isGridView.toggle()
        viewModel?.isGridView = isGridView
        
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 60, right: 6)
        
        if #available(iOS 13.0, *) {
            switchViewButton.setImage(UIImage(systemName: isGridView ? "list.bullet" : "square.grid.2x2.fill"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        
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
        let title = "Cancel all uploads".localized()
        let description = "Are you sure you want to cancel all uploads?".localized()
        
        self.showActionDialog(
            styled: .simpleWithDescription,
            withTitle: title,
            description: description,
            positiveButtonTitle: .cancelAll,
            positiveAction: {
                self.actionDialog?.dismiss()
                self.viewModel?.cancelUploadsInFolder()
                
                if self.viewModel?.refreshUploadQueue() == true {
                    self.refreshCollectionView()
                }
            },
            cancelButtonTitle: "No".localized(),
            positiveButtonColor: .brightRed,
            cancelButtonColor: .primary,
            overlayView: self.overlayView
        )
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
    
    func showFileActionSheet(file: FileViewModel, atIndexPath indexPath: IndexPath) {
        var menuItems: [FileMenuViewController.MenuItem] = []
        
        if let currentFolderIsRoot = viewModel?.currentFolderIsRoot, currentFolderIsRoot && self.segmentedControl.selectedSegmentIndex == 1 {
            menuItems.append(FileMenuViewController.MenuItem(type: .unshare, action: { [self] in
                unshareAction(file: file, atIndexPath: indexPath)
            }))
        } else if file.permissions.contains(.delete) {
            menuItems.append(FileMenuViewController.MenuItem(type: .delete, action: { [self] in
                deleteAction(file: file, atIndexPath: indexPath)
            }))
        }

        if file.permissions.contains(.edit) {
            menuItems.append(FileMenuViewController.MenuItem(type: .rename, action: { [self] in
                renameAction(file: file, atIndexPath: indexPath)
            }))
        }
        
        if file.permissions.contains(.read) && file.type.isFolder == false {
            menuItems.append(FileMenuViewController.MenuItem(type: .download, action: { [self] in
                downloadAction(file: file)
            }))
        }
        
        if let currentFolderIsRoot = viewModel?.currentFolderIsRoot, file.permissions.contains(.move) && !currentFolderIsRoot {
            menuItems.append(FileMenuViewController.MenuItem(type: .move, action: { [self] in
                relocateAction(file: file, action: .move)
            }))
        }
        
        let vc = FileMenuViewController()
        vc.fileViewModel = file
        vc.menuItems = menuItems
        vc.showsPermission = viewModel?.shareListType == .sharedWithMe
        present(vc, animated: true)
    }
    
    func renameAction(file: FileViewModel, atIndexPath indexPath: IndexPath) {
        let title = String(format: "\(String.rename) \"%@\"", file.name)
        
        self.showActionDialog(
            styled: .singleField,
            withTitle: title,
            placeholders: ["Name".localized()],
            prefilledValues: ["\(file.name)"],
            positiveButtonTitle: .rename,
            positiveAction: { [weak self] in
                guard let self = self else { return }
                guard let inputName = self.actionDialog?.fieldsInput.first?.description else { return }
                if inputName.isEmpty {
                    self.view.showNotificationBanner(title: "Please enter a name".localized(), backgroundColor: .deepRed, textColor: .white, animationDelayInSeconds: Constants.Design.longNotificationBarAnimationDuration)
                } else {
                    self.actionDialog?.dismiss()
                    self.rename(file, inputName, atIndexPath: indexPath)
                    self.view.endEditing(true)
                }
            },
            positiveButtonColor: .primary,
            cancelButtonColor: .brightRed,
            overlayView: self.overlayView
        )
    }
    
    func deleteAction(file: FileViewModel, atIndexPath indexPath: IndexPath) {
        didTapDelete(forFile: file, atIndexPath: indexPath)
    }
    
    func unshareAction(file: FileViewModel, atIndexPath indexPath: IndexPath) {
        didTapUnshare(forFile: file, atIndexPath: indexPath)
    }

    fileprivate func getShares(shouldShowSpinner: Bool = true, completion: (() -> Void)? = nil) {
        if shouldShowSpinner {
            showSpinner()
        }
        
        fabView.isHidden = true
        
        viewModel?.getShares(then: { status in
            self.hideSpinner()
            switch status {
            case .success:
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
    
    private func didTapRelocate(source: FileViewModel, destination: FileViewModel) {
        self.relocate(file: source, to: destination)
    }
    
    private func download(_ file: FileViewModel) {
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
    
    func rename(_ file: FileViewModel, _ name: String, atIndexPath indexPath: IndexPath) {
        showSpinner()
        viewModel?.rename(file: file, name: name, then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                self.pullToRefreshAction()
                if file.type.isFolder {
                    self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "Folder rename was successful".localized())
                } else {
                    self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: "File rename was successful".localized())
                }
                
            case .error( _):
                self.view.showNotificationBanner(title: .errorMessage, backgroundColor: .deepRed, textColor: .white)
            }
        })
    }
    
    func relocate(file: FileViewModel, to destination: FileViewModel) {
        showSpinner()
        viewModel?.relocate(file: file, to: destination, then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                self.viewModel?.viewModels.prepend(file)

                self.view.showNotificationBanner(height: Constants.Design.bannerHeight, title: self.viewModel?.fileAction.action ?? .success)
                self.setupUIForAction(.none)
                
            case .error(let message):
                self.showErrorAlert(message: message)
            }
        })
    }
    
    private func didTapDelete(forFile file: FileViewModel, atIndexPath indexPath: IndexPath) {
        let title = String(format: "\(String.delete) \"%@\"?", file.name)
        
        self.showActionDialog(
            styled: .simple,
            withTitle: title,
            positiveButtonTitle: .delete,
            positiveAction: {
                self.actionDialog?.dismiss()
                self.deleteFile(file, atIndexPath: indexPath)
            }, positiveButtonColor: .brightRed,
            cancelButtonColor: .primary,
            overlayView: self.overlayView
        )
    }
    
    private func didTapUnshare(forFile file: FileViewModel, atIndexPath indexPath: IndexPath) {
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
    
    func deleteFile(_ file: FileViewModel, atIndexPath indexPath: IndexPath) {
        showSpinner()
        viewModel?.delete(file, then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.viewModel?.removeSyncedFile(file)
                    self.refreshCollectionView()
                }
                
            case .error(let message):
                self.showErrorAlert(message: message)
            }
        })
    }
    
    func unshareFile(_ file: FileViewModel, atIndexPath indexPath: IndexPath) {
        showSpinner()
        viewModel?.unshare(file, then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.viewModel?.removeSyncedFile(file)
                    self.refreshCollectionView()
                }
                
            case .error(let message):
                self.showErrorAlert(message: message)
            }
        })
    }
    
    private func handleCellRightButtonAction(for file: FileViewModel, atIndexPath indexPath: IndexPath) {
        switch file.fileStatus {
        case .synced:
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
            showFileActionSheet(file: file, atIndexPath: indexPath)

        case .downloading:
            viewModel?.cancelDownload()
            
            if let index = viewModel?.viewModels.firstIndex(where: { $0.recordId == file.recordId }) {
                viewModel?.viewModels[index].fileStatus = .synced
            }
            
            collectionView.reloadData()
            
        case .uploading, .waiting, .failed:
            break
        }
    }
    
    private func handleProgress(forFile file: FileViewModel, withValue value: Float) {
        guard let index = viewModel?.viewModels.firstIndex(where: { $0.recordId == file.recordId }),
            let downloadingCell = collectionView.cellForItem(at: IndexPath(row: index, section: 0)) as? FileCollectionViewCell
        else {
            return
        }
        
        downloadingCell.updateProgress(withValue: value)
    }

    public func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, shouldDisplaySpinner: Bool = true, then handler: VoidAction? = nil) {
        shouldDisplaySpinner ? showSpinner() : nil
        
        viewModel?.navigateMin(params: params, backNavigation: backNavigation, then: { status in
            self.onFilesFetchCompletion(status)
            handler?()
        })
        viewModel?.timer?.invalidate()
    }
    
    private func onFilesFetchCompletion(_ status: RequestStatus) {
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
            showErrorAlert(message: message)
        }
    }
    
    private func upload(files: [FileInfo]) {
        viewModel?.uploadFiles(files)
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
                self.refreshCurrentFolder()

            case .error(let message):
                self.showErrorAlert(message: message)
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

        cell.updateCell(model: file, fileAction: viewModel.fileAction, isGridCell: isGridView, isSearchCell: false, sharedFile: true)
        
        cell.rightButtonTapAction = { _ in
            self.handleCellRightButtonAction(for: file, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let file = viewModel?.fileForRowAt(indexPath: indexPath)
        let listItemHeight: CGFloat
        let gridItemHeight: CGFloat = UIScreen.main.bounds.width / 2 + 50
        if viewModel?.shareListType == .sharedByMe {
            listItemHeight = (file?.minArchiveVOS.count ?? 0) > 0 ? 90 : 70
        } else {
            listItemHeight = file?.sharedByArchive != nil ? 90 : 70
        }
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
        
        guard file.fileStatus == .synced && file.thumbnailURL != nil else { return }
        
        if file.type.isFolder {
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
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let section = indexPath.section
        let title = viewModel?.title(forSection: section) ?? ""
        
        if kind == UICollectionView.elementKindSectionHeader && title.isNotEmpty {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: "HeaderView", for: indexPath) as! FileCollectionViewHeader
            headerView.leftButtonTitle = title
            if viewModel?.shouldPerformAction(forSection: section) == true {
                headerView.leftButtonAction = { [weak self] header in self?.headerButtonAction(UIButton()) }
            } else {
                headerView.leftButtonAction = nil
            }
            
            if viewModel?.hasCancelButton(forSection: section) == true {
                headerView.rightButtonTitle = "Cancel All".localized()
                headerView.rightButtonAction = { [weak self] header in self?.cancelAllUploadsAction(UIButton()) }
            } else {
                headerView.rightButtonTitle = nil
                headerView.rightButtonAction = nil
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
        
        let indexPath = IndexPath(row: index, section: 0)
        collectionView.selectItem(at: indexPath, animated: true, scrollPosition: [])
    }
}

// MARK: - SharedFileActionSheetDelegate
extension SharesViewController: SharedFileActionSheetDelegate {
    func downloadAction(file: FileViewModel) {
        download(file)
    }
    
    func relocateAction(file: FileViewModel, action: FileAction) {
        viewModel?.selectedFile = file
        
        setupUIForAction(action)
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
        guard let actionSheet = UIViewController.create(
            withIdentifier: .fabActionSheet,
            from: .main
        ) as? FABActionSheet else {
            showAlert(title: .error, message: .errorMessage)
            return
        }

        actionSheet.delegate = self
        navigationController?.display(viewController: actionSheet, modally: true)
    }
}

// MARK: - FABActionSheetDelegate
extension SharesViewController: FABActionSheetDelegate {
    func didTapUpload() {
        showActionSheet()
    }
    
    func didTapNewFolder() {
        showActionDialog(
            styled: .singleField,
            withTitle: .createFolder,
            placeholders: [.folderName],
            positiveButtonTitle: .create,
            positiveAction: { self.newFolderAction() },
            overlayView: overlayView
        )
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
        PHPhotoLibrary.requestAuthorization { (authStatus) in
            switch authStatus {
            case .authorized, .limited:
                DispatchQueue.main.async {
                    let storyboard = UIStoryboard(name: "PhotoPicker", bundle: nil)
                    let imagePicker = storyboard.instantiateInitialViewController() as! PhotoTabBarViewController
                    imagePicker.pickerDelegate = self
                    
                    self.present(imagePicker, animated: true, completion: nil)
                }
                
            case .denied:
                let alertController = UIAlertController(title: "Photos permission required".localized(), message: "Please go to Settings and turn on the permissions.".localized(), preferredStyle: .alert)
                
                let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
                    guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                        return
                    }
                    if UIApplication.shared.canOpenURL(settingsUrl) {
                        UIApplication.shared.open(settingsUrl, completionHandler: { (success) in })
                    }
                }
                let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
                
                alertController.addAction(cancelAction)
                alertController.addAction(settingsAction)
                
                DispatchQueue.main.async {
                    self.present(alertController, animated: true, completion: nil)
                }
                
            default: break
            }
        }
    }
    
    func openFileBrowser() {
        let docPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String, kUTTypeContent as String], in: .import)
        
        docPicker.delegate = self
        docPicker.allowsMultipleSelection = true
        present(docPicker, animated: true, completion: nil)
    }
    
    private func processUpload(toFolder folder: FileViewModel, forURLS urls: [URL], loadInMemory: Bool = false) {
        let folderInfo = FolderInfo(folderId: folder.folderId, folderLinkId: folder.folderLinkId)
        
        let files = FileInfo.createFiles(from: urls, parentFolder: folderInfo, loadInMemory: loadInMemory)
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
        
        processUpload(toFolder: currentFolder, forURLS: urls)
    }
}

// MARK: - PhotoPickerViewControllerDelegate
extension SharesViewController: PhotoPickerViewControllerDelegate {
    func photoTabBarViewControllerDidPickAssets(_ vc: PhotoTabBarViewController?, assets: [PHAsset]) {
        viewModel?.didChooseFromPhotoLibrary(assets, completion: { [self] urls in
            guard let currentFolder = viewModel?.currentFolder else {
                return showErrorAlert(message: .cannotUpload)
            }
            
            processUpload(toFolder: currentFolder, forURLS: urls)
        })
    }
}
