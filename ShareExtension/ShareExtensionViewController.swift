//
//  ShareExtensionViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.08.2020.
//

import UIKit
import MobileCoreServices
import UniformTypeIdentifiers

@objc(ShareExtensionViewController)
class ShareExtensionViewController: BaseViewController<ShareExtensionViewModel> {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var statusLabel: UILabel!
    @IBOutlet weak var archiveNameLabel: UILabel!
    @IBOutlet weak var saveFolderLabel: UILabel!
    @IBOutlet weak var separatorOneView: UIView!
    @IBOutlet weak var archiveImageView: UIImageView!
    @IBOutlet weak var saveFolderImageView: UIImageView!
    @IBOutlet weak var selectFolderButton: UIButton!
    @IBOutlet weak var selectArchiveButton: UIButton!
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait]
        } else {
            return [.all]
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = ShareExtensionViewModel()
        initUI()
        setupTableView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        // Only handle shared files after view appears to avoid view hierarchy issues
        handleSharedFile()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    fileprivate func initUI() {
        styleNavBar()
        
        title = "Permanent"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Upload".localized(), style: .plain, target: self, action: #selector(uploadButtonPressed(_:)))
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel".localized(), style: .plain, target: self, action: #selector(didTapCancel))
        
        saveFolderLabel.text = viewModel?.folderDisplayName
        archiveImageView.image = UIImage(named: "placeholder")
        saveFolderImageView.image = UIImage(named: "shareFolder")
        
        archiveNameLabel.font = TextFontStyle.style4.font
        saveFolderLabel.font = TextFontStyle.style4.font
        
        archiveNameLabel.textColor = .black
        saveFolderLabel.textColor = .black
        separatorOneView.backgroundColor = .lightGray
    }
    
    fileprivate func setupTableView() {
        tableView.separatorStyle = .none
        tableView.register(UINib(nibName: String(describing: FileDetailsTableViewCell.self), bundle: nil), forCellReuseIdentifier: String(describing: FileDetailsTableViewCell.self))
        
        tableView.backgroundColor = .white
    }
    
    private func handleSharedFile() {
        updateArchiveView()
        
        // Check for active session first
        guard let hasActiveSession = viewModel?.hasActiveSession(), hasActiveSession else {
            showSessionExpiredAlert()
            return
        }
        
        // Check upload permissions
        if viewModel?.hasUploadPermission() == false {
            let alert = UIAlertController(title: "Uh oh", message: "You are a viewer of the selected archive and do not have permission to upload files.".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: .cancel, style: .default, handler: { _ in
                self.didTapCancel()
            }))
            alert.addAction(UIAlertAction(title: "Change Archive".localized(), style: .default, handler: { action in
                self.selectArchiveButtonPressed(action)
            }))
            
            self.present(alert, animated: true)
            return
        }
        
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        
        viewModel?.processSelectedFiles(attachments: attachments, then: { status in
            self.stopLoadingAnimation()
        })
    }
    
    private func showSessionExpiredAlert() {
        let alert = UIAlertController(
            title: "Login Required", 
            message: "Please open the Permanent app and log in to use the share extension.", 
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.didTapCancel()
        }))
        
        if view.window != nil {
            present(alert, animated: true)
        } else {
            // If not in hierarchy yet, wait a bit and try again
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.view.window != nil {
                    self.present(alert, animated: true)
                } else {
                    // If still not available, just cancel
                    self.didTapCancel()
                }
            }
        }
    }
    
    func updateArchiveView() {
        archiveNameLabel.text = viewModel?.archiveName()
        
        if let archiveThumnailUrl = viewModel?.archiveThumbnailUrl() {
            archiveImageView.load(urlString: archiveThumnailUrl)
        }
    }
    
    func stopLoadingAnimation() {
        self.activityIndicator.stopAnimating()
        self.statusLabel.isHidden = true
        self.tableView.reloadData()
    }
    
    func showUploadErrorAlert() {
        let alert = UIAlertController(title: "Error".localized(), message: "ErrorMessage".localized(), preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok".localized(), style: .default, handler: nil))
        
        present(alert, animated: true)
    }
    
    private func showStorageQuotaExceededAlert() {
        let alert = UIAlertController(
            title: "Storage Full", 
            message: "You don't have enough storage space to upload these files. Please free up space or upgrade your storage plan in the Permanent app.", 
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { _ in
            self.didTapCancel()
        }))
        if view.window != nil {
            present(alert, animated: true)
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if self.view.window != nil {
                    self.present(alert, animated: true)
                } else {
                    self.didTapCancel()
                }
            }
        }
    }
    
    @IBAction func uploadButtonPressed(_ sender: Any) {
        navigationItem.rightBarButtonItem?.isEnabled = false
        
        viewModel?.uploadSelectedFiles(completion: { error in
            DispatchQueue.main.async {
                self.navigationItem.rightBarButtonItem?.isEnabled = true
                
                if let error = error {
                    if let quotaError = error as? StorageQuotaError {
                        switch quotaError {
                        case .insufficientSpace:
                            self.showStorageQuotaExceededAlert()
                        case .apiError:
                            // The quota check itself failed (offline / transient / expired token).
                            // Don't claim "Storage Full" or cancel the share — show a retryable
                            // message; the upload button is already re-enabled above.
                            let alert = UIAlertController(title: "Couldn’t check storage".localized(),
                                                          message: quotaError.localizedDescription,
                                                          preferredStyle: .alert)
                            alert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
                            self.present(alert, animated: true, completion: nil)
                        }
                    } else {
                        let alert = UIAlertController(title: "Upload Error", message: error.localizedDescription, preferredStyle: .alert)
                        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                        self.present(alert, animated: true, completion: nil)
                    }
                } else {
                    self.extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
                }
            }
        })
    }
    
    @objc func didTapCancel() {
        extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @IBAction func selectFolderButtonPressed(_ sender: Any) {
        // Check if we have a valid session before presenting folder selection
        guard viewModel?.hasActiveSession() == true else {
            showSessionExpiredAlert()
            return
        }
        
        let storyboard = UIStoryboard(name: "MainInterface", bundle: nil)
        let selectFolderVC = storyboard.instantiateViewController(withIdentifier: "selectWorkspace") as! SelectWorkspaceViewController
        selectFolderVC.delegate = self
        let navController = ShareExtensionNavigationController(rootViewController: selectFolderVC)
        
        present(navController, animated: true)
    }
    
    @IBAction func selectArchiveButtonPressed(_ sender: Any) {
        // Check if we have a valid session before presenting archives
        guard viewModel?.hasActiveSession() == true else {
            showSessionExpiredAlert()
            return
        }
        
        let archivesVC = UIViewController.create(withIdentifier: .archives, from: .archives) as! ArchivesViewController
        archivesVC.delegate = self
        archivesVC.isManaging = false
        archivesVC.accountArchives = nil
        
        let navController = UINavigationController(rootViewController: archivesVC)
        present(navController, animated: true, completion: nil)
    }
}

