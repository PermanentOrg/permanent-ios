//
//  MainViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import BSImagePicker
import MobileCoreServices
import UIKit

class MainViewController: BaseViewController<FilesViewModel> {
    @IBOutlet var directoryLabel: UILabel!
    @IBOutlet var backButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var fabView: FABView!
    
    private let refreshControl = UIRefreshControl()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        setupTableView()
        
        viewModel = FilesViewModel()
        fabView.delegate = self
        
        getRootFolder()
    }
    
    // MARK: - UI Related
    
    fileprivate func initUI() {
        view.backgroundColor = .white
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationItem.setHidesBackButton(true, animated: false)
        navigationItem.title = Translations.myFiles
        styleNavBar()
        
        directoryLabel.font = Text.style3.font
        directoryLabel.textColor = .primary
        backButton.tintColor = .primary
        backButton.isHidden = true
    }
    
    fileprivate func setupTableView() {
        tableView.register(UINib(nibName: String(describing: FileTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: FileTableViewCell.self))
        tableView.tableFooterView = UIView()
        tableView.refreshControl = refreshControl
        
        refreshControl.tintColor = .primary
        refreshControl.addTarget(self, action: #selector(pullToRefreshAction), for: .valueChanged)
    }
    
    func refreshTableView() {
        handleTableBackgroundView()
        tableView.reloadData()
    }
    
    func handleTableBackgroundView() {
        guard viewModel?.shouldDisplayBackgroundView == false else {
            tableView.backgroundView = EmptyFolderView()
            return
        }

        tableView.backgroundView = nil
    }
    
    @IBAction
    func backButtonAction(_ sender: UIButton) {
        guard
            let viewModel = viewModel,
            let _ = viewModel.navigationStack.popLast(),
            let destinationFolder = viewModel.navigationStack.last
        else {
            return
        }
        
        let navigateParams: NavigateMinParams = (destinationFolder.archiveNo, destinationFolder.folderLinkId, viewModel.csrf)
        navigateToFolder(withParams: navigateParams, backNavigation: true, then: {
            self.directoryLabel.text = destinationFolder.name
            
            // If we got to the root, hide the back button.
            if viewModel.navigationStack.count == 1 {
                self.backButton.isHidden = true
            }
        })
    }
    
    private func refreshCurrentFolder(shouldDisplaySpinner: Bool = true,
                                      then handler: VoidAction? = nil)
    {
        guard
            let viewModel = viewModel,
            let currentFolder = viewModel.navigationStack.last else { return }
        
        let params: NavigateMinParams = (
            currentFolder.archiveNo,
            currentFolder.folderLinkId,
            viewModel.csrf
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
    
    // MARK: - Network Related
    
    private func getRootFolder() {
        showSpinner()
        
        viewModel?.getRoot(then: { status in
            self.onFilesFetchCompletion(status)
        })
    }
    
    private func navigateToFolder(withParams params: NavigateMinParams,
                                  backNavigation: Bool,
                                  shouldDisplaySpinner: Bool = true,
                                  then handler: VoidAction? = nil)
    {
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
            DispatchQueue.main.async {
                self.refreshTableView()
            }
            
        case .error(let message):
            DispatchQueue.main.async {
                self.showAlert(title: Translations.error, message: message)
            }
        }
    }
    
    private func upload(fileURLS: [URL]) {
        viewModel?.uploadFiles(
            fileURLS,
            onUploadStart: {
                DispatchQueue.main.async {
                    self.refreshTableView()
                }
            },
            onFileUploaded: { uploadedFile, errorMessage in
                // TODO:
                // Remove file from uploading list and move it to synced one
                
                guard let file = uploadedFile else {
                    DispatchQueue.main.async {
                        self.showAlert(title: Translations.error, message: errorMessage)
                    }
                    return
                }
                
                DispatchQueue.main.async {
                    self.refreshTableView()
                }
                
                print("FILE UPLOADED: ", file.filename ?? "____")
                
            },
            
            then: { status in
                switch status {
                case .success:
                    self.refreshCurrentFolder()
                
                case .error(let message):
                    DispatchQueue.main.async {
                        self.hideSpinner()
                        self.showAlert(title: Translations.error, message: message)
                    }
                }
            }
        )
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
        // TODO: Create tableView Helper class
        guard
            let viewModel = self.viewModel,
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FileTableViewCell.self)) as? FileTableViewCell
        else {
            fatalError()
        }
        
        let file = viewModel.cellForRowAt(indexPath: indexPath)
        cell.updateCell(model: file)
        return cell
    }
    
    // TODO:
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let viewModel = viewModel else {
            fatalError()
        }

        guard !viewModel.uploadInProgress else {
            return
        }
        
        let file = viewModel.viewModels[indexPath.row]
        guard file.type.isFolder else { return }

        let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, viewModel.csrf)
        navigateToFolder(withParams: navigateParams, backNavigation: false, then: {
            self.backButton.isHidden = false
            self.directoryLabel.text = file.name
        })
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard viewModel?.numberOfRowsInSection(section) != 0 else {
            return nil
        }
        
        headerView.backgroundColor = .backgroundPrimary
        
        let sectionTitleLabel = UILabel()
        sectionTitleLabel.text = "Section \(section)"
        sectionTitleLabel.font = Text.style11.font
        sectionTitleLabel.textColor = .middleGray

        headerView.addSubview(sectionTitleLabel)
        sectionTitleLabel.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            sectionTitleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor),
            sectionTitleLabel.leadingAnchor.constraint(equalTo: headerView.leadingAnchor, constant: 20)
        ])
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard viewModel?.numberOfRowsInSection(section) != 0 else {
            return 0
        }

        return 40
    }
}

