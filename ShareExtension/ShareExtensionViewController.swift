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
        handleSharedFile()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    fileprivate func initUI() {
        styleNavBar()
        
        title = "Permanent"
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Upload".localized(), style: .plain, target: self, action: #selector(didTapUpload))
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
        
        if let hasActiveSession = viewModel?.hasActiveSession(), !hasActiveSession {
            let alert = UIAlertController(title: "Uh oh", message: "You do not have an active session. Please log in to Permanent.".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: .ok, style: .default, handler: { _ in
                self.didTapCancel()
            }))
            
            self.present(alert, animated: true)
        }
        
        if viewModel?.hasUploadPermission() == false {
            let alert = UIAlertController(title: "Uh oh", message: "You are a viewer of the selected archive and do not have permission to upload files.".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: .cancel, style: .default, handler: { _ in
                self.didTapCancel()
            }))
            alert.addAction(UIAlertAction(title: "Change Archive".localized(), style: .default, handler: { action in
                self.selectArchiveButtonPressed(action)
            }))
            
            self.present(alert, animated: true)
        }
        
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        
        viewModel?.processSelectedFiles(attachments: attachments, then: { status in
            self.stopLoadingAnimation()
        })
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
    
    @objc func didTapUpload() {
        let alert = UIAlertController(title: "Preparing Files...".localized(), message: nil, preferredStyle: .alert)
        present(alert, animated: true)
        
        viewModel?.uploadSelectedFiles() { [self] error in
            dismiss(animated: false) { [self] in
                if error != nil {
                    showUploadErrorAlert()
                }
                
                extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
            }
        }
    }
    
    @objc func didTapCancel() {
        extensionContext!.completeRequest(returningItems: nil, completionHandler: nil)
    }
    
    @IBAction func selectFolderButtonPressed(_ sender: Any) {
        let storyboard = UIStoryboard(name: "MainInterface", bundle: nil)
        let selectFolderVC = storyboard.instantiateViewController(withIdentifier: "selectWorkspace") as! SelectWorkspaceViewController
        selectFolderVC.delegate = self
        let navController = ShareExtensionNavigationController(rootViewController: selectFolderVC)
        
        present(navController, animated: true)
    }
    
    @IBAction func selectArchiveButtonPressed(_ sender: Any) {
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
