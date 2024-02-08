//
//  SettingsRouter.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.02.2024.

import Foundation
import SwiftUI

class SettingsRouter: ObservableObject {
    enum Page {
        case settings
        case account
        case storage
        case myArchives
        case invitations
        case activityFeed
        case security
        case legacyPlanning
        case contactSupport
        case signUp
    }
    
    var rootViewController: RootNavigationController
    var currentView: Page
    
    init(rootViewController: RootNavigationController, currentView: Page) {
        self.rootViewController = rootViewController
        self.currentView = currentView
    }
    
    func navigate(to page: Page, router: SettingsRouter) {
        if page != .settings {
            self.rootViewController.dismiss(animated: true)
        }
        switch page {
        case .settings:
            let settingsScreenView = SettingsScreenView(viewModel: StateObject(wrappedValue: SettingsScreenViewModel()), router: router)
            let host = UIHostingController(rootView: settingsScreenView)
            self.rootViewController.present(host, animated: true, completion: nil)
        case .account:
            let screenView = ViewRepresentableContainer(viewRepresentable: AccountInfoViewControllerRepresentable(), title: AccountInfoViewControllerRepresentable().title)
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
            let screenView = ViewRepresentableContainer(viewRepresentable: ArchivesViewControllerRepresentable(), title: ArchivesViewControllerRepresentable().title)
            let host = UIHostingController(rootView: screenView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
        case .invitations:
            let currentView = ViewRepresentableContainer(viewRepresentable: InvitesViewControllerRepresentable(), title: InvitesViewControllerRepresentable().title)
            let host = UIHostingController(rootView: currentView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
        case .activityFeed:
            let currentView = ViewRepresentableContainer(viewRepresentable: ActivityFeedViewControllerRepresentable(), title: ActivityFeedViewControllerRepresentable().title)
            let host = UIHostingController(rootView: currentView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
        case .security:
            let currentView = ViewRepresentableContainer(viewRepresentable: AccountSettingsViewControllerRepresentable(), title: AccountSettingsViewControllerRepresentable().title)
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
        case .contactSupport:
            guard let url = URL(string: APIEnvironment.defaultEnv.helpURL) else { return }
            UIApplication.shared.open(url)
        case .signUp:
            UploadManager.shared.cancelAll()
            
            AppDelegate.shared.rootViewController.setRoot(named: .signUp, from: .authentication)
        }
    }
}