extension MainViewController: FABViewDelegate {
    func didTap() {
        guard let actionSheet = navigationController?.create(
            viewController: .fabActionSheet,
            from: .main
        ) as? FABActionSheet else {
            showAlert(title: Translations.error, message: Translations.errorMessage)
            return
        }
        
        actionSheet.delegate = self
        navigationController?.display(viewController: actionSheet)
    }
}

extension MainViewController: FABActionSheetDelegate {
    func didTapUpload() {
        showActionSheet()
    }
    
    func didTapNewFolder() {
        guard
            let viewModel = viewModel,
            let currentFolder = viewModel.navigationStack.last else { return }
        
        let params: NewFolderParams = ("Testing Folder v6", currentFolder.folderLinkId, viewModel.csrf)
        
        showSpinner()
        viewModel.createNewFolder(params: params, then: { status in
            self.hideSpinner()
            
            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
            
            case .error(let message):
                DispatchQueue.main.async {
                    self.showAlert(title: Translations.error, message: message)
                }
            }
        })
    }
    
    func showActionSheet() {
        let photoLibraryAction = UIAlertAction(title: Translations.photoLibrary, style: .default) { _ in self.openPhotoLibrary() }
        let browseAction = UIAlertAction(title: Translations.browse, style: .default) { _ in self.openFileBrowser() }
        let cancelAction = UIAlertAction(title: Translations.cancel, style: .cancel, handler: nil)
            
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addActions([photoLibraryAction, browseAction, cancelAction])
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func openPhotoLibrary() {
        let imagePicker = ImagePickerController()
        
        presentImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil, finish: { assets in
            self.viewModel?.didChooseFromPhotoLibrary(assets, completion: { urls in
                self.upload(fileURLS: urls)
            })
        })
    }
    
    func openFileBrowser() {
        let docPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeImage as String,
                                                                       kUTTypeCompositeContent as String],
                                                       in: .import)
        docPicker.delegate = self
        docPicker.allowsMultipleSelection = true
        present(docPicker, animated: true, completion: nil)
    }
}

// MARK: - Document Picker Delegate

extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        upload(fileURLS: urls)
    }
}
