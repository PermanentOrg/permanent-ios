//
//  MainViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import BSImagePicker
import MobileCoreServices
import Photos
import UIKit
import WebKit

class MainViewController: BaseViewController<MyFilesViewModel> {
    @IBOutlet var directoryLabel: UILabel!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var fabView: FABView!
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var fileActionBottomView: BottomActionSheet!
    
    private let overlayView = UIView()
    private let refreshControl = UIRefreshControl()
    private let screenLockManager = ScreenLockManager()

    private var sortActionSheet: SortActionSheet?
    private var fileActionSheet: FileActionSheet?
    private var isSearchActive: Bool = false
    private lazy var mediaRecorder = MediaRecorder(presentationController: self, delegate: self)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        setupTableView()
        setupBottomActionSheet()
        
        viewModel = MyFilesViewModel()
        fabView.delegate = self
        searchBar.delegate = self
        
        getRootFolder()
        
        NotificationCenter.default.addObserver(forName: UploadManager.didRefreshQueueNotification, object: nil, queue: nil) { [weak self] notif in
            if (self?.viewModel?.refreshUploadQueue() ?? false) && (self?.viewModel?.queueItemsForCurrentFolder.count ?? 0 > 0) {
                self?.refreshTableView()
            }
        }
        
        NotificationCenter.default.addObserver(forName: UploadManager.quotaExceededNotification, object: nil, queue: nil) { [weak self] notif in
            let alertVC = UIAlertController(title: "Quota Exceeded".localized(), message: "Do you want to add more storage?".localized(), preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: "Add Storage", style: .default, handler: { action in
                guard let url = URL(string: APIEnvironment.defaultEnv.buyStorageURL) else { return }
                UIApplication.shared.open(url)
            }))
            
