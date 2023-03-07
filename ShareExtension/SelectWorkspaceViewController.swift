//
//  SelectWorkspaceViewController.swift
//  ShareExtension
//
//  Created by Vlad Alexandru Rusu on 07.02.2023.
//

import UIKit

protocol SelectWorkspaceViewControllerDelegate: AnyObject {
    func selectWorkspaceViewControllerDidPickFolder(named name: String, folderInfo: FolderInfo)
}

class SelectWorkspaceViewController: BaseViewController<SaveDestinationBrowserViewModel> {
    weak var delegate: SelectWorkspaceViewControllerDelegate?
    
    @IBOutlet weak var sharedFilesImageView: UIImageView!
    @IBOutlet weak var publicFilesImageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Choose Folder"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
        styleNavBar()
        
        if viewModel?.hasPublicFilesPermission() ?? false {
            publicFilesImageView.image = UIImage(named: "PublicFilesWorkspaceIcon")
        } else {
            publicFilesImageView.image = UIImage(named: "publicFilesWorkspaceDisabledIcon")
        }
    }
    
    @objc func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true)
    }
    
    @IBAction func privateFilesButtonPressed(_ sender: Any) {
        let selectFolderVC = ShareFileBrowserViewController()
        selectFolderVC.delegate = self
        selectFolderVC.viewModel = SaveDestinationBrowserViewModel(workspace: .privateFiles)
        
        navigationController?.pushViewController(selectFolderVC, animated: true)
    }
    
    @IBAction func publicFilesButtonPressed(_ sender: Any) {
        if viewModel?.hasPublicFilesPermission() ?? false {
            self.showActionDialog(
                styled: .simpleWithDescription,
                withTitle: "Public Files".localized(),
                description: "Upload a publicly viewable copy of these items in your Public workspace and get a public link to share with anyone.".localized(),
                positiveButtonTitle: "Continue".localized(),
                positiveAction: {
                    let selectFolderVC = ShareFileBrowserViewController()
                    selectFolderVC.delegate = self
                    selectFolderVC.viewModel = SaveDestinationBrowserViewModel(workspace: .publicFiles)
                    
                    self.navigationController?.pushViewController(selectFolderVC, animated: true)
                },
                overlayView: nil
            )
        } else {
            let alert = UIAlertController(title: "Uh oh".localized(), message: "You do not have permission to upload public files.".localized(), preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: .ok, style: .default, handler: { _ in
            }))

            self.present(alert, animated: true)
        }
    }
    
    @IBAction func sharedFilesButtonPressed(_ sender: Any) {
        let selectFolderVC = ShareFileBrowserViewController()
        selectFolderVC.delegate = self
        selectFolderVC.viewModel = SaveDestinationBrowserViewModel(workspace: .sharedFiles)
        
        navigationController?.pushViewController(selectFolderVC, animated: true)
    }
}

extension SelectWorkspaceViewController: ShareFileBrowserViewControllerDelegate {
    func shareFileBrowserViewControllerDidPickFolder(named name: String, folderInfo: FolderInfo) {
        delegate?.selectWorkspaceViewControllerDidPickFolder(named: name, folderInfo: folderInfo)
    }
}
