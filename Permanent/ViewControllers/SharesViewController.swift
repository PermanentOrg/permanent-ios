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
    @IBOutlet var tableView: UITableView!
    private let refreshControl = UIRefreshControl()
    
    private var fileActionSheet: SharedFileActionSheet?
    
    private let overlayView = UIView()
    
    let documentInteractionController = UIDocumentInteractionController()
    
    var selectedIndex: Int = 0
    
    var selectedFileId: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = SharedFilesViewModel()
        
        configureUI()
        setupTableView()
     
        getShares()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        overlayView.frame = view.bounds
    }
    
    fileprivate func configureUI() {
        navigationItem.title = .shares
        view.backgroundColor = .backgroundPrimary
        
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white,
                                                 .font: Text.style11.font], for: .selected)
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
    }
    
    fileprivate func setupTableView() {
        tableView.registerNib(cellClass: SharedFileTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero
        
        tableView.refreshControl = refreshControl
        
        refreshControl.tintColor = .primary
        refreshControl.addTarget(self, action: #selector(pullToRefreshAction), for: .valueChanged)
    }
    
    fileprivate func configureTableViewBgView() {
        if let items = viewModel?.viewModels, items.isEmpty {
            tableView.backgroundView = EmptyFolderView(title: .shareActionMessage, image: .shares)
        } else {
            tableView.backgroundView = nil
        }
    }
    
    fileprivate func refreshTableView(_ completion: (() -> ())? = nil) {
        tableView.reloadData(completion)
        configureTableViewBgView()
    }
    
    private func refreshCurrentFolder(shouldDisplaySpinner: Bool = true, then handler: VoidAction? = nil) {
        guard let viewModel = viewModel else { return }
        
        if let currentFolder = viewModel.currentFolder {
            let params: NavigateMinParams = (currentFolder.archiveNo, currentFolder.folderLinkId, viewModel.csrf)
            
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
        
        self.directoryLabel.text = listType == .sharedByMe ? .sharedByMe : .sharedWithMe
        self.backButton.isHidden = true
        
        viewModel?.shareListType = listType
        refreshTableView()
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
        guard
            let viewModel = viewModel,
            let _ = viewModel.removeCurrentFolderFromHierarchy()
        else {
            return
        }
        
        if let destinationFolder = viewModel.currentFolder {
            let navigateParams: NavigateMinParams = (destinationFolder.archiveNo, destinationFolder.folderLinkId, viewModel.csrf)
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

    fileprivate func getShares(shouldShowSpinner: Bool = true, completion: (() -> Void)? = nil) {
        if shouldShowSpinner {
            showSpinner()
        }
        
        viewModel?.getShares(then: { status in
            self.hideSpinner()
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.refreshTableView {
                        self.scrollToFileIfNeeded()
                        
                        self.directoryLabel.text = self.viewModel?.shareListType == .sharedByMe ? .sharedByMe : .sharedWithMe
                        self.backButton.isHidden = true
                    }
                }
            case .error(let message):
                DispatchQueue.main.async {
                    self.showErrorAlert(message: message)
                }
            }
            
            if let completion = completion {
                completion()
            }
        })
    }
    
    private func download(_ file: FileViewModel) {
        viewModel?.download(file, onDownloadStart: {
            DispatchQueue.main.async {
                if let index = self.viewModel?.viewModels.firstIndex(where: { $0.recordId == file.recordId }) {
                    self.viewModel?.viewModels[index].fileStatus = .downloading
                }
                
                self.refreshTableView()
            }
        }, onFileDownloaded: { url, error in
            DispatchQueue.main.async {
                if let index = self.viewModel?.viewModels.firstIndex(where: { $0.recordId == file.recordId }) {
                    self.viewModel?.viewModels[index].fileStatus = .synced
                }
                
                self.onFileDownloaded(url: url, error: error)
            }
        }, progressHandler: { progress in
            DispatchQueue.main.async {
                self.handleProgress(forFile: file, withValue: progress)
            }
        })
    }
    
    fileprivate func onFileDownloaded(url: URL?, error: Error?) {
        self.refreshTableView()
        
        guard let shareURL = url else {
            let apiError = (error as? APIError) ?? .unknown
            
            if apiError == .cancelled {
                view.showNotificationBanner(height: Constants.Design.bannerHeight, title: .downloadCancelled)
            } else {
                showErrorAlert(message: apiError.message)
            }

            return
        }
        
        share(url: shareURL)
    }
    
    private func handleCellRightButtonAction(for file: FileViewModel, atIndexPath indexPath: IndexPath) {
        switch file.fileStatus {
        case .synced:
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
            showFileActionSheet(file: file, atIndexPath: indexPath)
            
        case .downloading:
            viewModel?.cancelDownload()
            
            if let index = self.viewModel?.viewModels.firstIndex(where: { $0.recordId == file.recordId }) {
                self.viewModel?.viewModels[index].fileStatus = .synced
            }
            
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
            
        case .uploading, .waiting:
            break
        }
    }
    
    private func handleProgress(forFile file: FileViewModel, withValue value: Float) {
        guard let index = viewModel?.viewModels.firstIndex(where: { $0.recordId == file.recordId }),
              let downloadingCell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SharedFileTableViewCell
        else {
            return
        }
        
        downloadingCell.updateProgress(withValue: value)
    }

    private func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, shouldDisplaySpinner: Bool = true, then handler: VoidAction? = nil) {
        shouldDisplaySpinner ? showSpinner() : nil
        
        // Clear the data before navigation so we avoid concurrent errors.
        viewModel?.viewModels.removeAll()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
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
                self.refreshTableView()
            }
            
        case .error(let message):
            showErrorAlert(message: message)
        }
    }
}

extension SharesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.viewModels.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = self.viewModel else {
            fatalError()
        }
        
        let cell = tableView.dequeue(cellClass: SharedFileTableViewCell.self, forIndexPath: indexPath)
        let item = viewModel.viewModels[indexPath.row]
        cell.updateCell(model: item)
        
        cell.rightButtonTapAction = { _ in
            self.handleCellRightButtonAction(for: item, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let viewModel = self.viewModel else { return }
        
        let file = viewModel.fileForRowAt(indexPath: indexPath)
        
        guard file.type.isFolder, file.fileStatus == .synced else { return }

        let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, viewModel.csrf)
        navigateToFolder(withParams: navigateParams, backNavigation: false, then: {
            self.backButton.isHidden = false
            self.directoryLabel.text = file.name
        })
    }
    
    func scrollToFileIfNeeded() {
        guard
            let folderLinkId = selectedFileId,
            let index = viewModel?.viewModels.firstIndex(where: { $0.folderLinkId == folderLinkId })
        else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }
}

extension SharesViewController: SharedFileActionSheetDelegate {
    func downloadAction(file: FileViewModel) {
        download(file)
    }
}

extension SharesViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
    
    func share(url: URL) {
        // For now, dismiss the menu in case another one opens so we avoid crash.
        documentInteractionController.dismissMenu(animated: true)
        
        documentInteractionController.url = url
        documentInteractionController.uti = url.typeIdentifier ?? "public.data, public.content"
        documentInteractionController.name = url.localizedName ?? url.lastPathComponent
        documentInteractionController.presentOptionsMenu(from: .zero, in: view, animated: true)
    }
}
