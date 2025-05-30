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
                navControl.modalPresentationStyle = .fullScreen
                window.rootViewController?.present(navControl, animated: true)
            }
        }
    }
    
    func presentSwiftUIView<Content: View>(_ view: Content) {
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.dismiss(animated: true) {
                let hostingController = UIHostingController(rootView: view)
                hostingController.modalPresentationStyle = .fullScreen
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
        if let legacyPlanningStewardVC = UIViewController.create(withIdentifier: .legacyPlanningSteward, from: .legacyPlanning) as? LegacyPlanningStewardViewController {
            legacyPlanningStewardVC.viewModel = LegacyPlanningViewModel()
            legacyPlanningStewardVC.viewModel?.stewardType = .account
            presentViewController(legacyPlanningStewardVC)
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
            presentViewController(archiveProfileVC)
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
