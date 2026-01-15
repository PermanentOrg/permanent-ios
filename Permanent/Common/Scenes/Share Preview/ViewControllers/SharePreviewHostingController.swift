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
        
        // Create SwiftUI view with navigation callbacks
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
                
                self?.navigationController?.popViewController(animated: true)
                AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: sharesVC)
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
