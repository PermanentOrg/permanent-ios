//
//  SettingsRouter.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.02.2024.

import Foundation
import SwiftUI

class SettingsRouter {
    enum Page {
        case settings
        case account
        case storage
        case myArchives
        case invitations
        case activityFeed
        case loginAndSecurity
        case legacyPlanning
        case contactSupport
        case signUp
        case memberChecklist
    }
    
    var rootViewController: RootNavigationController
    var currentPage: Page = .settings
    static let showMemberChecklistNotifName = NSNotification.Name("SettingsRouter.showMemberChecklistNotifName")
    
    init(rootViewController: RootNavigationController) {
        self.rootViewController = rootViewController
    }
    
    func navigate(to page: Page, router: SettingsRouter) {
        // Reset scroll view appearance before dismissing current screen
        ScrollViewAppearanceManager.shared.reset()
        
        if page != .settings {
            self.rootViewController.dismiss(animated: true)
        }
        currentPage = page
        switch page {
        case .settings:
            let screenView = SettingsScreenView(viewModel: StateObject(wrappedValue: SettingsScreenViewModel()), router: router)
            let host = UIHostingController(rootView: screenView)
            host.sheetPresentationController?.detents = [.large()]
            self.rootViewController.present(host, animated: true, completion: nil)
            
        case .account:
            let infoRepresentable: AccountInfoViewControllerRepresentable = AccountInfoViewControllerRepresentable()
            let screenView = ViewRepresentableContainer(viewRepresentable: infoRepresentable, title: AccountInfoViewControllerRepresentable().title)
            let host = UIHostingController(rootView: screenView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
            
        case .storage:
            let storageViewModel = StorageViewModel()
            let storageView = StorageView(viewModel: StateObject(wrappedValue: storageViewModel))
            presentSwiftUIView(storageView)
            
        case .myArchives:
            let screenView = ViewRepresentableContainer(viewRepresentable: ArchivesViewControllerRepresentable(), title: ArchivesViewControllerRepresentable().title)
            let host = UIHostingController(rootView: screenView)
            host.modalPresentationStyle = .fullScreen
            if !Constants.Design.isPhone {
                host.modalPresentationStyle = .formSheet
            }
            self.rootViewController.present(host, animated: true, completion: nil)
            
        case .invitations:
            let screenView = ViewRepresentableContainer(viewRepresentable: InvitesViewControllerRepresentable(), title: InvitesViewControllerRepresentable().title)
            let host = UIHostingController(rootView: screenView)
            host.modalPresentationStyle = .fullScreen
            if !Constants.Design.isPhone {
                host.modalPresentationStyle = .formSheet
            }
            self.rootViewController.present(host, animated: true, completion: nil)
            
        case .activityFeed:
            let screenView = ViewRepresentableContainer(viewRepresentable: ActivityFeedViewControllerRepresentable(), title: ActivityFeedViewControllerRepresentable().title)
            let host = UIHostingController(rootView: screenView)
            host.modalPresentationStyle = .fullScreen
            if !Constants.Design.isPhone {
                host.modalPresentationStyle = .formSheet
            }
            self.rootViewController.present(host, animated: true, completion: nil)
            
        case .loginAndSecurity:
            let screenView = LoginSecurityView(viewModel: StateObject(wrappedValue: LoginSecurityViewModel()))
            let host = UIHostingController(rootView: screenView)
            host.modalPresentationStyle = .fullScreen
            self.rootViewController.present(host, animated: true, completion: nil)
            
        case .legacyPlanning:
            let legacyPlanningLoadingVC = LegacyPlanningLoadingViewController()
            legacyPlanningLoadingVC.viewModel = LegacyPlanningViewModel()
            legacyPlanningLoadingVC.viewModel?.account = AuthenticationManager.shared.session?.account
            let host = NavigationController(rootViewController: legacyPlanningLoadingVC)
            host.modalPresentationStyle = .fullScreen
            if !Constants.Design.isPhone {
                host.modalPresentationStyle = .formSheet
            }
            
            self.rootViewController.present(host, animated: true, completion: nil)
            
        case .contactSupport:
            guard let url = URL(string: APIEnvironment.defaultEnv.helpURL) else { return }
            UIApplication.shared.open(url)
            
        case .signUp:
            UploadManager.shared.cancelAll()
            
            AppDelegate.shared.rootViewController.setRoot(named: .signUp, from: .authentication)
        case .memberChecklist:
            NotificationCenter.default.post(name: Self.showMemberChecklistNotifName, object: nil, userInfo: nil)
        }
    }
    
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
}
