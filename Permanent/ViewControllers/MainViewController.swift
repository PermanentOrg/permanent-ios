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
    private var actionDialog: ActionDialogView?
    
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
        navigationItem.title = .myFiles
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
    
    private func handleUploadProgress(withValue value: Float) {
        let indexPath = IndexPath(row: 0, section: 0)
        
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
        
        refreshTableView()
    }
    
    // MARK: - Network Related
    
    private func getRootFolder() {
        showSpinner()
        
        viewModel?.getRoot(then: { status in
            self.onFilesFetchCompletion(status)
            self.retryUnfinishedUploadsIfNeeded()
        })
    }
    
    private func navigateToFolder(withParams params: NavigateMinParams,
                                  backNavigation: Bool,
                                  shouldDisplaySpinner: Bool = true,
                                  then handler: VoidAction? = nil)
    {
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
            DispatchQueue.main.async {
                self.showAlert(title: .error, message: message)
            }
        }
    }
    
    private func retryUnfinishedUploadsIfNeeded() {
        guard
            let uploadQueue: [FileInfo] = try? PreferencesManager.shared.getCustomObject(forKey: Constants.Keys.StorageKeys.uploadFilesKey),
            !uploadQueue.isEmpty
        else {
            return
        }
        
        upload(files: uploadQueue)
    }
    
    private func upload(files: [FileInfo]) {
        viewModel?.uploadFiles(
            files,
            onUploadStart: {
                DispatchQueue.main.async {
                    self.refreshTableView()
                }
            },
            onFileUploaded: { uploadedFile, errorMessage in
                // TODO: what should we do on file upload fail?
                guard uploadedFile != nil else {
                    DispatchQueue.main.async {
                        self.showAlert(title: .error, message: errorMessage)
                    }
                    return
                }

                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            },
            progressHandler: { progress in
                DispatchQueue.main.async {
                    self.handleUploadProgress(withValue: progress)
                }
                
            },
            
            then: { status in
                switch status {
                case .success:
                    if self.viewModel?.shouldRefreshList == true {
                        self.refreshCurrentFolder(shouldDisplaySpinner: true)
                    }
                    
                    self.viewModel?.clearUploadQueue()
                    
                case .error(let message):
                    DispatchQueue.main.async {
                        self.hideSpinner()
                        self.showAlert(title: .error, message: message)
                    }
                }
            }
        )
    }
    
    private func createNewFolder(named name: String) {
        guard
            let viewModel = viewModel,
            let currentFolder = viewModel.navigationStack.last else { return }

        let params: NewFolderParams = (name, currentFolder.folderLinkId, viewModel.csrf)

        showSpinner()
        viewModel.createNewFolder(params: params, then: { status in
            self.hideSpinner()

            switch status {
            case .success:
                DispatchQueue.main.async {
                    self.refreshTableView()
                }

            case .error(let message):
                DispatchQueue.main.async {
                    self.showAlert(title: .error, message: message)
                }
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
                DispatchQueue.main.async {
                    self.showAlert(title: .error, message: message)
                }
            }
            
        })
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
        
        let file = viewModel.fileForRowAt(indexPath: indexPath)
        cell.updateCell(model: file)
        
        cell.rightButtonTapAction = { _ in
            guard file.fileStatus != .synced else {
                // TODO: Handle `more` button tap and display action sheet.
                return
            }
            
            self.cellRightButtonAction(atPosition: indexPath.row)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let viewModel = viewModel else {
            fatalError()
        }

        let file = viewModel.fileForRowAt(indexPath: indexPath)
        
        guard
            file.type.isFolder,
            file.fileStatus == .synced
        else {
            return
        }

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
        
        let headerView = UIView()
        headerView.backgroundColor = .backgroundPrimary
        
        let sectionTitleLabel = UILabel()
        sectionTitleLabel.text = viewModel?.title(forSection: section)
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
    
    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction.make(
            withImage: .deleteAction,
            backgroundColor: .destructive,
            handler: { _, _, completion in
                self.didTapDelete(at: indexPath)
                completion(true)
            }
        )

        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
    
    private func cellRightButtonAction(atPosition position: Int) {
        actionDialog?.dismiss()
        removeFromQueue(atPosition: position)
    }
    
    private func didTapDelete(at indexPath: IndexPath) {
        guard let file = viewModel?.fileForRowAt(indexPath: indexPath) else {
            return
        }
        
        let title = String(format: "\(String.delete) \"%@\"?", file.name)
        
        showActionDialog(styled: .simple,
                         withTitle: title,
                         positiveButtonTitle: .delete,
                         positiveAction: {
                            self.actionDialog?.dismiss()
                            self.deleteFile(file, atIndexPath: indexPath)
                         })
    }
}

extension MainViewController: FABViewDelegate {
    func didTap() {
        guard let actionSheet = navigationController?.create(
            viewController: .fabActionSheet,
            from: .main
        ) as? FABActionSheet else {
            showAlert(title: .error, message: .errorMessage)
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
        showActionDialog(
            styled: .singleField,
            withTitle: .createFolder,
            placeholder: .folderName,
            positiveButtonTitle: .create,
            positiveAction: { self.newFolderAction() }
        )
    }
    
    // TODO: Move this to BaseVC
    func showActionDialog(
        styled style: ActionDialogStyle,
        withTitle title: String,
        placeholder: String? = nil,
        positiveButtonTitle: String,
        positiveAction: @escaping ButtonAction
    ) {
        actionDialog = ActionDialogView(
            frame: view.bounds,
            style: style,
            title: title,
            positiveButtonTitle: positiveButtonTitle,
            placeholder: placeholder
        )
        
        actionDialog?.positiveAction = positiveAction
        view.addSubview(actionDialog!)
    }
    
    func showActionSheet() {
        let photoLibraryAction = UIAlertAction(title: .photoLibrary, style: .default) { _ in self.openPhotoLibrary() }
        let browseAction = UIAlertAction(title: .browse, style: .default) { _ in self.openFileBrowser() }
        let cancelAction = UIAlertAction(title: .cancel, style: .cancel, handler: nil)
            
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        actionSheet.addActions([photoLibraryAction, browseAction, cancelAction])
        
        present(actionSheet, animated: true, completion: nil)
    }
    
    func openPhotoLibrary() {
        let imagePicker = ImagePickerController()
        
        presentImagePicker(imagePicker, select: nil, deselect: nil, cancel: nil, finish: { assets in
            self.viewModel?.didChooseFromPhotoLibrary(assets, completion: { urls in
                
                guard let currentFolder = self.viewModel?.navigationStack.last else {
                    // Display alert with cannot upload?
                    return
                }
                
                self.processUpload(toFolder: currentFolder, forURLS: urls)
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
    
    private func processUpload(toFolder folder: FileViewModel, forURLS urls: [URL]) {
        let folderInfo = FolderInfo(
            folderId: folder.folderId,
            folderLinkId: folder.folderLinkId
        )
        
        let files = FileInfo.createFiles(from: urls, parentFolder: folderInfo)
        upload(files: files)
    }
    
    private func newFolderAction() {
        guard let folderName = actionDialog?.fieldsInput?.first else {
            DispatchQueue.main.async {
                self.showAlert(title: .error, message: .errorMessage)
            }
            return
        }
        
        if folderName.isEmpty {
            return
        }
        
        actionDialog?.dismiss()
        createNewFolder(named: folderName)
    }
}

// MARK: - Document Picker Delegate

extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let currentFolder = viewModel?.navigationStack.last else {
            // Display alert with cannot upload?
            return
        }
        
        processUpload(toFolder: currentFolder, forURLS: urls)
    }
}