extension ShareExtensionViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel?.selectedFiles.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var tableViewCell = UITableViewCell()
        
        if let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: FileDetailsTableViewCell.self)) as? FileDetailsTableViewCell {
            guard let selectedFile = viewModel?.selectedFiles[indexPath.row],
                let cellConfiguration = viewModel?.cellConfigurationParameters(file: selectedFile) else { return UITableViewCell() }
            
            cell.configure(with: cellConfiguration)
            cell.rightButtonAction = { [weak self] cell in
                self?.viewModel?.removeSelectedFile(selectedFile)
                self?.tableView.reloadData()
            }
            tableViewCell = cell
        }
        return tableViewCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return CGFloat(60)
    }
}

extension ShareExtensionViewController: ArchivesViewControllerDelegate {
    func archivesViewController(_ vc: ArchivesViewController, shouldChangeToArchive toArchive: ArchiveVOData) -> Bool {
        let hasUploadPermission = toArchive.permissions().contains(.upload)
        if hasUploadPermission == false {
            dismiss(animated: true) {
                let alert = UIAlertController(title: "Uh oh", message: "You are a viewer of the selected archive and do not have permission to upload files.".localized(), preferredStyle: .alert)
                alert.addAction(UIAlertAction(title: .ok, style: .default, handler: { _ in
                }))
                
                self.present(alert, animated: true)
            }
        }
        
        return hasUploadPermission
    }
    
    func archivesViewControllerDidChangeArchive(_ vc: ArchivesViewController) {
        updateArchiveView()
        viewModel?.archiveUpdated()
    }
}

extension ShareExtensionViewController: SelectWorkspaceViewControllerDelegate {
    func selectWorkspaceViewControllerDidPickFolder(named name: String, folderInfo: FolderInfo) {
        viewModel?.updateSelectedFolder(withName: name, folderInfo: folderInfo)
        saveFolderLabel.text = viewModel?.folderDisplayName
    }
}
