//
//  RootViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25/09/2020.
//

import UIKit

class RootViewController: UIViewController {
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return [.portrait]
        } else {
            return [.all]
        }
    }
    
    var current: UIViewController
    
    init() {
        self.current = SplashViewController()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.current = SplashViewController()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChild(current)
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
    }
    
    func drawerControllerForDeepLink() -> DrawerViewController {
        let mainViewController: UIViewController
        let sideMenuController = UIViewController.create(withIdentifier: .sideMenu, from: .main) as! SideMenuViewController
        
        if let requestPAAccess: Bool = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.requestPAAccess),
           requestPAAccess == true {
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.requestPAAccess)
            mainViewController = UIViewController.create(withIdentifier: .members, from: .members)
            
            sideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.others]![0]
        } else {
            mainViewController = UIViewController.create(withIdentifier: .main, from: .main)
        }
        
        let navController = RootNavigationController(viewController: mainViewController)
        return DrawerViewController(rootViewController: navController, sideMenuController: sideMenuController)
    }
    
    func setRoot(named controller: ViewControllerId, from storyboard: StoryboardName) {
        let navController = NavigationController()
        let viewController = UIViewController.create(withIdentifier: controller, from: storyboard)
        
        navController.viewControllers = [viewController]
        
        setupChild(navController)
        removeChild(current)
        current = navController
    }
    
    fileprivate func setupChild(_ viewController: UIViewController) {
        addChild(viewController)
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }
    
    fileprivate func removeChild(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
    
    func sendPushNotificationToken() {
        guard let token: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.fcmPushTokenKey),
              let csrf: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.csrfStorageKey)
        else { return }
        
        let newDeviceParams = NewDeviceParams(token: token, csrf: csrf)
        let apiOperation = APIOperation(DeviceEndpoint.new(params: newDeviceParams))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in

        }
    }
}
