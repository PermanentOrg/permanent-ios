//
//  ChecklistCongratsView.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.05.2025.

import UIKit
import SwiftUI

class ChecklistCoordinator {
    static let shared = ChecklistCoordinator()
    
    private init() {}
    
    func presentViewController(_ viewController: UIViewController) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.dismiss(animated: true) {
                let navControl = NavigationController(rootViewController: viewController)
                if Constants.Design.isPhone {
                    navControl.modalPresentationStyle = .fullScreen
                } else {
                    
                    navControl.modalPresentationStyle = .formSheet
                    navControl.sheetPresentationController?.detents = [.large()]
                }
                
                window.rootViewController?.present(navControl, animated: true)
            }
        }
    }
    
    func presentSwiftUIView<Content: View>(_ view: Content) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.dismiss(animated: true) {
                let hostingController = UIHostingController(rootView: view)
                if Constants.Design.isPhone {
                    hostingController.modalPresentationStyle = .fullScreen
                } else {
                    hostingController.modalPresentationStyle = .formSheet
                    hostingController.sheetPresentationController?.detents = [.large()]
                }
                
                window.rootViewController?.present(hostingController, animated: true)
            }
        }
    }
    
    func presentStorageRedeem() {
        let storageViewModel = StorageViewModel()
        let storageView = StorageView(viewModel: StateObject(wrappedValue: storageViewModel))
        storageViewModel.redeemStorageIspresented = true
        presentSwiftUIView(storageView)
    }
    
    func presentLegacyContact() {
        if let legacyPlanningLoadingVC = UIViewController.create(withIdentifier: .legacyPlanningLoading, from: .legacyPlanning) as? LegacyPlanningLoadingViewController {
            legacyPlanningLoadingVC.viewModel = LegacyPlanningViewModel()
            legacyPlanningLoadingVC.viewModel?.account = AuthenticationManager.shared.session?.account
            let customNavController = NavigationController(rootViewController: legacyPlanningLoadingVC)
            customNavController.modalPresentationStyle = .fullScreen
            presentViewController(legacyPlanningLoadingVC)
        }
    }
    
    func presentArchiveSteward() {
        if let archiveLegacyPlanningVC = UIViewController.create(withIdentifier: .legacyPlanningSteward, from: .legacyPlanning) as? LegacyPlanningStewardViewController,
           let archiveData = AuthenticationManager.shared.session?.selectedArchive {
            archiveLegacyPlanningVC.viewModel = LegacyPlanningViewModel()
            archiveLegacyPlanningVC.selectedArchive = archiveData
            archiveLegacyPlanningVC.viewModel?.account = AuthenticationManager.shared.session?.account
            archiveLegacyPlanningVC.viewModel?.stewardType = .archive
            presentViewController(archiveLegacyPlanningVC)
        }
    }
    
    func presentArchiveProfile() {
        if let archiveProfileVC = UIViewController.create(withIdentifier: .publicArchive, from: .profile) as? PublicArchiveViewController,
           let archiveData = AuthenticationManager.shared.session?.selectedArchive {
            archiveProfileVC.archiveData = archiveData
            archiveProfileVC.isViewingPublicProfile = true
            
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                window.rootViewController?.dismiss(animated: true) {
                    let navControl = NavigationController(rootViewController: archiveProfileVC)
                    navControl.modalPresentationStyle = .fullScreen
                    window.rootViewController?.present(navControl, animated: true)
                }
            }
        }
    }
    
    func presentSupportForUploadFile() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.dismiss(animated: true) {
                UIApplication.shared.open(URL(string: "https://permanent.zohodesk.com/portal/en/kb/articles/uploading-files-mobile-apps")!)
            }
        }
    }
    
    func presentSupportForPublishFiles() {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.dismiss(animated: true) {
                UIApplication.shared.open(URL(string: "https://permanent.zohodesk.com/portal/en/kb/articles/how-to-publish-a-file-or-folder-mobile")!)
            }
        }
    }
}