            self?.present(alertVC, animated: true, completion: nil)
        }
        
        NotificationCenter.default.addObserver(forName: UploadOperation.uploadFinishedNotification, object: nil, queue: nil) { [weak self] notif in
            // if the upload is in this screen's list, refresh the list of models
            if self?.viewModel?.currentFolder?.folderLinkId == (notif.object as! UploadOperation).file.folder.folderLinkId && (notif.userInfo?["error"] == nil) {
                self?.refreshCurrentFolder()
            }
        }
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
        navigationItem.title = .myFiles
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .white
        
        styleNavBar()
        
        directoryLabel.font = Text.style3.font
        directoryLabel.textColor = .primary
        backButton.tintColor = .primary
        backButton.isHidden = true
        
        searchBar.setDefaultStyle(placeholder: .searchFiles)
        
        fileActionBottomView.isHidden = true
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
    }
    
    fileprivate func setupTableView() {
        tableView.registerNib(cellClass: FileTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.refreshControl = refreshControl
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        
        refreshControl.tintColor = .primary
        refreshControl.addTarget(self, action: #selector(pullToRefreshAction), for: .valueChanged)
    }
    
    func refreshTableView() {
        handleTableBackgroundView()
        tableView.reloadData()
    }
    
    func handleTableBackgroundView() {
        guard viewModel?.shouldDisplayBackgroundView == false else {
            tableView.backgroundView = EmptyFolderView(title: .emptyFolderMessage,
                                                       image: .emptyFolder)
            return
        }

        tableView.backgroundView = nil
    }
    
    func invalidateSearchBarIfNeeded() {
        guard viewModel?.isSearchActive == true else {
            return
        }
        
        searchBar.text = ""
        viewModel?.isSearchActive = false
        viewModel?.searchViewModels.removeAll()
        view.endEditing(true)
    }
    
    fileprivate func setupBottomActionSheet() {
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
            fabView.isHidden = false
            fileActionBottomView.isHidden = true
            
        case .move, .copy:
            fabView.isHidden = true
            fileActionBottomView.isHidden = false
            fileActionBottomView.setActionTitle(action.title)
            toggleFileAction(action)
        }
        
        DispatchQueue.main.async {
            self.refreshTableView()
        }
    }
    
    fileprivate func toggleFileAction(_ action: FileAction?) {
        // If we try to move file in the same folder, disable the button
        let shouldDisableButton = viewModel?.selectedFile?.parentFolderId == viewModel?.currentFolder?.folderId && action == .move
        fileActionBottomView.toggleActionButton(enabled: !shouldDisableButton)
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
        
        invalidateSearchBarIfNeeded()
        let navigateParams: NavigateMinParams = (destinationFolder.archiveNo, destinationFolder.folderLinkId, nil)
        navigateToFolder(withParams: navigateParams, backNavigation: true, then: {
            self.directoryLabel.text = destinationFolder.name
            
            // If we got to the root, hide the back button.
            if viewModel.currentFolderIsRoot {
                self.backButton.isHidden = true
            }
        })
    }
    
    private func refreshCurrentFolder(shouldDisplaySpinner: Bool = true,
                                      then handler: VoidAction? = nil)
    {
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
        navigateToFolder(withParams: params,
                         backNavigation: true,
                         shouldDisplaySpinner: shouldDisplaySpinner,
                         then: handler)
    }
    
    @objc
    private func pullToRefreshAction() {
        refreshCurrentFolder(
            shouldDisplaySpinner: false,
            then: {
                self.refreshControl.endRefreshing()
            }
        )
    }
    
    private func handleProgress(withValue value: Float, listSection section: FileListType) {
        let indexPath = IndexPath(row: 0, section: section.rawValue)
        
        guard
            let uploadingCell = tableView.cellForRow(at: indexPath) as? FileTableViewCell
        else {
            return
        }
        
        uploadingCell.updateProgress(withValue: value)
    }
    
    @objc
    private func removeFromQueue(atPosition position: Int) {
        viewModel?.removeFromQueue(position)
    }
    
    @objc
    private func headerButtonAction(_ sender: UIButton) {
        showSortActionSheetDialog()
    }
    
    @objc
    private func cancelAllUploadsAction(_ sender: UIButton) {
        let title = "Confirmation".localized()
        let description = "Are you sure you want to cancel all uploads?".localized()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showActionDialog(styled: .simpleWithDescription,
                                  withTitle: title,
                                  description: description,
                                  positiveButtonTitle: .cancelAll,
                                  positiveAction: {
                                    self.actionDialog?.dismiss()
                                    self.viewModel?.cancelUploadsInFolder()
                                  },
                                  cancelButtonTitle: "No".localized(),
                                  positiveButtonColor: .brightRed,
                                  cancelButtonColor: .primary,
                                  overlayView: self.overlayView)
        }
    }
    
    // MARK: - Network Related
    
    private func getRootFolder() {
        showSpinner()
        
        viewModel?.getRoot(then: { status in
            self.onFilesFetchCompletion(status)
            self.checkForSavedUniversalLink()
            self.checkForSavedShareFile()
            self.checkForRequestShareAccess()
        })
    }
    
    private func navigateToFolder(withParams params: NavigateMinParams,
                                  backNavigation: Bool,
                                  shouldDisplaySpinner: Bool = true,
                                  then handler: VoidAction? = nil) {
        shouldDisplaySpinner ? showSpinner() : nil
        
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
            self.refreshTableView()
            self.toggleFileAction(self.viewModel?.fileAction)
            
            if let userName = UserDefaults.standard.string(forKey: Constants.Keys.StorageKeys.signUpNameStorageKey) {
                self.displayWelcomePage(archiveName: userName)
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
    
    fileprivate func checkForSavedShareFile() {
        guard
            let sharedFile: ShareNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.sharedFileKey),
            let sharePreviewVC = UIViewController.create(withIdentifier: .filePreview, from: .main) as? FilePreviewViewController
        else {
            return
        }
        
        let fileVM = FileViewModel(name: sharedFile.name, recordId: sharedFile.recordId, folderLinkId: sharedFile.folderLinkId, archiveNbr: sharedFile.archiveNbr, type: sharedFile.type)
        sharePreviewVC.file = fileVM
        
        let fileDetailsNavigationController = FilePreviewNavigationController(rootViewController: sharePreviewVC)
        fileDetailsNavigationController.filePreviewNavDelegate = self
        fileDetailsNavigationController.modalPresentationStyle = .fullScreen
        present(fileDetailsNavigationController, animated: true)
        
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.sharedFileKey)
    }
    
    fileprivate func checkForRequestShareAccess() {
        guard
            let sharedFilePayload: RequestLinkAccessNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.requestLinkAccess),
            let shareVC = UIViewController.create(withIdentifier: .share, from: .share) as? ShareViewController
        else {
            return
        }
        
        let file = FileViewModel(name: sharedFilePayload.name, recordId: 0, folderLinkId: sharedFilePayload.folderLinkId, archiveNbr: "0", type: FileType.miscellaneous.rawValue)
        shareVC.sharedFile = file
        
        let shareNavController = FilePreviewNavigationController(rootViewController: shareVC)
        present(shareNavController, animated: true)
        
        PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.requestLinkAccess)
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
                    self.refreshTableView()
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
                    self.tableView.deleteRows(at: [indexPath], with: .automatic)
                    self.refreshTableView()
                }
                
            case .error(let message):
                self.showErrorAlert(message: message)
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
                
                DispatchQueue.main.async {
                    self.view.showNotificationBanner(height: Constants.Design.bannerHeight,
                                                     title: self.viewModel?.fileAction.action ?? .success)
                    self.setupUIForAction(.none)
                }
                
            case .error(let message):
                self.showErrorAlert(message: message)
            }
        })
    }
    
    func displayWelcomePage(archiveName: String) {
        let vc = UIViewController.create(withIdentifier: .welcomePage, from: .onboarding) as! WelcomePageViewController
        vc.archiveName = archiveName
        self.present(vc, animated: true, completion: nil)
    }
}

