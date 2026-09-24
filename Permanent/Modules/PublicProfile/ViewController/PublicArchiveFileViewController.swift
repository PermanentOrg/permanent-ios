//
//  PublicArchiveFileViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 01.12.2021.
//

import UIKit

class PublicArchiveFileViewController: BaseViewController<PublicArchiveViewModel> {
    @IBOutlet weak var directoryLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var linkButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    
    weak var delegate: PublicArchiveChildDelegate?
    
    var archiveData: ArchiveVOData!
    var deeplinkPayload: PublicProfileDeeplinkPayload?
    
    private var isGridView = true
    private lazy var folderHeader: FolderHeaderTransition? = {
        guard backButton != nil, directoryLabel != nil else { return nil }
        return FolderHeaderTransition(backButton: backButton, titleLabel: directoryLabel)
    }()
    /// How the last folder load ended, for flows that changed the header before it landed; nil while one runs.
    private var lastFolderLoadStatus: RequestStatus?
    private lazy var pagingSection = FileListPagingSection(collectionView: collectionView, viewModel: { [weak self] in self?.viewModel }, onChange: { [weak self] in self?.refreshCollectionView() })
    
    private let refreshControl = UIRefreshControl()
    
    let fileHelper = FileHelper()
    let documentInteractionController = UIDocumentInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = PublicArchiveViewModel()
        viewModel?.currentArchive = archiveData
        
        initUI()
        setupCollectionView()
        
        if !checkSavedFile() {
            getRootFolder()
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }

    // MARK: - UI Related
    
    fileprivate func initUI() {
        view.backgroundColor = .white

        styleNavBar()
        
        directoryLabel.font = TextFontStyle.style3.font
        directoryLabel.textColor = .primary
        directoryLabel.text = "Public"
        backButton.tintColor = .primary
        backButton.isHidden = true
        _ = folderHeader
        
        linkButton.tintColor = .primary
        linkButton.setTitle(nil, for: .normal)
    }
    
