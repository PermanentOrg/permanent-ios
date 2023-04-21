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
    
    let fileHelper = FileHelper()
    let documentInteractionController = UIDocumentInteractionController()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = SearchFilesViewModel()
        
        initUI()
        setupCollectionView()
        
        searchBar.delegate = self
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name("SearchFilesViewModel.didSearch"), object: viewModel, queue: nil) { notification in
            self.searchBar.text = ""
            self.refreshCollectionView()
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
        
        directoryLabel.font = Text.style3.font
        directoryLabel.textColor = .primary
        directoryLabel.text = ""
        backButton.tintColor = .primary
        backButton.isHidden = true
        
        switchViewButton.isHidden = true
        folderNavigationStackView.isHidden = true
        collectionViewTopConstraint.constant = 0
        
        searchBar.setDefaultStyle(placeholder: .searchFiles)
        
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
              let _ = viewModel.removeCurrentFolderFromHierarchy() else { return }
        
        if let destinationFolder = viewModel.currentFolder {
            // Still has some folder to go back to
            let navigateParams: NavigateMinParams = (destinationFolder.archiveNo, destinationFolder.folderLinkId, nil)
            navigateToFolder(withParams: navigateParams, backNavigation: true, then: {
                self.directoryLabel.text = destinationFolder.name
            })
        } else {
            // Navigate to the original search
            viewModel.reallySearchFiles() { status in
                self.backButton.isHidden = true
                self.directoryLabel.text = ""
                
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
                                  then handler: VoidAction? = nil) {
        shouldDisplaySpinner ? showSpinner() : nil
        
        viewModel?.navigateMin(params: params, backNavigation: backNavigation, then: { status in
            self.onFilesFetchCompletion(status)
            handler?()
        })
    }
    
    private func onFilesFetchCompletion(_ status: RequestStatus) {
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
        return viewModel?.numberOfSections ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel?.numberOfRowsInSection(section) ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let viewModel = self.viewModel else {
            return UICollectionViewCell()
        }
        
        let cell: UICollectionViewCell
        
        let reuseIdentifier: String
        if indexPath.section == 1 {
            reuseIdentifier = "FileCell"
            
            let newCell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! FileCollectionViewCell
            let file = viewModel.fileForRowAt(indexPath: indexPath)
            newCell.updateCell(model: file, fileAction: viewModel.fileAction, isGridCell: false, isSearchCell: true)
            
            newCell.rightButtonTapAction = { _ in
                self.handleCellRightButtonAction(for: file, atIndexPath: indexPath)
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
        let listItemSize = CGSize(width: UIScreen.main.bounds.width, height: 70)

        return listItemSize
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
    
}

// MARK: - Table View Delegates
extension SearchViewController {
    private func cellRightButtonAction(atPosition position: Int) {
        
    }
    
    private func handleCellRightButtonAction(for file: FileViewModel, atIndexPath indexPath: IndexPath) {

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
        backButton.isHidden = true
        directoryLabel.text = ""
        
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
}
