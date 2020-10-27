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
    @IBOutlet var sortButton: UIButton!
    @IBOutlet var tableView: UITableView!
    @IBOutlet var fabView: FABView!
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initUI()
        
        viewModel = FilesViewModel()
        tableView.register(UINib(nibName: String(describing: FileTableViewCell.self), bundle: nil),
                           forCellReuseIdentifier: String(describing: FileTableViewCell.self))
        tableView.tableFooterView = UIView()
        fabView.delegate = self
        
        getRoot()
    }
    
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
        
        sortButton.setFont(Text.style11.font)
        sortButton.setTitleColor(.middleGray, for: [])
        sortButton.tintColor = .middleGray
        sortButton.setTitle(Translations.name, for: [])
    }
    
    // MARK: - Actions
    
    private func getRoot() {
        showSpinner()
        
        viewModel?.getRoot(then: { status in
            self.onFilesFetchCompletion(status)
        })
    }
    
    private func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, then handler: (() -> Void)? = nil) {
        showSpinner()
        
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
                self.handleTableBackgroundView()
                self.tableView.reloadData()
            }
            
        case .error(let message):
            DispatchQueue.main.async {
                self.showAlert(title: Translations.error, message: message)
            }
        }
    }
    
    @IBAction func backButtonAction(_ sender: UIButton) {
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
    
    func handleTableBackgroundView() {
        guard
            let viewModel = viewModel,
            !viewModel.viewModels.isEmpty
        else {
            tableView.backgroundView = EmptyFolderView()
            return
        }
        
        tableView.backgroundView = nil
    }
    
    func upload(fileURLS: [URL]) {
        viewModel?.uploadFiles(fileURLS, then: { status in
            switch status {
            case .success:
                self.onUploadSuccess()
                
            case .error(let message):
                DispatchQueue.main.async {
                    self.hideSpinner()
                    self.showAlert(title: Translations.error, message: message)
                }
            }
        })
    }
    
    func onUploadSuccess() {
        guard
            let viewModel = viewModel,
            let currentFolder = viewModel.navigationStack.last
        else {
            return
        }
        
        let params: NavigateMinParams = (currentFolder.archiveNo, currentFolder.folderLinkId, viewModel.csrf)
        navigateToFolder(withParams: params, backNavigation: true, then: nil)
    }
}

// MARK: - Table View Delegates

extension MainViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.viewModels.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let viewModel = self.viewModel,
            let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FileTableViewCell.self)) as? FileTableViewCell
        else {
            fatalError()
        }
        
        let file = viewModel.viewModels[indexPath.row]
        cell.updateCell(model: file)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let viewModel = viewModel else {
            fatalError()
        }
        
        let file = viewModel.viewModels[indexPath.row]
        guard file.type.isFolder else { return }

        let navigateParams: NavigateMinParams = (file.archiveNo, file.folderLinkId, viewModel.csrf)
        navigateToFolder(withParams: navigateParams, backNavigation: false, then: {
            self.backButton.isHidden = false
            self.directoryLabel.text = file.name
        })
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
        print("TODO")
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