// MARK: - Table View Delegates

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel?.numberOfSections ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.numberOfRowsInSection(section) ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = self.viewModel else {
            return UITableViewCell()
        }

        let cell = tableView.dequeue(cellClass: FileTableViewCell.self, forIndexPath: indexPath)
        let file = viewModel.fileForRowAt(indexPath: indexPath)
        cell.updateCell(model: file, fileAction: viewModel.fileAction)
        
        cell.rightButtonTapAction = { _ in
            self.handleCellRightButtonAction(for: file, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let viewModel = viewModel else { return }

        let file = viewModel.fileForRowAt(indexPath: indexPath)
        
        guard file.fileStatus == .synced && file.thumbnailURL != nil else { return }
        
        if file.type.isFolder {
            invalidateSearchBarIfNeeded()
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
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard viewModel?.numberOfRowsInSection(section) != 0 else {
            return nil
        }
        
        let headerView = UIView()
        headerView.backgroundColor = .backgroundPrimary
        
        let sectionTitleButton = UIButton()
        sectionTitleButton.setTitle(viewModel?.title(forSection: section), for: [])
        sectionTitleButton.setFont(Text.style11.font)
        sectionTitleButton.setTitleColor(.middleGray, for: [])
        
        if viewModel?.shouldPerformAction(forSection: section) == true {
            sectionTitleButton.addTarget(self, action: #selector(headerButtonAction(_:)), for: .touchUpInside)
        }
        
        headerView.addSubview(sectionTitleButton)
        sectionTitleButton.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sectionTitleButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            sectionTitleButton.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20)
        ])
        
        if viewModel?.hasCancelButton(forSection: section) == true {
            let cancelButton = UIButton()
            cancelButton.setTitle("Cancel All".localized(), for: [])
            cancelButton.setFont(Text.style11.font)
            cancelButton.setTitleColor(.darkBlue, for: [])
            cancelButton.addTarget(self, action: #selector(cancelAllUploadsAction(_:)), for: .touchUpInside)
            
            headerView.addSubview(cancelButton)
            cancelButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                cancelButton.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
                cancelButton.trailingAnchor.constraint(equalTo: headerView.trailingAnchor, constant: -10)
            ])
        }
        
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard viewModel?.numberOfRowsInSection(section) != 0 else {
            return 0
        }

        return 40
    }
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        guard let viewModel = viewModel else {
            fatalError()
        }
        
        let selectedFile = viewModel.fileForRowAt(indexPath: indexPath)
        
        let moreAction = UIContextualAction.make(
            withImage: .moreAction,
            backgroundColor: .middleGray,
            handler: { _, _, completion in
                self.showFileActionSheet(file: selectedFile, atIndexPath: indexPath)
                completion(true)
            }
        )
        
        let deleteAction = UIContextualAction.make(
            withImage: .deleteAction,
            backgroundColor: .destructive,
            handler: { _, _, completion in
                self.didTapDelete(forFile: selectedFile, atIndexPath: indexPath)
                completion(true)
            }
        )
        
        return UISwipeActionsConfiguration(actions: [
            moreAction,
            deleteAction
        ])
    }
    
    private func cellRightButtonAction(atPosition position: Int) {
        removeFromQueue(atPosition: position)
    }
    
    private func handleCellRightButtonAction(for file: FileViewModel, atIndexPath indexPath: IndexPath) {
        switch file.fileStatus {
        case .synced:
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none) // test
            showFileActionSheet(file: file, atIndexPath: indexPath)
            
        case .downloading:
            
            viewModel?.cancelDownload()
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        case .uploading, .waiting:
            cellRightButtonAction(atPosition: indexPath.row)
        }
    }
    
    private func didTapDelete(forFile file: FileViewModel, atIndexPath indexPath: IndexPath) {
        let title = String(format: "\(String.delete) \"%@\"?", file.name)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showActionDialog(styled: .simple,
                                  withTitle: title,
                                  positiveButtonTitle: .delete,
                                  positiveAction: {
                                      self.actionDialog?.dismiss()
                                      self.deleteFile(file, atIndexPath: indexPath)
                                  }, overlayView: self.overlayView)
        }
    }
    
    private func didTapRelocate(source: FileViewModel, destination: FileViewModel) {
        guard let fileAction = viewModel?.fileAction else { return }
        
        let title = String(format: "\(fileAction.title) \"%@\"?", source.name)
        
        showActionDialog(styled: .simple,
                         withTitle: title,
                         positiveButtonTitle: fileAction.title,
                         positiveAction: {
                             self.actionDialog?.dismiss()
                             self.relocate(file: source, to: destination)
                         }, overlayView: overlayView)
    }
    
    private func download(_ file: FileViewModel) {
        viewModel?.download(
            file,
            
            onDownloadStart: {
                DispatchQueue.main.async {
                    self.refreshTableView()
                }
            },
            
            onFileDownloaded: { url, error in
                DispatchQueue.main.async {
                    self.onFileDownloaded(url: url, error: error)
                }
            },
            
            progressHandler: { progress in
                DispatchQueue.main.async {
                    self.handleProgress(withValue: progress, listSection: FileListType.downloading)
                }
            }
        )
    }
    
    fileprivate func onFileDownloaded(url: URL?, error: Error?) {
        refreshTableView()
        
        guard let _ = url else {
            let apiError = (error as? APIError) ?? .unknown
            
            if apiError == .cancelled {
                view.showNotificationBanner(height: Constants.Design.bannerHeight, title: .downloadCancelled)
            } else {
                showErrorAlert(message: apiError.message)
            }

            return
        }
    }
}

