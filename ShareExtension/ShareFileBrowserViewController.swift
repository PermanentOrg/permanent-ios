//
//  ShareFileBrowserViewController.swift
//  ShareExtension
//
//  Created by Vlad Alexandru Rusu on 20.10.2022.
//

import Foundation
import UIKit

protocol ShareFileBrowserViewControllerDelegate {
    func shareFileBrowserViewControllerDidPickFolder(named name: String, folderInfo: FolderInfo)
}

class ShareFileBrowserViewController: BaseViewController<SaveDestinationBrowserViewModel> {
    let folderContentView: FolderContentView = FolderContentView()
    let folderNavigationView: FolderNavigationView = FolderNavigationView()
    
    var delegate: ShareFileBrowserViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Choose Destination"
        
        edgesForExtendedLayout = []
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
        
        viewModel?.loadRootFolder()
        
        initUI()
        styleNavBar()
        
        NotificationCenter.default.addObserver(forName: FileBrowserViewModel.didUpdateContentViewModels, object: viewModel, queue: nil) { [weak self] notif in
            guard let self = self else { return }
            self.folderContentView.viewModel = self.viewModel?.contentViewModels.last
            
            if self.viewModel?.hasSaveButton ?? false {
                self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(self.doneButtonPressed(_:)))
            } else {
                self.navigationItem.rightBarButtonItem = nil
            }
        }
        
        NotificationCenter.default.addObserver(forName: ShareFolderNavigationViewModel.didPopToWorkspaceNotification, object: viewModel?.navigationViewModel, queue: nil) { [weak self] notif in
            guard let self = self else { return }
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        folderContentView.invalidateLayout()
    }
    
    func initUI() {
        folderContentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(folderContentView)
        
        folderNavigationView.translatesAutoresizingMaskIntoConstraints = false
        folderNavigationView.viewModel = viewModel?.navigationViewModel
        folderNavigationView.layer.shadowColor = UIColor.black.cgColor
        folderNavigationView.layer.shadowOpacity = 1
        folderNavigationView.layer.shadowOffset = .zero
        folderNavigationView.layer.shadowRadius = 3
        view.addSubview(folderNavigationView)
        
        NSLayoutConstraint.activate([
            folderNavigationView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
            folderNavigationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            folderNavigationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
            folderContentView.topAnchor.constraint(equalTo: folderNavigationView.bottomAnchor, constant: 0),
            folderContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
            folderContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
            folderContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
        ])
        
        if let workspace = viewModel?.workspace, (workspace == Workspace.sharedByMeFiles || workspace == Workspace.shareWithMeFiles) {
            NSLayoutConstraint.activate([folderNavigationView.heightAnchor.constraint(equalToConstant: 110)])
        } else {
            NSLayoutConstraint.activate([folderNavigationView.heightAnchor.constraint(equalToConstant: 40)])
        }
    }
    
    @objc func cancelButtonPressed(_ sender: UIBarButtonItem) {
        dismiss(animated: true)
    }
    
    @objc func doneButtonPressed(_ sender: UIBarButtonItem) {
        if let folderName = viewModel?.selectedFolder()?.name,
           let folderInfo = viewModel?.selectedFolderInfo() {
            delegate?.shareFileBrowserViewControllerDidPickFolder(named: folderName, folderInfo: folderInfo)
        }
        dismiss(animated: true)
    }
}
