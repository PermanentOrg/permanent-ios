//
//  SharesViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import UIKit

class SharesViewController: BaseViewController<SharedFilesViewModel> {
    @IBOutlet var directoryLabel: UILabel!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var switchViewButton: UIButton!
    private let refreshControl = UIRefreshControl()
    
    private var fileActionSheet: SharedFileActionSheet?
    
    private let overlayView = UIView()
    
    var selectedIndex: Int = 0
    
    var selectedFileId: Int?
    
    var isSharedFolder: Bool = false
    var sharedFolderArchiveNo: String = ""
    var sharedFolderLinkId: Int = -1
    var sharedFolderName: String = ""
    
    private var isGridView = false
    private var sortActionSheet: SortActionSheet?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = SharedFilesViewModel()
        
        let hasSavedFile = checkSavedFile()
        let hasSavedFolder = checkSavedFolder()
        
        configureUI()
        setupCollectionView()
        
        if !hasSavedFolder && !hasSavedFile {
            getShares()
            if isSharedFolder {
                isSharedFolder = false
                let navigateParams: NavigateMinParams = (sharedFolderArchiveNo, sharedFolderLinkId, nil)
                navigateToFolder(withParams: navigateParams, backNavigation: false, shouldDisplaySpinner: true, then: {
                    self.backButton.isHidden = false
                    self.directoryLabel.text = self.sharedFolderName
                })
            }
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
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
        styleNavBar()
    }
    
    fileprivate func setupCollectionView() {
        isGridView = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.isGridView) ?? false
        if #available(iOS 13.0, *) {
            switchViewButton.setImage(UIImage(systemName: isGridView ? "list.bullet" : "square.grid.2x2.fill"), for: .normal)
        } else {
            // Fallback on earlier versions
        }
        
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
    
    func checkSavedFile() -> Bool {
        var hasSavedFile = false
        if let sharedFile: ShareNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.sharedFileKey) {
            hasSavedFile = true
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.sharedFileKey)
            
            selectedIndex = ShareListType.sharedWithMe.rawValue
            
            func _presentFileDetails() {
                let currentArchive: ArchiveVOData? = viewModel?.currentArchive
                let permissions = currentArchive?.permissions() ?? [.read]
                let fileVM = FileViewModel(name: sharedFile.name, recordId: sharedFile.recordId, folderLinkId: sharedFile.folderLinkId, archiveNbr: sharedFile.archiveNbr, type: sharedFile.type, permissions: permissions)
                let filePreviewVC = UIViewController.create(withIdentifier: .filePreview, from: .main) as! FilePreviewViewController
                filePreviewVC.file = fileVM
                
                let fileDetailsNavigationController = FilePreviewNavigationController(rootViewController: filePreviewVC)
                fileDetailsNavigationController.filePreviewNavDelegate = self
                fileDetailsNavigationController.modalPresentationStyle = .fullScreen
                present(fileDetailsNavigationController, animated: true)
                
                // This has to be done after presentation, filePreviewVC has to have it's view loaded
                filePreviewVC.loadVM()
            }
            
            let currentArchive: ArchiveVOData? = viewModel?.currentArchive
            if currentArchive?.archiveNbr != sharedFile.toArchiveNbr {
                let action = { [weak self] in
                    self?.actionDialog?.dismiss()
                    
                    self?.viewModel?.changeArchive(withArchiveId: sharedFile.toArchiveId, archiveNbr: sharedFile.toArchiveNbr, completion: { success in
                        if success {
                            self?.getShares {
                                _presentFileDetails()
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
                    _presentFileDetails()
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
                        backButton.isHidden = false
                        directoryLabel.text = navigationParams.folderName
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
    
    @objc private func pullToRefreshAction() {
        refreshCurrentFolder(
            shouldDisplaySpinner: false,
            then: {
                self.refreshControl.endRefreshing()
            }
        )
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        guard let listType = ShareListType(rawValue: sender.selectedSegmentIndex) else {
            return
        }
        
        self.directoryLabel.text = "Shares".localized()
        self.backButton.isHidden = true
        
        viewModel?.shareListType = listType
        refreshCollectionView()
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
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
    
    @IBAction func switchViewButtonPressed(_ sender: Any) {
        isGridView.toggle()
        PreferencesManager.shared.set(isGridView, forKey: Constants.Keys.StorageKeys.isGridView)
        
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
        // Safety measure, in case the user taps to show sheet, but the previously shown one
        // has not finished dimissing and being deallocated.
        guard fileActionSheet == nil else { return }
        
        fileActionSheet = SharedFileActionSheet(
            frame: CGRect(origin: CGPoint(x: 0, y: view.bounds.height), size: view.bounds.size),
            title: file.name,
            file: file,
            indexPath: indexPath,
            hasDownloadButton: viewModel?.downloadInProgress == false,
            onDismiss: {
                self.collectionView.deselectItem(at: indexPath, animated: true)
                self.view.dismissPopup(
                    self.fileActionSheet,
                    overlayView: self.overlayView,
                    completion: { _ in
                        self.fileActionSheet?.removeFromSuperview()
                        self.fileActionSheet = nil
                    }
                )
            }
        )
        
        fileActionSheet?.delegate = self
        view.addSubview(fileActionSheet!)
        view.presentPopup(fileActionSheet, overlayView: overlayView)
    }

    fileprivate func getShares(shouldShowSpinner: Bool = true, completion: (() -> Void)? = nil) {
        if shouldShowSpinner {
            showSpinner()
        }
        
        viewModel?.getShares(then: { status in
            self.hideSpinner()
            switch status {
            case .success:
                self.refreshCollectionView {
                    self.scrollToFileIfNeeded()
                    
                    self.directoryLabel.text = "Shares".localized()
                    self.backButton.isHidden = true
                }
                
            case .error(let message):
                self.showErrorAlert(message: message)
            }
            
            if let completion = completion {
                completion()
            }
        })
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
        
        // Clear the data before navigation so we avoid concurrent errors.
        viewModel?.viewModels.removeAll()
        
        self.collectionView.reloadData()
        
        viewModel?.navigateMin(params: params, backNavigation: backNavigation, then: { status in
            self.onFilesFetchCompletion(status)
            handler?()
        })
    }
    
    private func onFilesFetchCompletion(_ status: RequestStatus) {
        DispatchQueue.main.async {
            self.hideSpinner()
        }

        switch status {
        case .success:
            DispatchQueue.main.async {
                self.refreshCollectionView()
            }
            
        case .error(let message):
            showErrorAlert(message: message)
        }
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
        cell.updateCell(model: file, fileAction: viewModel.fileAction, isGridCell: isGridView, isSearchCell: false)
        
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
            
            headerView.rightButtonTitle = nil
            headerView.rightButtonAction = nil
            
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