extension MainViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            viewModel?.isSearchActive = false
        } else {
            viewModel?.isSearchActive = true
            viewModel?.searchFiles(byQuery: searchText)
        }
        
        refreshTableView()
    }
}

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

extension MainViewController: FABActionSheetDelegate {
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
        
        fileActionSheet = FileActionSheet(
            frame: CGRect(origin: CGPoint(x: 0, y: view.bounds.height), size: view.bounds.size),
            title: file.name,
            file: file,
            indexPath: indexPath,
            hasDownloadButton: viewModel?.downloadInProgress == false,
            onDismiss: {
                self.tableView.deselectRow(at: indexPath, animated: true)
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
        PHPhotoLibrary.requestAuthorization { (auth_status) in
            switch auth_status {
            case .authorized,.limited:
                let imagePicker = ImagePickerController()
                imagePicker.settings.fetch.assets.supportedMediaTypes = [.image, .video]
                let options = imagePicker.settings.fetch.album.options
                imagePicker.settings.fetch.album.fetchResults = [
                    PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumUserLibrary, options: options),
                    PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumFavorites, options: options),
                    PHAssetCollection.fetchAssetCollections(with: .album, subtype: .albumRegular, options: options),
                    PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumSelfPortraits, options: options),
                    PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumPanoramas, options: options),
                    PHAssetCollection.fetchAssetCollections(with: .smartAlbum, subtype: .smartAlbumVideos, options: options)
                ]
                self.presentImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil, finish: { assets in
                    self.viewModel?.didChooseFromPhotoLibrary(assets, completion: { urls in
                        
                        guard let currentFolder = self.viewModel?.currentFolder else {
                            return self.showErrorAlert(message: .cannotUpload)
                        }
                        self.processUpload(toFolder: currentFolder, forURLS: urls)
                    })
                })
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
        let docPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeItem as String,
                                                                       kUTTypeContent as String],
                                                       in: .import)
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
extension MainViewController: FileActionSheetDelegate {
    func share(file: FileViewModel) {
        guard
            let shareVC = UIViewController.create(
                withIdentifier: .share,
                from: .share
            ) as? ShareViewController
        else {
            return
        }

        shareVC.sharedFile = file
        
        let shareNavController = FilePreviewNavigationController(rootViewController: shareVC)
        present(shareNavController, animated: true)
    }
    
    func deleteAction(file: FileViewModel, atIndexPath indexPath: IndexPath) {
        didTapDelete(forFile: file, atIndexPath: indexPath)
    }
    
    func downloadAction(file: FileViewModel) {
        fileActionSheet?.dismiss()
        download(file)
    }
    
    func relocateAction(file: FileViewModel, action: FileAction) {
        viewModel?.selectedFile = file
        
        setupUIForAction(action)
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
        
    }
}

