//
//  SettingsRouter.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.02.2024.

import Foundation
import SwiftUI

class SettingsRouter: ObservableObject {
    enum View {
        case settings
        case account
        case storage
        case myArchives
        case invitations
        case activityFeed
        case security
        case legacyPlanning
        case signUp
    }
    
    var rootViewController: RootNavigationController
    var currentView: View
    
    init(rootViewController: RootNavigationController, currentView: View) {
        self.rootViewController = rootViewController
        self.currentView = currentView
    }
    
    func navigate(to view: View, router: SettingsRouter) {
        if view != .settings {
            self.rootViewController.dismiss(animated: true)
        }
        switch view {
        case .settings:
            let settingsScreenView = SettingsScreenView(viewModel: StateObject(wrappedValue: SettingsScreenViewModel()), router: router)
            let host = UIHostingController(rootView: settingsScreenView)
            self.rootViewController.present(host, animated: true, completion: nil)
        case .account:
            let screenView = AccountInfoView()
            let host = UIHostingController(rootView: screenView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
        case .storage:
            currentView = .storage
            let storageView = StorageView(viewModel: StateObject(wrappedValue: StorageViewModel.init()))
            let host = UIHostingController(rootView: storageView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
        case .myArchives:
            let screenView = ArchivesView()
            let host = UIHostingController(rootView: screenView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
        case .invitations:
            let currentView = InvitesView()
            let host = UIHostingController(rootView: currentView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
        case .activityFeed:
            let currentView = ActivityFeedView()
            let host = UIHostingController(rootView: currentView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
        case .security:
            let currentView = AccountSettingsView()
            let host = UIHostingController(rootView: currentView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
        case .legacyPlanning:
            let legacyPlanningLoadingVC = LegacyPlanningLoadingViewController()
            legacyPlanningLoadingVC.viewModel = LegacyPlanningViewModel()
            legacyPlanningLoadingVC.viewModel?.account = AuthenticationManager.shared.session?.account
            let host = NavigationController(rootViewController: legacyPlanningLoadingVC)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
        case .signUp:
            UploadManager.shared.cancelAll()
            
            AppDelegate.shared.rootViewController.setRoot(named: .signUp, from: .authentication)
        }
    }
}
