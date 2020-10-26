//
//  MainViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

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
        sortButton.setTitleColor(.middleGrey, for: [])
        sortButton.tintColor = .middleGrey
        sortButton.setTitle(Translations.name, for: [])
    }
    
    // MARK: - Actions
    
    private func getRoot() {
        showSpinner()
        
        viewModel?.getRoot(then: { status in
            self.onFilesFetchCompletion(status)
        })
    }
    
    private func navigateToFolder(withParams params: NavigateMinParams, backNavigation: Bool, then handler: @escaping () -> Void) {
        showSpinner()
        
        viewModel?.navigateMin(params: params, backNavigation: backNavigation, then: { status in
            self.onFilesFetchCompletion(status)
            handler()
        })
    }
    
    private func onFilesFetchCompletion(_ status: RequestStatus) {
        hideSpinner()
        
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
        let files = fileURLS.map {
            FileInfo(withFileURL: $0,
                     filename: $0.lastPathComponent,
                     name: $0.lastPathComponent,
                     mimeType: "application/pdf") // TODO:
        }
        
        showSpinner()
        
        DispatchQueue.global(qos: .userInitiated).async {
            self.viewModel?.upload(files: files, recordId: "52719") { status in
                DispatchQueue.main.async {
                    self.hideSpinner()
                }
                
                switch status {
                case .success:
                    break
                    
                case .error(let message):
                    DispatchQueue.main.async {
                        self.showAlert(title: Translations.error, message: message)
                    }
                }
            }
        }
    }
}

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
        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: UIAlertController.Style.actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Take Photo or Video", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) -> Void in
        }))

        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) -> Void in
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Browse", style: UIAlertAction.Style.default, handler: { (_: UIAlertAction!) -> Void in
            self.openFileBrowser()
        }))

        actionSheet.addAction(UIAlertAction(title: "Cancel", style: UIAlertAction.Style.cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    func openFileBrowser() {
        let docPicker = UIDocumentPickerViewController(documentTypes: [kUTTypeImage as String,
                                                                       kUTTypeCompositeContent as String],
                                                       in: .import)
        docPicker.delegate = self // make the VM the delegate
        docPicker.allowsMultipleSelection = true
        present(docPicker, animated: true, completion: nil)
    }
}

extension MainViewController: UIDocumentPickerDelegate {
    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        for url in urls {
            print("Full path: ", url)
            print("Document: ", url.lastPathComponent)
            
            upload(fileURLS: urls)
        }
    }
}
