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
        
        UploadManager.shared.refreshQueue()
    }
    
    func drawerControllerForDeepLink() -> DrawerViewController {
        let mainViewController: UIViewController
        let sideMenuController = UIViewController.create(withIdentifier: .sideMenu, from: .main) as! SideMenuViewController
        
        if let requestPAAccess: Bool = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.requestPAAccess),
           requestPAAccess == true {
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.requestPAAccess)
            mainViewController = UIViewController.create(withIdentifier: .members, from: .members)
            
            sideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.others]![0]
        } else if let sharedFile: ShareNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.sharedFileKey) {
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.sharedFileKey)
            let sharesVC: SharesViewController
            
            sharesVC = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
            sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
            
            sideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.files]![1]
            
            let fileVM = FileViewModel(name: sharedFile.name, recordId: sharedFile.recordId, folderLinkId: sharedFile.folderLinkId, archiveNbr: sharedFile.archiveNbr, type: sharedFile.type)
            let filePreviewVC = UIViewController.create(withIdentifier: .filePreview, from: .main) as! FilePreviewViewController
            filePreviewVC.file = fileVM
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                let fileDetailsNavigationController = FilePreviewNavigationController(rootViewController: filePreviewVC)
                fileDetailsNavigationController.filePreviewNavDelegate = sharesVC
                fileDetailsNavigationController.modalPresentationStyle = .fullScreen
                sharesVC.present(fileDetailsNavigationController, animated: true)
            }
            
            mainViewController = sharesVC
        } else if let sharedFolder: ShareNotificationPayload = try? PreferencesManager.shared.getNonPlistObject(forKey: Constants.Keys.StorageKeys.sharedFolderKey) {
            PreferencesManager.shared.removeValue(forKey: Constants.Keys.StorageKeys.sharedFolderKey)
            let sharesVC: SharesViewController
            
            sharesVC = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
            sharesVC.initialNavigationParams = (archiveNo: sharedFolder.archiveNbr, folderLinkId: sharedFolder.folderLinkId, folderName: sharedFolder.name)
            sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
            
            sideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.files]![1]
            
            mainViewController = sharesVC
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
        guard let token: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.fcmPushTokenKey)
        else { return }
        
        let newDeviceParams = NewDeviceParams(token)
        let apiOperation = APIOperation(DeviceEndpoint.new(params: newDeviceParams))
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            
        }
    }
}