    fileprivate func setupCollectionView() {
        collectionView.register(UINib(nibName: "FileCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "FileCell")
        collectionView.register(UINib(nibName: "FileCollectionViewGridCell", bundle: nil), forCellWithReuseIdentifier: "FileGridCell")
        collectionView.register(FileCollectionViewHeaderCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FileCollectionViewHeaderCell.identifier)
        _ = pagingSection
        
        collectionView.refreshControl = refreshControl
        // The side gutters belong to `sectionInset`, not `contentInset`: the latter is re-resolved when the
        // view re-enters the window, and the layout can cache a pass against a momentarily zero inset.
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 60, right: 0)
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 6
        flowLayout.minimumLineSpacing = 0
        flowLayout.estimatedItemSize = .zero
        flowLayout.sectionInset = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 6)
        collectionView.collectionViewLayout = flowLayout
        
        refreshControl.tintColor = .primary
        refreshControl.addTarget(self, action: #selector(pullToRefreshAction), for: .valueChanged)
    }
    
    func refreshCollectionView() {
        handleTableBackgroundView()
        pagingSection.prepareForReload()
        collectionView.reloadData()
        #if DEBUG
        // Surface which navigation path served the current listing so UI parity tests can
        // confirm a "V2" run actually used Stela (not the silent V1 failsafe). DEBUG-only.
        collectionView.accessibilityIdentifier = "files-nav-source-\(FilesViewModel.lastNavigationSource)"
        #endif
    }
    
    func handleTableBackgroundView() {
        guard viewModel?.shouldDisplayBackgroundView == false else {
            collectionView.backgroundView = EmptyFolderView(title: .emptyFolderMessage, image: .emptyFolder)
            return
        }

        collectionView.backgroundView = nil
    }
    
    @IBAction
    func backButtonAction(_ sender: UIButton) {
        guard let viewModel = viewModel,
              let leftFolder = viewModel.removeCurrentFolderFromHierarchy(),
              let destinationFolder = viewModel.currentFolder
        else {
            return
        }
        
        let revertHeader = showHeaderWhileLoading(title: destinationFolder.name, showsBack: !viewModel.currentFolderIsRoot)
        let navigateParams: NavigateMinParams = (destinationFolder.archiveNo, destinationFolder.folderLinkId, nil)
        navigateToFolder(withParams: navigateParams, backNavigation: true, then: {
            // The folder left is still on screen, so it goes back on the history and keeps its header.
            guard self.folderLoadFailed(), viewModel.navigationStack.last?.folderLinkId == destinationFolder.folderLinkId else { return }
            viewModel.navigationStack.append(leftFolder)
            revertHeader()
        })
    }
    
    @IBAction func linkButtonPressed(_ sender: Any) {
        guard let file = viewModel?.currentFolder, let url = viewModel?.publicURL(forFile: file) else { return }
        
        share(url: url)
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
        navigateToFolder(withParams: params, backNavigation: true, shouldDisplaySpinner: shouldDisplaySpinner, isRefresh: true, then: handler)
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
    
    @objc
    private func headerButtonAction(_ sender: UIButton) {
//        showSortActionSheetDialog()
    }
    
    func checkSavedFile() -> Bool {
        if let deeplinkPayload = deeplinkPayload, let folderLinkId = deeplinkPayload.folderLinkId, let folderId = Int(folderLinkId) {
            self.deeplinkPayload = nil
            
            showSpinner()
            
            let navigationParams = (archiveNo: deeplinkPayload.archiveNbr, folderLinkId: folderId, folderName: "")
            viewModel?.getRoot(then: { status in
                // The link carries no name, so only the arrow can show before the folder loads.
                let revertHeader = self.showHeaderWhileLoading(title: self.folderHeader?.current.title, showsBack: true, entering: folderId)
                self.navigateToFolder(withParams: navigationParams, backNavigation: false, then: {
                    guard !self.folderLoadFailed(entering: folderId) else { return revertHeader() }
                    self.folderHeader?.show(title: self.viewModel?.currentFolder?.name, showsBack: true)
                    
                    // The linked file can sit on a later page than the first.
                    self.viewModel?.loadChildrenPages(until: { $0.archiveNo == deeplinkPayload.fileArchiveNbr }) { [weak self] file in
                        guard let self, self.viewIfLoaded?.window != nil else { return }
                        self.refreshCollectionView()
                        if let file { self.presentFileDetails(file: file) }
                    }
                })
            })
            
            return true
        }
        
        return false
    }
    
    func presentFileDetails(file: FileModel) {
        let listPreviewVC = FilePreviewListViewController(nibName: nil, bundle: nil)
        listPreviewVC.modalPresentationStyle = .fullScreen
        listPreviewVC.viewModel = viewModel
        listPreviewVC.currentFile = file
        
        let fileDetailsNavigationController = FilePreviewNavigationController(rootViewController: listPreviewVC)
        fileDetailsNavigationController.filePreviewNavDelegate = self
        fileDetailsNavigationController.modalPresentationStyle = .fullScreen
        
        present(fileDetailsNavigationController, animated: true)
    }
    
    // MARK: - Network Related
    
    private func getRootFolder(isRetry: Bool = false) {
        // The retry runs under the skeleton the first attempt put up.
        if !isRetry { setLoadingFirstPage(true) }

        viewModel?.getRoot(then: { [weak self] status in
            guard let self = self else { return }
            // Opening a foreign archive fires several authenticated fetches on a cold connection, where the
            // first can fail transiently. Retry once; the flag is a parameter so each load gets its own.
            if case .error = status, !isRetry {
                self.getRootFolder(isRetry: true)
                return
            }
            let finish = {
                self.setLoadingFirstPage(false)
                if status != .success, self.collectionView != nil { self.dropRootSkeleton() }
                self.onFilesFetchCompletion(status)
            }
            self.collectionView != nil ? self.pagingSection.afterSkeletonMinimumTime(finish) : finish()
        })
    }
    
    private func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, shouldDisplaySpinner: Bool = true, isRefresh: Bool = false, then handler: VoidAction? = nil) {
        // Entering a folder shows skeleton tiles; refreshing the one on screen keeps its tiles under the spinner.
        let showsSkeleton = shouldDisplaySpinner && !isRefresh
        if showsSkeleton {
            setLoadingFirstPage(true)
        } else if shouldDisplaySpinner {
            showSpinner()
        }
        
        viewModel?.navigateMin(params: params, backNavigation: backNavigation, then: { status in
            // The skeleton stays up for its minimum time, so it fades out rather than flickers.
            let finish = {
                if showsSkeleton {
                    self.setLoadingFirstPage(false)
                    // On failure the previous folder's rows come back from under the skeleton.
                    if status != .success, self.collectionView != nil { self.refreshCollectionView() }
                }
                self.onFilesFetchCompletion(status)
                handler?()
            }
            showsSkeleton && self.collectionView != nil ? self.pagingSection.afterSkeletonMinimumTime(finish) : finish()
        })
    }

    /// A root that never loaded is not an empty folder, so only the skeleton goes; no empty-folder view comes up.
    private func dropRootSkeleton() {
        guard viewModel?.currentFolder == nil else { return refreshCollectionView() }
        pagingSection.prepareForReload()
        collectionView.reloadData()
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

    private func setLoadingFirstPage(_ isLoading: Bool) {
        guard let viewModel else { return }
        guard isLoading else {
            guard viewModel.endFirstPageLoad() else { return }
            hideTouchBlocker()
            if collectionView != nil { pagingSection.skeletonWillDisappear() }
            return
        }
        viewModel.beginFirstPageLoad()
        showTouchBlocker()
        guard collectionView != nil else { return }
        pagingSection.skeletonWillAppear()
        refreshCollectionView()
    }
    
    private func onFilesFetchCompletion(_ status: RequestStatus) {
        lastFolderLoadStatus = status
        hideSpinner()

        switch status {
        case .success:
            refreshCollectionView()
            
        case .error(let message):
            showErrorAlert(message: message)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension PublicArchiveFileViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
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
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FileGridCell", for: indexPath) as! FileCollectionViewCell
        let file = viewModel.fileForRowAt(indexPath: indexPath)
        cell.updateCell(model: file, fileAction: viewModel.fileAction, isGridCell: isGridView, isSearchCell: false)
        
        cell.rightButtonTapAction = { [weak self] _ in
            self?.handleCellRightButtonAction(for: file, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Two-up, derived from the collection view's own width rather than the screen's, so a narrower
        // container can't push the fit over the edge. Floored, to leave slack instead of an exact fit.
        let layout = collectionViewLayout as? UICollectionViewFlowLayout
        let sideGutters = (layout?.sectionInset.left ?? 6) + (layout?.sectionInset.right ?? 6)
        let interitem = layout?.minimumInteritemSpacing ?? 6
        let available = collectionView.bounds.width
            - collectionView.adjustedContentInset.left
            - collectionView.adjustedContentInset.right
            - sideGutters
            - interitem
        let width = max(1, (available / 2).rounded(.down))

        return CGSize(width: width, height: width + 39)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        pagingSection.willDisplayItem(at: indexPath)
    }

    func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return indexPath.section != pagingSection.sectionIndex
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let viewModel = viewModel, indexPath.section != pagingSection.sectionIndex else { return }

        let file = viewModel.fileForRowAt(indexPath: indexPath)
        
        guard file.fileStatus == .synced && (file.thumbnailURL != nil || file.canBeAccessed) else { return }
        
        if file.type.isFolder {
            // Seed the V2 navigation target (no-op when Stela nav is off, or when the tapped
            // item carries no V2 folderId — navigateMin gates on both and falls through to V1).
            viewModel.v2NavigationTarget = file
            let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, nil)
            let revertHeader = showHeaderWhileLoading(title: file.name, showsBack: true, entering: file.folderLinkId)
            navigateToFolder(withParams: navigateParams, backNavigation: false, then: revertHeader)
        } else {
            presentFileDetails(file: file)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionFooter {
            return pagingSection.footer(at: indexPath)
        }
        if kind == UICollectionView.elementKindSectionHeader {
            let headerView = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: FileCollectionViewHeaderCell.identifier, for: indexPath) as! FileCollectionViewHeaderCell
            
            headerView.rightButtonTitle = nil
            headerView.rightButtonAction = nil
            headerView.leftButtonTitle = nil
            headerView.leftButtonAction = nil
            
            return headerView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 0)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard section == pagingSection.sectionIndex else { return .zero }
        return pagingSection.footerSize(width: collectionView.bounds.width - collectionView.adjustedContentInset.left - collectionView.adjustedContentInset.right)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        // Always try to pass scroll to parent first, let parent decide if it should handle it
        if delegate?.childVC(self, didScrollToOffset: scrollView.contentOffset) ?? false {
            // Parent handled the scroll, reset our offset
            scrollView.contentOffset.y = 0
        }
    }
}

// MARK: - Table View Delegates

extension PublicArchiveFileViewController {
    private func cellRightButtonAction(atPosition position: Int) { }
    
    private func handleCellRightButtonAction(for file: FileModel, atIndexPath indexPath: IndexPath) {
        switch file.fileStatus {
        case .synced:
            showFileActionSheet(file: file, atIndexPath: indexPath)
            
        case .downloading:
            viewModel?.cancelDownload()
            
            self.collectionView.reloadData()
            
        case .uploading, .waiting, .failed:
            cellRightButtonAction(atPosition: indexPath.row)
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
    
    private func handleProgress(withValue value: Float, listSection section: FileListType) {
        let indexPath = IndexPath(row: 0, section: section.rawValue)
        
        guard let uploadingCell = collectionView.cellForItem(at: indexPath) as? FileCollectionViewCell else {
            return
        }

        uploadingCell.updateProgress(withValue: value)
    }
    
    fileprivate func onFileDownloaded(url: URL?, error: Error?) {
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
    }
}

extension PublicArchiveFileViewController {
    func showFileActionSheet(file: FileModel, atIndexPath indexPath: IndexPath) {
        var actions: [PRMNTAction] = []
        
        if file.type.isFolder == false {
            actions.append(
                PRMNTAction(title: "Share to Another App".localized(), iconName: "Share Other", color: .primary, handler: { [self] action in
                    shareWithOtherApps(file: file)
                })
            )
        }
        
        actions.append(
            PRMNTAction(title: "Get Link".localized(), iconName: "Get Link", color: .primary, handler: { [self] action in
                guard let url = viewModel?.publicURL(forFile: file) else { return }
                
                share(url: url)
            })
        )
        
        let actionSheet = PRMNTActionSheetViewController(title: file.name, thumbnail: file.thumbnailURL, actions: actions)
        present(actionSheet, animated: true, completion: nil)
    }
    
    func shareWithOtherApps(file: FileModel) {
        if let localURL = fileHelper.url(forFileNamed: FileHelper.recordScopedName(file.uploadFileName, recordId: file.recordId)) {
            share(url: localURL)
        } else {
            let preparingAlert = UIAlertController(title: "Preparing File..".localized(), message: nil, preferredStyle: .alert)
            preparingAlert.addAction(
                UIAlertAction(title: .cancel, style: .cancel, handler: { _ in
                    self.viewModel?.cancelDownload()
                })
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
    
    func downloadAction(file: FileModel) {
        download(file)
    }
}

// MARK: - SortActionSheetDelegate
extension PublicArchiveFileViewController: SortActionSheetDelegate {
    func didSelectOption(_ option: SortOption) {
        guard let viewModel = viewModel else { return }
        if viewModel.currentFolder != nil { showSpinner() }
        viewModel.saveSortOption(option) { [weak self] _ in
            // The refresh's own guard would leave the spinner up if the folder is gone by now.
            self?.hideSpinner()
            self?.refreshCurrentFolder()
        }
    }
}

// MARK: - FilePreviewNavigationControllerDelegate
extension PublicArchiveFileViewController: FilePreviewNavigationControllerDelegate {
    func filePreviewNavigationControllerWillClose(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        if hasChanges {
            refreshCurrentFolder()
        }
    }
    
    func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) { }
    
    func filePreviewNavigationControllerRequestsDownload(_ filePreviewNavigationVC: UIViewController, file: FileModel) {
        // Download not supported in public profile view
    }
}
