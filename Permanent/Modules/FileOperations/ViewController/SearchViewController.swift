//
//  SearchViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 15.11.2021.
//

import UIKit

class SearchViewController: BaseViewController<SearchFilesViewModel> {
    @IBOutlet weak var directoryLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var folderNavigationStackView: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var switchViewButton: UIButton!
    @IBOutlet weak var collectionViewTopConstraint: NSLayoutConstraint!
    
    private let overlayView = UIView()
    private let refreshControl = UIRefreshControl()

    /// Token for the `didSearch` observer, held so `deinit` can remove it: NotificationCenter retains
    /// the block, which would keep this controller alive for the app's lifetime.
    private var didSearchObserver: NSObjectProtocol?
    private lazy var folderHeader: FolderHeaderTransition? = {
        guard backButton != nil, directoryLabel != nil else { return nil }
        return FolderHeaderTransition(backButton: backButton, titleLabel: directoryLabel)
    }()
    /// How the last folder load ended, for flows that changed the header before it landed; nil while one runs.
    private var lastFolderLoadStatus: RequestStatus?
    private lazy var pagingSection = FileListPagingSection(collectionView: collectionView, viewModel: { [weak self] in self?.viewModel }, onChange: { [weak self] in self?.refreshCollectionView() })
    
    let fileHelper = FileHelper()
    let documentInteractionController = UIDocumentInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = SearchFilesViewModel()
        
        initUI()
        setupCollectionView()
        
        searchBar.delegate = self
        
        didSearchObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name("SearchFilesViewModel.didSearch"), object: viewModel, queue: nil) { [weak self] _ in
            self?.searchBar.text = ""
            self?.refreshCollectionView()
        }
    }

    deinit {
        if let didSearchObserver {
            NotificationCenter.default.removeObserver(didSearchObserver)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        searchBar.becomeFirstResponder()
    }

    // MARK: - UI Related
    
    fileprivate func initUI() {
        view.backgroundColor = .white
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.title = "Search".localized()
        navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        navigationItem.backBarButtonItem?.tintColor = .white
        
        styleNavBar()
        
        directoryLabel.font = TextFontStyle.style3.font
        directoryLabel.textColor = .primary
        directoryLabel.text = ""
        backButton.tintColor = .primary
        backButton.isHidden = true
        _ = folderHeader
        
        switchViewButton.isHidden = true
        folderNavigationStackView.isHidden = true
        collectionViewTopConstraint.constant = 0
        
        searchBar.setDefaultStyle(placeholder: .searchFiles)
        searchBar.accessibilityIdentifier = "filesSearchBar"
        searchBar.searchTextField.accessibilityIdentifier = "filesSearchBar"
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
        let leftButtonImage: UIImage!
        leftButtonImage = UIImage(systemName: "xmark", withConfiguration: UIImage.SymbolConfiguration(weight: .regular))
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: leftButtonImage, style: .plain, target: self, action: #selector(closeButtonAction(_:)))
    }
    
    fileprivate func setupCollectionView() {
        collectionView.register(UINib(nibName: "FileCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "FileCell")
        collectionView.register(UINib(nibName: "FileCollectionViewGridCell", bundle: nil), forCellWithReuseIdentifier: "FileGridCell")
        collectionView.register(FileCollectionViewHeaderCell.nib(), forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: FileCollectionViewHeaderCell.identifier)
        _ = pagingSection
        
        collectionView.refreshControl = refreshControl
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 6, bottom: 60, right: 6)
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 6
        flowLayout.minimumLineSpacing = 0
        flowLayout.estimatedItemSize = .zero
        collectionView.collectionViewLayout = flowLayout
        
        refreshControl.tintColor = .primary
        refreshControl.addTarget(self, action: #selector(pullToRefreshAction), for: .valueChanged)
        
        handleTableBackgroundView()
    }
    
    func refreshCollectionView() {
        handleTableBackgroundView()
        pagingSection.prepareForReload()
        collectionView.reloadData()
    }
    
    func handleTableBackgroundView() {
        guard viewModel?.shouldDisplayBackgroundView == false else {
            let backgroundView = EmptyFolderView(title: "Enter search terms to match tags and titles.\nSearch results will appear here.", image: .emptySearch)
            backgroundView.frame = collectionView.bounds
            collectionView.backgroundView = backgroundView
            return
        }

        collectionView.backgroundView = nil
    }
    
    @IBAction
    func backButtonAction(_ sender: UIButton) {
        guard let viewModel = viewModel,
              let leftFolder = viewModel.removeCurrentFolderFromHierarchy() else { return }
        
        if let destinationFolder = viewModel.currentFolder {
            // Still has some folder to go back to
            let revertHeader = showHeaderWhileLoading(title: destinationFolder.name, showsBack: true)
            let navigateParams: NavigateMinParams = (destinationFolder.archiveNo, destinationFolder.folderLinkId, nil)
            navigateToFolder(withParams: navigateParams, backNavigation: true, then: {
                // The folder left is still on screen, so it goes back on the history and keeps its header.
                guard self.folderLoadFailed(), viewModel.navigationStack.last?.folderLinkId == destinationFolder.folderLinkId else { return }
                viewModel.navigationStack.append(leftFolder)
                revertHeader()
            })
        } else {
            // Navigate to the original search
            viewModel.reallySearchFiles() { status in
                self.folderHeader?.show(title: "", showsBack: false)
                
                self.refreshCollectionView()
            }
        }
    }
    
    private func refreshCurrentFolder(shouldDisplaySpinner: Bool = true, then handler: VoidAction? = nil) {
        guard
            let viewModel = viewModel,
            let currentFolder = viewModel.currentFolder else { return }
        
        let params: NavigateMinParams = (
            currentFolder.archiveNo,
            currentFolder.folderLinkId,
            nil
        )
        
        // Back navigation set to `true` so it's not considered a in-depth navigation.
        navigateToFolder(withParams: params,
                         backNavigation: true,
                         shouldDisplaySpinner: shouldDisplaySpinner,
                         isRefresh: true,
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
    
    @objc
    private func headerButtonAction(_ sender: UIButton) {
    }
    
    @objc func closeButtonAction(_ sender: Any) {
        dismiss(animated: false)
    }
    
    // MARK: - Network Related
    private func navigateToFolder(withParams params: NavigateMinParams,
                                  backNavigation: Bool,
                                  shouldDisplaySpinner: Bool = true,
                                  isRefresh: Bool = false,
                                  then handler: VoidAction? = nil) {
        // Entering a folder shows skeleton rows; refreshing the one on screen keeps its rows under the spinner.
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
        self.hideSpinner()

        switch status {
        case .success:
            self.refreshCollectionView()
            
        case .error(let message):
            showErrorAlert(message: message)
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout, UICollectionViewDataSource
extension SearchViewController: UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return viewModel.map { $0.numberOfSections + 1 } ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == pagingSection.sectionIndex { return pagingSection.numberOfItems(isGrid: false) }
        return viewModel?.numberOfRowsInSection(section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = self.viewModel else {
            return UICollectionViewCell()
        }
        if indexPath.section == pagingSection.sectionIndex {
            return pagingSection.cell(at: indexPath, isGrid: false)
        }
        
        let cell: UICollectionViewCell
        
        let reuseIdentifier: String
        if indexPath.section == 1 {
            reuseIdentifier = "FileCell"
            
            let newCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FileCollectionViewCell
            let file = viewModel.fileForRowAt(indexPath: indexPath)
            newCell.updateCell(model: file, fileAction: viewModel.fileAction, isGridCell: false, isSearchCell: true)
            
            newCell.rightButtonTapAction = { [weak self] _ in
                self?.handleCellRightButtonAction(for: file, atIndexPath: indexPath)
            }
            
            cell = newCell
        } else {
            reuseIdentifier = "SearchTagsCell"
            
            let newCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FileSearchTagsCollectionViewCell
            
            newCell.configure(withViewModel: viewModel)
            
            cell = newCell
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let listItemSize = CGSize(width: UIScreen.main.bounds.width, height: 74)

        return listItemSize
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
            // Seed the V2 navigation target (no-op when Stela nav is off): V2 needs the
            // String folderId, which lives on the tapped FileModel.
            viewModel.v2NavigationTarget = file
            let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, nil)
            let revertHeader = showHeaderWhileLoading(title: file.name, showsBack: true, entering: file.folderLinkId)
            navigateToFolder(withParams: navigateParams, backNavigation: false, then: revertHeader)
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
        if kind == UICollectionView.elementKindSectionFooter {
            return pagingSection.footer(at: indexPath)
        }
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
            } else {
                headerView.rightButtonTitle = nil
                headerView.rightButtonAction = nil
            }
            
            return headerView
        }
        
        return UICollectionReusableView()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let height: CGFloat = viewModel?.heightForSection(section) ?? 0
        return CGSize(width: UIScreen.main.bounds.width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        guard section == pagingSection.sectionIndex else { return .zero }
        return pagingSection.footerSize(width: collectionView.bounds.width - collectionView.adjustedContentInset.left - collectionView.adjustedContentInset.right)
    }
    
}

// MARK: - Table View Delegates
extension SearchViewController {
    private func cellRightButtonAction(atPosition position: Int) {
        
    }
    
    private func handleCellRightButtonAction(for file: FileModel, atIndexPath indexPath: IndexPath) {

    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        view.endEditing(true)
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        folderHeader?.show(title: "", showsBack: false)
        
        viewModel?.searchFiles(byQuery: searchText, handler: { status in
            self.refreshCollectionView()
        })
    }
}

// MARK: - FileActionSheetDelegate
extension SearchViewController {

}

// MARK: - FilePreviewNavigationControllerDelegate
extension SearchViewController: FilePreviewNavigationControllerDelegate {
    func filePreviewNavigationControllerWillClose(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        if hasChanges {
            refreshCurrentFolder()
        }
    }
    
    func filePreviewNavigationControllerDidChange(_ filePreviewNavigationVC: UIViewController, hasChanges: Bool) {
        
    }
    
    func filePreviewNavigationControllerRequestsDownload(_ filePreviewNavigationVC: UIViewController, file: FileModel) {
        // Download not supported in search view
    }
}
