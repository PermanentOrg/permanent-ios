//  
//  SharesViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14.12.2020.
//

import UIKit

class SharesViewController: BaseViewController<ShareLinkViewModel> {
    @IBOutlet var segmentedControl: UISegmentedControl!
    @IBOutlet var tableView: UITableView!
    
    private var fileActionSheet: SharedFileActionSheet?
    
    private let overlayView = UIView()
    
    let documentInteractionController = UIDocumentInteractionController()
    
    var selectedIndex: Int = 0
    
    var selectedFileId: Int?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        viewModel = ShareLinkViewModel()
        
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
        
        view.addSubview(overlayView)
        overlayView.backgroundColor = .overlay
        overlayView.alpha = 0
        
    }
    
    fileprivate func setupTableView() {
        tableView.registerNib(cellClass: SharedFileTableViewCell.self)
        tableView.tableFooterView = UIView()
        tableView.separatorInset = .zero
    }
    
    fileprivate func configureTableViewBgView() {
        if let items = viewModel?.items, items.isEmpty {
            tableView.backgroundView = EmptyFolderView(title: .shareActionMessage, image: .shares)
        } else {
            tableView.backgroundView = nil
        }
    }
    
    fileprivate func refreshTableView(_ completion: (() -> ())? = nil) {
        self.tableView.reloadData(completion)
        self.configureTableViewBgView()
    }
    
    @IBAction func segmentedControlValueChanged(_ sender: UISegmentedControl) {
        guard let listType = ShareListType(rawValue: sender.selectedSegmentIndex) else {
            return
        }
        
        viewModel?.shareListType = listType
        refreshTableView()
    }
    
    func showFileActionSheet(file: SharedFileViewModel, atIndexPath indexPath: IndexPath) {
        // Safety measure, in case the user taps to show sheet, but the previously shown one
        // has not finished dimissing and being deallocated.
        guard fileActionSheet == nil else { return }
        
        fileActionSheet = SharedFileActionSheet(
            frame: CGRect(origin: CGPoint(x: 0, y: view.bounds.height), size: view.bounds.size),
            title: file.name,
            file: file,
            indexPath: indexPath,
            onDismiss: {
                self.tableView.deselectRow(at: indexPath, animated: true)
                self.view.dismissPopup(
                    self.fileActionSheet,
                    overlayView: self.overlayView,
                    completion: { _ in
                        self.fileActionSheet?.removeFromSuperview()
                        self.fileActionSheet = nil
                    })
            }
        )
        
        fileActionSheet?.delegate = self
        view.addSubview(fileActionSheet!)
        self.view.presentPopup(fileActionSheet, overlayView: overlayView)
    }

    fileprivate func getShares() {
        showSpinner()
        viewModel?.getShares(then: { status in
            self.hideSpinner()
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.refreshTableView {
                        self.scrollToFileIfNeeded()
                    }
                }
            case .error(let message):
                DispatchQueue.main.async {
                    self.showErrorAlert(message: message)
                }
            }
        })
    }
    
    private func download(_ file: SharedFileViewModel) {
        viewModel?.download(
            file,
            
            onDownloadStart: {
                
                self.viewModel?.changeStatus(forFile: file, status: .downloading)
                
                DispatchQueue.main.async {
                    self.refreshTableView()
                }
            },
            
            onFileDownloaded: { url, errorMessage in
                guard let shareURL = url else {
                    DispatchQueue.main.async {
                        self.showErrorAlert(message: errorMessage)
                    }
                
                    return
                }
                
                self.viewModel?.changeStatus(forFile: file, status: .synced)
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
                DispatchQueue.main.async {
                    self.share(url: shareURL)
                }
            },
            
            progressHandler: { progress in
                DispatchQueue.main.async {
//                    self.handleProgress(withValue: progress, listSection: FileListType.downloading)
                    
                    self.handleProgress(forFile: file, withValue: progress)
                    
                }
            },
            
            then: { status in
                
                switch status {
                case .success:
                    break
                    
                case .error(let message):
                    DispatchQueue.main.async {
                        self.hideSpinner()
                        self.showAlert(title: .error, message: message)
                    }
                }
            }
        )
    }
    
    private func handleCellRightButtonAction(for file: SharedFileViewModel, atIndexPath indexPath: IndexPath) {
        switch file.status {
        case .synced:
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none) // test
            showFileActionSheet(file: file, atIndexPath: indexPath)
            
        case .downloading:
            break
            
        case .uploading, .waiting:
            //cellRightButtonAction(atPosition: indexPath.row)
            break
        }
    }
    
    private func onDownloadStart(forFile file: SharedFileViewModel) {
        
    }
    
    private func handleProgress(forFile file: SharedFileViewModel, withValue value: Float) {
        
        guard
            
            
            
            let index = viewModel?.items.firstIndex(where: { $0.folderLinkId == file.folderLinkId }),
            let downloadingCell = tableView.cellForRow(at: IndexPath(row: index, section: 0)) as? SharedFileTableViewCell else {
            return
        }
        
        
        downloadingCell.updateProgress(withValue: value)
        
    }
    
//    private func handleProgress(withValue value: Float, listSection section: FileListType) {
//
//        viewModel?.items.firstIndex(where: )
//
//
//
//
//
//
//        let indexPath = IndexPath(row: 0, section: section.rawValue)
//
//        guard
//            let uploadingCell = tableView.cellForRow(at: indexPath) as? SharedFileTableViewCell
//        else {
//            return
//        }
//
//        uploadingCell.updateProgress(withValue: value)
//    }
    
}

extension SharesViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.items.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let viewModel = self.viewModel else {
            fatalError()
        }
        
        let cell = tableView.dequeue(cellClass: SharedFileTableViewCell.self, forIndexPath: indexPath)
        let item = viewModel.items[indexPath.row]
        cell.updateCell(model: item)
        
        cell.rightButtonTapAction = { _ in
            self.handleCellRightButtonAction(for: item, atIndexPath: indexPath)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func scrollToFileIfNeeded() {
        guard
            let folderLinkId = self.selectedFileId,
            let index = self.viewModel?.items.firstIndex(where: { $0.folderLinkId == folderLinkId} ) else {
            return
        }
        
        let indexPath = IndexPath(row: index, section: 0)
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
    }
}

extension SharesViewController: SharedFileActionSheetDelegate {
    func downloadAction(file: SharedFileViewModel) {
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
