//
//  SharePreviewHostingController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.01.2026
//

import SwiftUI
import UIKit

/// UIHostingController wrapper for SharePreviewView (SwiftUI)
/// Maintains compatibility with existing UIKit navigation while using the new SwiftUI implementation
class SharePreviewHostingController: UIHostingController<SharePreviewView> {
    // MARK: - Properties
    private let shareToken: String
    
    /// Navigation callback to UIKit - called when user taps "View in archive" for share creators
    var navigateTo: ((NavigateMinParams) -> Void)?
    
    /// Navigation callback to UIKit - called when user taps "View in archive" for non-creators
    var navigateToShares: ((String) -> Void)?
    
    // MARK: - Init
    init(shareToken: String) {
        self.shareToken = shareToken
        
        // Create SwiftUI view with navigation callbacks that will be set later
        let rootView = SharePreviewView(
            shareToken: shareToken,
            onNavigateToFolder: nil,  // Will be wired up after properties are set
            onNavigateToShares: nil   // Will be wired up after properties are set
        )
        
        super.init(rootView: rootView)
    }
    
    /// Call this after setting navigateTo and navigateToShares properties to wire up callbacks
    func wireCallbacks() {
        self.rootView = SharePreviewView(
            shareToken: shareToken,
            onNavigateToFolder: { [weak self] params in
                self?.navigationController?.popViewController(animated: true)
                self?.navigateTo?(params)
            },
            onNavigateToShares: { [weak self] archiveNbr in
                guard let sharesVC = UIViewController.create(
                    withIdentifier: .shares,
                    from: .share
                ) as? SharesViewController else { return }
                
                sharesVC.sharedFolderArchiveNo = archiveNbr
                sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
                
                AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: sharesVC)
            },
            onNavigateToSharedWithMe: { [weak self] params in
                guard let self = self else { return }
                
                guard let sharesVC = UIViewController.create(
                    withIdentifier: .shares,
                    from: .share
                ) as? SharesViewController else { return }
                
                sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
                
                // If params provided, navigate into the folder
                if let params = params {
                    sharesVC.sharedFolderArchiveNo = params.archiveNo
                    sharesVC.sharedFolderLinkId = params.folderLinkId
                    sharesVC.sharedFolderName = params.folderName ?? "Shared Folder"
                    sharesVC.fileType = .sharedFolder // Set fileType to trigger folder navigation
                }
                
                AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: sharesVC)
            },
            onNavigateToSharedByMe: { [weak self] params in
                guard let self = self else { return }
                
                guard let sharesVC = UIViewController.create(
                    withIdentifier: .shares,
                    from: .share
                ) as? SharesViewController else { return }
                
                sharesVC.selectedIndex = ShareListType.sharedByMe.rawValue
                
                // If params provided, navigate into the folder
                if let params = params {
                    sharesVC.sharedFolderArchiveNo = params.archiveNo
                    sharesVC.sharedFolderLinkId = params.folderLinkId
                    sharesVC.sharedFolderName = params.folderName ?? "Shared Folder"
                    sharesVC.fileType = .sharedFolder // Set fileType to trigger folder navigation
                }
                
                AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: sharesVC)
            },
            onNavigateToFilePreview: { [weak self] params in
                guard let self = self else { return }
                
                // Navigate to Shared with Me tab first
                guard let sharesVC = UIViewController.create(
                    withIdentifier: .shares,
                    from: .share
                ) as? SharesViewController else { return }
                
                sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
                
                // Get current archive permissions
                let permissions = AuthenticationManager.shared.session?.selectedArchive?.accessRole.flatMap { 
                    ArchiveVOData.permissions(forAccessRole: $0) 
                } ?? []
                
                // Create the file model
                let file = FileModel(
                    name: params.name,
                    recordId: params.recordId,
                    folderLinkId: params.folderLinkId,
                    archiveNbr: params.archiveNbr,
                    type: params.type,
                    permissions: permissions,
                    thumbnailURL2000: params.thumbnailURL
                )
                
                // Change to shares view
                AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: sharesVC)
                
                // After a short delay to allow the view to load, present the file preview
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let filePreviewVC = FilePreviewListViewController(nibName: nil, bundle: nil)
                    filePreviewVC.modalPresentationStyle = .fullScreen
                    filePreviewVC.currentFile = file
                    filePreviewVC.isFromNotification = true
                    
                    // Use a minimal view model
                    let viewModel = MyFilesViewModel()
                    filePreviewVC.viewModel = viewModel
                    
                    let navController = FilePreviewNavigationController(rootViewController: filePreviewVC)
                    navController.modalPresentationStyle = .fullScreen
                    
                    sharesVC.present(navController, animated: true)
                }
            }
        )
    }
    
    @MainActor required dynamic init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Configure navigation bar appearance
        configureNavigationBar()
    }
    
    deinit {
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Ensure navigation bar is visible
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    // MARK: - Private
    private func configureNavigationBar() {
        // Match existing SharePreview navigation style
        navigationController?.navigationBar.prefersLargeTitles = false
        
        // Add close button if presented modally
        if presentingViewController != nil {
            let closeButton = UIBarButtonItem(
                barButtonSystemItem: .close,
                target: self,
                action: #selector(closeButtonTapped)
            )
            navigationItem.leftBarButtonItem = closeButton
        }
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
}
