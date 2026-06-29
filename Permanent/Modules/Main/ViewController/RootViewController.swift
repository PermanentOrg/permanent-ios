//
//  RootViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25/09/2020.
//

import UIKit
import SwiftUI
import FirebaseMessaging
import FirebaseRemoteConfig

class RootViewController: UIViewController {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait]
        } else {
            return [.landscape]
        }
    }
    
    var current: UIViewController?
    var sessionExpiredObserver: NSObjectProtocol?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    deinit {
        guard let sessionExpiredObserver = sessionExpiredObserver else {
            return
        }

        NotificationCenter.default.removeObserver(sessionExpiredObserver, name: nil, object: nil)
    }
    
    override func viewDidLoad() {
        let dispatchGroup = DispatchGroup()
        super.viewDidLoad()
        
        let updateAppVC = UIViewController.create(withIdentifier: .loadingScreen, from: .main) as! LoadingScreenViewController
        
        let navController = NavigationController()
        navController.viewControllers = [updateAppVC]
        
        current = navController
        setupChild(current)
        
        dispatchGroup.enter()
        RCValues.fetchCloudValues { result in
            if result {
                RCValues.verifyAppVersion()
            }
            dispatchGroup.leave()
        }
        
        dispatchGroup.notify(queue: .main) { [weak self] in
            if RCValues.appNeedUpdate {
                let updateAppVC = UIViewController.create(withIdentifier: .updateApp, from: .main) as! UpdateNecessaryViewController
                
                let navController = NavigationController()
                navController.viewControllers = [updateAppVC]
                
                self?.current = navController
                self?.setupChild(self?.current)
                return
            }
            
            AuthenticationManager.shared.reloadSession { success in
                let discardSession: Bool = CommandLine.arguments.contains("--DiscardSession")
                if success && !discardSession {
                    let authStatus = PermanentLocalAuthentication.instance.canAuthenticate()
                    let biometricsAuthEnabled: Bool = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.biometricsAuthEnabled) ?? true
                    
                    if authStatus.error?.statusCode == LocalAuthErrors.localHardwareUnavailableError.statusCode || !biometricsAuthEnabled {
                        // DASHBOARD_REDESIGN: a logged-in user with no default archive
                        // (relaunch, biometrics off/unavailable) goes to the redesigned
                        // onboarding dashboard — not the empty file manager.
                        if AuthenticationManager.shared.session?.account.defaultArchiveID == nil && DashboardRedesign.isEnabled {
                            let host = RedesignOnboardingEntry.makeDashboardHost()
                            AppDelegate.shared.rootViewController.present(host, animated: true)
                        } else {
                            self?.setDrawerRoot()
                        }
                    } else {
                        self?.setRoot(named: .biometrics, from: .authentication)
                    }
                } else {
                    let skipOnboarding: Bool = CommandLine.arguments.contains("--SkipOnboarding")
                    let route: (ViewControllerId, StoryboardName) = (.signUp, .authentication)
                    
                    if skipOnboarding {
                        AuthenticationManager.shared.logout()
                    }
                    
                    let navController = NavigationController()
                    let viewController = UIViewController.create(withIdentifier: route.0, from: route.1)
                    navController.viewControllers = [viewController]
                    
                    self?.current = navController
                    self?.setupChild(self?.current)
                }
            }
            
            self?.sessionExpiredObserver = NotificationCenter.default.addObserver(forName: APIRequestDispatcher.sessionExpiredNotificationName, object: nil, queue: nil) { [weak self] notification in
                guard self?.current is AuthenticationViewController == false else { return }
                
                self?.dismiss(animated: false) {
                    self?.setRoot(named: .signUp, from: .authentication)
                    
                    let alert = UIAlertController(title: "Session expired".localized(), message: "Your session has expired, please login again.".localized(), preferredStyle: .alert)
                    alert.addAction(UIAlertAction(title: "OK".localized(), style: .default, handler: nil))
                    self?.present(alert, animated: true, completion: nil)
                }
            }
        }
    }
    
    var isDrawerRootActive: Bool {
        return current is DrawerViewController
    }
    
    func navigateTo(viewController: UIViewController) {
        (current as? DrawerViewController)?.navigateTo(viewController: viewController)
    }
    
    func changeDrawerRoot(viewController: UIViewController) {
        (current as? DrawerViewController)?.changeRoot(viewController: viewController)
    }
    
    func setDrawerRoot() {
        sendPushNotificationToken()
        
        let drawerController = drawerControllerForDeepLink()
        
        // Move these 3 lines to a method
        setupChild(drawerController)
        removeChild(current)
        current = drawerController
        
        UploadManager.shared.refreshQueue()
    }
    
    func drawerControllerForDeepLink() -> DrawerViewController {
        var showArchives: Bool = false
        let mainViewController: UIViewController
        let leftSideMenuController = UIViewController.create(withIdentifier: .sideMenu, from: .main) as! SideMenuViewController

        // Redesign deep-link routing: instead of using `mainViewController` as the
        // drawer root (which the shell host replaces), route the intent INTO the
        // shell — shares open the Files tab's Shared section; PA-request /
        // public-profile present over the shell so the shell survives.
        var deepLinkSharedSection = false
        var deepLinkPresentVC: UIViewController?

        if let _: PARequestNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.requestPAAccess) {
            mainViewController = UIViewController.create(withIdentifier: .members, from: .members)

            leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![1]
            deepLinkPresentVC = mainViewController
        } else if let _: ShareNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.sharedFileKey) {
            let sharesVC: SharesViewController

            sharesVC = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
            sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue

            leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![0]

            mainViewController = sharesVC
            deepLinkSharedSection = true
        } else if let _: ShareNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.sharedFolderKey) {
            let sharesVC: SharesViewController

            sharesVC = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
            sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue

            leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![0]
            mainViewController = sharesVC
            deepLinkSharedSection = true
        } else if let deeplinkPayload: PublicProfileDeeplinkPayload = try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.publicURLToken) {
            let newRootVC = UIViewController.create(withIdentifier: .publicGallery, from: .main) as! PublicGalleryViewController
            newRootVC.deeplinkPayload = deeplinkPayload
            // Legacy swaps the drawer root; the shell instead presents it over the
            // shell (see deepLinkPresentVC below).
            if !DashboardRedesign.isEnabled {
                AppDelegate.shared.rootViewController.changeDrawerRoot(viewController: newRootVC)
            }

            leftSideMenuController.selectedMenuOption = .publicGallery

            mainViewController = newRootVC
            deepLinkPresentVC = newRootVC
        } else if let sharedArchiveToken: Bool = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.sharedArchiveToken), sharedArchiveToken {
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.sharedArchiveToken)
            showArchives = true
            
            mainViewController = UIViewController.create(withIdentifier: .main, from: .main)
            (mainViewController as! MainViewController).viewModel = MyFilesViewModel()
        } else {
            mainViewController = UIViewController.create(withIdentifier: .main, from: .main)
            (mainViewController as! MainViewController).viewModel = MyFilesViewModel()
        }
        
        let navController: RootNavigationController
        var shellCoordinator: RedesignShellCoordinator?
        if DashboardRedesign.isEnabled {
            // Stage 6 SwiftUI shell: host the Dashboard ↔ Files container.
            // The inner Files nav (RootNavigationController inside the shell)
            // provides its own bar, so the outer one is hidden. The coordinator
            // lets the drawer switch the shell's Files section in place instead
            // of swapping the root out from under it.
            let coordinator = RedesignShellCoordinator()
            // Deep link to a shared file/folder → open the Files tab's Shared section.
            if deepLinkSharedSection { coordinator.filesSection = .shared }
            shellCoordinator = coordinator
            navController = RootNavigationController(viewController: RedesignAppShellEntry.makeShellHost(coordinator: coordinator))
            navController.setNavigationBarHidden(true, animated: false)
        } else {
            navController = RootNavigationController(viewController: mainViewController)
        }
        let drawerController = DrawerViewController(rootViewController: navController, leftSideMenuController: leftSideMenuController, showArchives: showArchives)
        drawerController.shellCoordinator = shellCoordinator
        // Deep link to PA-request / public-profile → present over the shell once
        // the drawer is on screen (so the shell isn't torn down).
        if DashboardRedesign.isEnabled, let presentVC = deepLinkPresentVC {
            drawerController.pendingDeepLinkViewController = presentVC
        }
        return drawerController
    }
    
    func setRoot(named controller: ViewControllerId, from storyboard: StoryboardName, showRegisterView: Bool = false) {
        let navController = NavigationController()
        var viewController = UIViewController.create(withIdentifier: controller, from: storyboard)
        
        if showRegisterView {
            let signupController = viewController as! AuthenticationViewController
            signupController.showRegisterView = true
            viewController = signupController
        }
        
        navController.viewControllers = [viewController]
        
        setupChild(navController)
        removeChild(current)
        current = navController
    }
    
    func presentFullscreen() {
        
    }
    
    fileprivate func setupChild(_ viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }
        
        addChild(viewController)
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }
    
    fileprivate func removeChild(_ viewController: UIViewController?) {
        guard let viewController = viewController else {
            return
        }
        
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    func sendPushNotificationToken() {
        Messaging.messaging().retrieveFCMToken(forSenderID: googleServiceInfo.gcmSenderId, completion: { token, error in
            guard let token: String = token else { return }
            
            let newDeviceParams = NewDeviceParams(token)
            let apiOperation = APIOperation(DeviceEndpoint.new(params: newDeviceParams))
            
            apiOperation.execute(in: APIRequestDispatcher()) { result in }
        })
    }
}
