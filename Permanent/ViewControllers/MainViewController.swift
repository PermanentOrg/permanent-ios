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

class MainViewController: BaseViewController<MyFilesViewModel> {
    @IBOutlet var directoryLabel: UILabel!
    @IBOutlet var backButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet var fabView: FABView!
    @IBOutlet var fileActionBottomView: BottomActionSheet!
    @IBOutlet weak var switchViewButton: UIButton!
    
    private var isGridView = false
    
    private let overlayView = UIView()
    private let refreshControl = UIRefreshControl()
    private let screenLockManager = ScreenLockManager()

    private var sortActionSheet: SortActionSheet?
    private lazy var mediaRecorder = MediaRecorder(presentationController: self, delegate: self)
    
    let fileHelper = FileHelper()
    let documentInteractionController = UIDocumentInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        setupCollectionView()
        setupBottomActionSheet()
        
        fabView.delegate = self
        
        getRootFolder()
        
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
                    self?.viewModel?.viewModels.insert(FileViewModel(model: uploadedFile, archiveThumbnailURL: "", permissions: [], accessRole: self?.viewModel?.archiveAccessRole ?? .viewer), at: 0)
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
            
            self?.viewModel?.viewModels[index].accessRole = shareLinkVM.fileViewModel.accessRole
            self?.viewModel?.viewModels[index].minArchiveVOS = shareLinkVM.fileViewModel.minArchiveVOS
            
