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
    let segmentedControlView: WorkspaceSegmentedControlView = WorkspaceSegmentedControlView()
    let folderNavigationView: FolderNavigationView = FolderNavigationView()
    let folderContentView: FolderContentView = FolderContentView()
    
    var delegate: ShareFileBrowserViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Choose Destination"
        
        edgesForExtendedLayout = []
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelButtonPressed(_:)))
        
        viewModel?.loadRootFolder()
        
        initUI()
        styleNavBar()
        
        NotificationCenter.default.addObserver(self, selector: #selector(updateContentViewModels), name: FileBrowserViewModel.didUpdateContentViewModels, object: viewModel)
        NotificationCenter.default.addObserver(self, selector: #selector(popToWorkspace), name: ShareFolderNavigationViewModel.didPopToWorkspaceNotification, object: viewModel?.navigationViewModel)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        folderContentView.invalidateLayout()
    }
    
    func initUI() {
        setupFolderContentView()
        setupFolderNavigationView()
        setupWorkspaceSegmentedControlView()
        activateConstraints()
    }
    
    func setupFolderContentView() {
        folderContentView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(folderContentView)
    }
    
    func setupFolderNavigationView() {
        folderNavigationView.translatesAutoresizingMaskIntoConstraints = false
        folderNavigationView.viewModel = viewModel?.navigationViewModel
        folderNavigationView.layer.shadowColor = UIColor.black.cgColor
        folderNavigationView.layer.shadowOpacity = 1
        folderNavigationView.layer.shadowOffset = .zero
        folderNavigationView.layer.shadowRadius = 3
        view.addSubview(folderNavigationView)
        
    }
    
    func setupWorkspaceSegmentedControlView() {
        if let workspace = viewModel?.workspace, (workspace == Workspace.sharedByMeFiles || workspace == Workspace.shareWithMeFiles) {
            segmentedControlView.translatesAutoresizingMaskIntoConstraints = false
            segmentedControlView.viewModel = viewModel
            view.addSubview(segmentedControlView)
        }
    }
    
    func activateConstraints() {
        if let workspace = viewModel?.workspace, (workspace == Workspace.sharedByMeFiles || workspace == Workspace.shareWithMeFiles) {
            NSLayoutConstraint.activate([
                segmentedControlView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                segmentedControlView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                segmentedControlView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
                segmentedControlView.heightAnchor.constraint(equalToConstant: segmentedControlView.intrinsicContentSize.height),
                folderNavigationView.topAnchor.constraint(equalTo: segmentedControlView.bottomAnchor, constant: 0),
                folderNavigationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                folderNavigationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                folderNavigationView.heightAnchor.constraint(equalToConstant: folderNavigationView.intrinsicContentSize.height),
                folderContentView.topAnchor.constraint(equalTo: folderNavigationView.bottomAnchor, constant: 0),
                folderContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
                folderContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                folderContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
            ])
        } else {
            NSLayoutConstraint.activate([
                folderNavigationView.topAnchor.constraint(equalTo: view.topAnchor, constant: 0),
                folderNavigationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                folderNavigationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0),
                folderNavigationView.heightAnchor.constraint(equalToConstant: folderNavigationView.intrinsicContentSize.height),
                folderContentView.topAnchor.constraint(equalTo: folderNavigationView.bottomAnchor, constant: 0),
                folderContentView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: 0),
                folderContentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 0),
                folderContentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 0)
            ])
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
    
    @objc func updateContentViewModels() {
        folderContentView.viewModel = viewModel?.contentViewModels.last
        if viewModel?.hasSaveButton ?? false {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(doneButtonPressed(_:)))
        } else {
            navigationItem.rightBarButtonItem = nil
        }
    }

    @objc func popToWorkspace() {
        navigationController?.popViewController(animated: true)
    }
}