            self?.collectionView.reloadData()
        }
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
            let searchButton = UIBarButtonItem(barButtonSystemItem: .search, target: self, action: #selector(searchButtonPressed(_:)))
            navigationItem.rightBarButtonItems = [rightBarItem, searchButton]
        }
        
        if viewModel!.isPickingImage {
            let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
            navigationItem.leftBarButtonItem = cancelButton
        }
        
        styleNavBar()
        
        directoryLabel.font = Text.style3.font
        directoryLabel.textColor = .primary
        directoryLabel.text = viewModel?.rootFolderName
        backButton.tintColor = .primary
        backButton.isHidden = true
        
        fileActionBottomView.isHidden = true
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
        fabView.isHidden = viewModel!.archivePermissions.contains(.create) == false || viewModel!.archivePermissions.contains(.upload) == false || viewModel!.isPickingImage
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
        collectionView.register(FileCollectionViewHeaderCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FileCollectionViewHeaderCell.identifier)
        
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
    
    func refreshCollectionView() {
        handleTableBackgroundView()
        collectionView.reloadData()
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
        guard let source = viewModel?.selectedFile,
              let action = viewModel?.fileAction else { return }
              
        fabView.isHidden = true
        
        guard floatingActionIsland == nil else { return }
        
        let fileIconItem: FloatingActionImageItem
        if let url = URL(string: source.thumbnailURL), !source.type.isFolder {
            fileIconItem = FloatingActionImageItem(url: url, contentMode: .scaleAspectFill, action: nil)
        } else {
            fileIconItem = FloatingActionImageItem(image: UIImage(named: "folderIconFigma")!, action: nil)
        }
        
        let leftItems = [
            fileIconItem,
            FloatingActionTextSubtitleItem(text: action == .copy ? "COPYING".localized() : "MOVING".localized(), subtitle: source.name, action: nil),
        ]

        let closeImage = UIImage(named: "xMarkToolbarIcon")!
        let pasteTitle = action == .copy ? "Paste Here".localized() : "Move Here".localized()
        let rightItems = [
            FloatingActionImageTextItem(text: pasteTitle, image: UIImage(named: "pasteToolbarIcon")!) { [weak self] _, _ in
                guard let destination = self?.viewModel?.currentFolder else {
                    self?.showErrorAlert(message: .errorMessage)
                    return
                }

                self?.relocate(file: source, to: destination)
            },
            FloatingActionImageItem(image: closeImage) { [weak self] vc, item in
                self?.dismissFloatingActionIsland()
                self?.fabView.isHidden = false

                self?.viewModel?.selectedFile = nil
                self?.viewModel?.fileAction = .none

                self?.collectionView?.reloadData()
            },
        ]
        showFloatingActionIsland(withLeftItems: leftItems, rightItems: rightItems)

        collectionView?.reloadData()
    }
    
    fileprivate func toggleFileAction(_ action: FileAction?) {
        // If we try to move file in the same folder, disable the button
        let shouldDisableButton = viewModel?.selectedFile?.parentFolderId == viewModel?.currentFolder?.folderId && action == .move
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
    
    private func refreshCurrentFolder(shouldDisplaySpinner: Bool = true, then handler: VoidAction? = nil) {
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
        navigateToFolder(withParams: params, backNavigation: true, shouldDisplaySpinner: shouldDisplaySpinner, then: handler)
    }
    
    @objc
    private func pullToRefreshAction() {
        refreshCurrentFolder(
            shouldDisplaySpinner: false,
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
        clearButtonWasPressed(UIButton())
    }
    
    @objc
    private func headerButtonAction(_ sender: UIButton) {
        showSortActionSheetDialog()
    }
    
    @objc
    private func cancelAllUploadsAction(_ sender: UIButton) {
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
    
    @objc
    private func selectButtonWasPressed(_ sender: UIButton) {
        guard var selectWasPressed = viewModel?.selectWasPressed,
              let numberOfItems = viewModel?.isItemSelected.count else { return }
        fabView.isHidden = true

        if selectWasPressed {
            viewModel?.isItemSelected = [Bool](repeating: true, count: numberOfItems)
        } else {
            viewModel?.isItemSelected = [Bool](repeating: false, count: numberOfItems)
        }
        
        viewModel?.selectWasPressed = true
        refreshCollectionView()
    }
    
    @objc
    private func clearButtonWasPressed(_ sender: UIButton) {
        fabView.isHidden = false
        if let numberOfItems = viewModel?.isItemSelected.count {
            viewModel?.isItemSelected = [Bool?](repeating: nil, count: numberOfItems)
            viewModel?.selectWasPressed = false
            collectionView.reloadData()
        }
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
    
    @objc func searchButtonPressed(_ sender: Any) {
        guard let searchVC = UIViewController.create(withIdentifier: .search, from: .main) as? SearchViewController else {
            return
        }
        
        let navController = NavigationController(rootViewController: searchVC)
        navController.modalPresentationStyle = .fullScreen
        present(navController, animated: false)
    }
    
    // MARK: - Network Related
    
    private func getRootFolder() {
        showSpinner()
        
        viewModel?.getRoot(then: { status in
            self.onFilesFetchCompletion(status)
            self.checkForSavedUniversalLink()
            self.checkForRequestShareAccess()
        })
    }
    
    private func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, shouldDisplaySpinner: Bool = true, then handler: VoidAction? = nil) {
        shouldDisplaySpinner ? showSpinner() : nil
        
        viewModel?.navigateMin(params: params, backNavigation: backNavigation, then: { status in
            self.onFilesFetchCompletion(status)
            handler?()
            self.clearButtonWasPressed(UIButton())
        })
        viewModel?.timer?.invalidate()
    }
    
    private func onFilesFetchCompletion(_ status: RequestStatus) {
        DispatchQueue.main.async {
            self.hideSpinner()
        }
        
        viewModel?.refreshUploadQueue()

        switch status {
        case .success:
            refreshCollectionView()
            toggleFileAction(viewModel?.fileAction)
            
            let pendingInvitations = UserDefaults.standard.integer(forKey: Constants.Keys.StorageKeys.signUpInvitationsAccepted)
            if pendingInvitations != 0 {
                displayWelcomePage()
            }
            
        case .error(let message):
            showErrorAlert(message: message)
        }
    }
    
    fileprivate func checkForSavedUniversalLink() {
        guard
            let token: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.shareURLToken),
            let sharePreviewVC = UIViewController.create(
                withIdentifier: .sharePreview,
                from: .share
            ) as? SharePreviewViewController
        else {
            return
        }
        
        let viewModel = SharePreviewViewModel()
        viewModel.urlToken = token
        sharePreviewVC.viewModel = viewModel
        
        navigationController?.display(viewController: sharePreviewVC)
    }
    
    func checkForRequestShareAccess() {
        guard
            let sharedFilePayload: RequestLinkAccessNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.requestLinkAccess)
        else {
            return
        }
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.requestLinkAccess)
        
        func _presentShare() {
            let file = FileViewModel(name: sharedFilePayload.name, recordId: 0, folderLinkId: sharedFilePayload.folderLinkId, archiveNbr: "0", type: FileType.miscellaneous.rawValue, permissions: viewModel!.archivePermissions)
            
            showFileActionSheet(file: file, atIndexPath: [0, 0])
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
                DispatchQueue.main.async {
                    self.refreshCollectionView()
                }

            case .error(let message):
                self.showErrorAlert(message: message)
            }
        })
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
        floatingActionIsland?.showActivityIndicator()
        viewModel?.relocate(file: file, to: destination, then: { status in
            self.floatingActionIsland?.hideActivityIndicator()

            switch status {
            case .success:
                self.viewModel?.viewModels.prepend(file)

                self.floatingActionIsland?.showDoneCheckmark() {
                    self.dismissFloatingActionIsland()

                    self.collectionView?.reloadData()
                }

                
            case .error(let message):
                self.dismissFloatingActionIsland()
                self.showErrorAlert(message: message)
            }
        })
    }
    
    func publish(file: FileViewModel) {
        showSpinner()
        viewModel?.publish(file: file, then: { status in
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
    
    func displayWelcomePage() {
        let vc = UIViewController.create(withIdentifier: .welcomePage, from: .onboarding) as! WelcomePageViewController
        self.present(vc, animated: true, completion: nil)
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
        cell.updateCell(model: file, fileAction: viewModel.fileAction, isGridCell: isGridView, isSearchCell: false, isItemSelected: viewModel.isItemSelected[indexPath.item])
        
        cell.moreButton.isHidden = cell.moreButton.isHidden || viewModel.isPickingImage
        cell.rightButtonImageView.isHidden = cell.rightButtonImageView.isHidden || viewModel.isPickingImage
        
        cell.rightButtonTapAction = { _ in
            self.handleCellRightButtonAction(for: file, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let listItemSize = CGSize(width: UIScreen.main.bounds.width, height: 70)
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
        
        guard file.fileStatus == .synced && file.thumbnailURL != nil else { return }
        
        if viewModel.selectWasPressed {
            viewModel.isItemSelected[indexPath.item]?.toggle()
            self.refreshCollectionView()
        } else {
            if file.type.isFolder {
                viewModel.selectWasPressed = false
                let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, nil)
                navigateToFolder(withParams: navigateParams, backNavigation: false, then: {
                    self.backButton.isHidden = false
                    self.directoryLabel.text = file.name
                })
            } else {
                if viewModel.isPickingImage {
                    handleImagePickerSelection(file: file)
                } else {
                    handlePreviewSelection(file: file)
                }
            }
        }
    }
    
    func handleImagePickerSelection(file: FileViewModel) {
        guard let viewModel = viewModel else { return }
        
        viewModel.pickerDelegate?.myFilesVMDidPickFile(viewModel: viewModel, file: file)
    }
    
    func handlePreviewSelection(file: FileViewModel) {
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
            if viewModel?.shouldPerformAction(forSection: section) == true {
                headerView.leftButtonAction = { [weak self] header in self?.headerButtonAction(UIButton()) }
            } else {
                headerView.leftButtonAction = nil
            }
            
            if viewModel?.hasCancelButton(forSection: section) == true {
                headerView.rightButtonTitle = "Cancel All".localized()
                headerView.rightButtonImageIsVisible = false
                headerView.rightButtonAction = { [weak self] header in self?.cancelAllUploadsAction(UIButton()) }
            } else {
                if let selectWasPressed = viewModel?.selectWasPressed, selectWasPressed {
                    headerView.rightButtonTitle = "Select all  ".localized()
                    headerView.rightButtonImageIsVisible = true
                    headerView.clearButtonIsVisible = true
                } else {
                    headerView.rightButtonTitle = "Select".localized()
                    headerView.rightButtonImageIsVisible = false
                    headerView.clearButtonIsVisible = false
                }
                
                headerView.rightButtonAction = { [weak self] header in self?.selectButtonWasPressed(UIButton()) }
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
        pullToRefreshAction()
        viewModel?.updateTimerCount()
    }
}

// MARK: - Table View Delegates

extension MainViewController {
    private func handleCellRightButtonAction(for file: FileViewModel, atIndexPath indexPath: IndexPath) {
        switch file.fileStatus {
        case .synced:
            if let _ = viewModel?.isItemSelected[indexPath.item] {
                viewModel?.isItemSelected[indexPath.item]?.toggle()
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
    
    private func didTapPublish(source: FileViewModel) {
        let title = String(format: "\(String.publish) \"%@\"?", source.name)
        self.showActionDialog(
            styled: .simpleWithDescription,
            withTitle: title,
            description: .publishDescription,
            positiveButtonTitle: .publish,
            positiveAction: {
                self.actionDialog?.dismiss()
                self.publish(file: source)
            },
            overlayView: self.overlayView
        )
    }
    
    private func download(_ file: FileViewModel) {
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
extension MainViewController: FABActionSheetDelegate {
    func didTapUpload() {
        if viewModel is PublicFilesViewModel {
            let title = ""
            let description = "This is a public folder. Are you sure you want to upload here?".localized()
            showActionDialog(
                styled: .simpleWithDescription,
                withTitle: title,
                description: description,
                positiveButtonTitle: "Upload".localized(),
                positiveAction: { [weak self] in
                    self?.view.dismissPopup(
                        self?.actionDialog,
                        overlayView: self?.overlayView,
                        completion: { _ in
                            self?.actionDialog?.removeFromSuperview()
                            self?.actionDialog = nil
                            
                            self?.showActionSheet()
                        }
                    )
                },
                cancelButtonTitle: "Cancel".localized(),
                overlayView: overlayView
            )
        } else {
            showActionSheet()
        }
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

    func showFileActionSheet(file: FileViewModel, atIndexPath indexPath: IndexPath) {
        var menuItems: [FileMenuViewController.MenuItem] = []
        if file.permissions.contains(.share) {
            if file.type.isFolder == false {
                menuItems.append(FileMenuViewController.MenuItem(type: .shareToAnotherApp, action: { [self] in
                    shareWithOtherApps(file: file)
                }))
            }
            
            if file.permissions.contains(.ownership) && viewModel is PublicFilesViewModel == false {
                menuItems.append(FileMenuViewController.MenuItem(type: .shareToPermanent, action: nil))
            }
        }
        
        if let viewModel = viewModel as? PublicFilesViewModel, let url = viewModel.publicURL(forFile: file) {
            menuItems.append(FileMenuViewController.MenuItem(type: .getLink, action: { [self] in
                share(url: url)
            }))
        }
        
        if file.permissions.contains(.delete) && viewModel is PublicFilesViewModel == false {
            menuItems.append(FileMenuViewController.MenuItem(type: .publish, action: { [self] in
                publishAction(file: file)
            }))
        }
        
        if file.permissions.contains(.edit) {
            menuItems.append(FileMenuViewController.MenuItem(type: .rename, action: { [self] in
                renameAction(file: file, atIndexPath: indexPath)
            }))
        }
        
        if file.permissions.contains(.delete) {
            menuItems.append(FileMenuViewController.MenuItem(type: .delete, action: { [self] in
                deleteAction(file: file, atIndexPath: indexPath)
            }))
        }
        
        if file.permissions.contains(.move) {
            menuItems.append(FileMenuViewController.MenuItem(type: .move, action: { [self] in
                relocateAction(file: file, action: .move)
            }))
        }
        
        if file.permissions.contains(.create) {
            menuItems.append(FileMenuViewController.MenuItem(type: .copy, action: { [self] in
                relocateAction(file: file, action: .copy)
            }))
        }
        
        if file.permissions.contains(.read) && file.type.isFolder == false {
            menuItems.append(FileMenuViewController.MenuItem(type: .download, action: { [self] in
                downloadAction(file: file)
            }))
        }
        
        let vc = FileMenuViewController()
        vc.fileViewModel = file
        vc.menuItems = menuItems
        
        present(vc, animated: true)
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

// MARK: - Document Picker Delegate
extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let currentFolder = viewModel?.currentFolder else {
            return showErrorAlert(message: .cannotUpload)
        }
        
        processUpload(toFolder: currentFolder, forURLS: urls)
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
    func shareWithOtherApps(file: FileViewModel) {
        if let localURL = fileHelper.url(forFileNamed: file.uploadFileName) {
            share(url: localURL)
        } else {
            let preparingAlert = UIAlertController(title: "Preparing File..".localized(), message: nil, preferredStyle: .alert)
            preparingAlert.addAction(UIAlertAction(title: .cancel, style: .cancel, handler: { _ in
                self.viewModel?.cancelDownload() })
            )
            present(preparingAlert, animated: true) {
                self.viewModel?.download(file: file, onDownloadStart: { }, onFileDownloaded: { url, errorMessage in
                    if let url = url {
                        self.dismiss(animated: true) {
                            self.share(url: url)
                        }
                    } else {
                        self.dismiss(animated: true, completion: nil)
                    }
                })
            }
        }
    }
    
    private func share(url: URL) {
        // For now, dismiss the menu in case another one opens so we avoid crash.
        documentInteractionController.dismissMenu(animated: true)
        
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentOptionsMenu(from: .zero, in: view, animated: true)
    }
    
    func renameAction(file: FileViewModel, atIndexPath indexPath: IndexPath) {
        let title = String(format: "\(String.rename) \"%@\"", file.name)
        
        self.showActionDialog(
            styled: .singleField,
            withTitle: title,
            placeholders: ["Name".localized()],
            prefilledValues: ["\(file.name)"],
            positiveButtonTitle: .rename,
            positiveAction: {
                guard let inputName = self.actionDialog?.fieldsInput.first?.description else { return }
                if inputName.isEmpty {
                    self.view.showNotificationBanner(title: "Please enter a name".localized(), backgroundColor: .deepRed, textColor: .white, animationDelayInSeconds: Constants.Design.longNotificationBarAnimationDuration)
                } else {
                    self.actionDialog?.dismiss()
                    self.actionDialog = nil
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
    
    func downloadAction(file: FileViewModel) {
        download(file)
    }
    
    func relocateAction(file: FileViewModel, action: FileAction) {
        viewModel?.selectedFile = file
        viewModel?.fileAction = action
        
        setupBottomActionSheet()
    }
    
    func publishAction(file: FileViewModel) {
        didTapPublish(source: file)
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
    
    func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) { }
}

// MARK: - PhotoPickerViewControllerDelegate
extension MainViewController: PhotoPickerViewControllerDelegate {
    func photoTabBarViewControllerDidPickAssets(_ vc: PhotoTabBarViewController?, assets: [PHAsset]) {
        let alert = UIAlertController(title: "Preparing Files...".localized(), message: nil, preferredStyle: .alert)
        present(alert, animated: true)
        viewModel?.didChooseFromPhotoLibrary(assets, completion: { [self] urls in
            dismiss(animated: true) { [self] in
                guard let currentFolder = viewModel?.currentFolder else {
                    return showErrorAlert(message: .cannotUpload)
                }
                
                processUpload(toFolder: currentFolder, forURLS: urls)
            }
        })
    }
}
