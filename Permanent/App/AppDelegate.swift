//
//  AppDelegate.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04/08/2020.
//

import Firebase
import FirebaseMessaging
import UIKit
import GooglePlaces
import GoogleMaps
import StripeApplePay
import SwiftUI
import KeychainSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    static let navigateToFolderNotifName = NSNotification.Name("AppDelegate.navigateToFolderNotifName")

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if CommandLine.arguments.contains("--AddTextClearButton") {
            UITextField.appearance().clearButtonMode = .always
        }
        
        clearShareDeepLinks()
        
        initFirebase()
        initNotifications()
        configureLogging()
        
        StripeAPI.defaultPublishableKey = stripeServiceInfo.publishableKey
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootViewController()
        window?.makeKeyAndVisible()

        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        clearShareDeepLinks()
        
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb, let url = userActivity.webpageURL, url.pathComponents.count > 1
        else {
            return false
        }
        
        switch url.pathComponents[1] {
        case "share":
            if url.absoluteString.contains("targetArchiveNbr")
            {
                let pathComponents = url.pathComponents
                let queryItems = URLComponents(string: url.absoluteString)?.queryItems
                
                let shareIdOpt = pathComponents.count > 3 ? pathComponents[3] : nil
                let folderLinkIdOpt = pathComponents.count > 4 ? pathComponents[4] : nil
                
                let targetArchiveNbrOpt = queryItems?.first(where: { $0.name == "targetArchiveNbr" })?.value
                
                guard let shareId: Int = Int(shareIdOpt ?? ""),
                      let folderLinkId: Int = Int(folderLinkIdOpt ?? "") else {
                    return true
                }
                
                // Add API request here
                let apiOperation = APIOperation(ShareEndpoint.getShareForPreview(shareId: shareId, folder_linkId: folderLinkId))
                apiOperation.execute(in: APIRequestDispatcher()) { [weak self] result in
                    switch result {
                    case .json(let response, _):
                        
                        guard let model: APIResults<ShareVO> = JSONHelper.decoding( from: response, with: APIResults<ShareVO>.decoder),
                              let data = model.results.first?.data,
                              let shareVO = data.first?.shareVO
                        else {
                            return
                        }
                        guard
                            let toArchiveId: Int = shareVO.archiveID else {
                            return
                        }
                        let accessRole: String = AccessRole.roleForValue(shareVO.accessRole ?? "").groupName
                        let toArchiveNbr: String = targetArchiveNbrOpt ?? ""
                        let toArchiveName: String = ""

                        if let name: String = shareVO.recordVO?.displayName as? String,
                           let recordId: Int = shareVO.recordVO?.recordID {
                    DispatchQueue.main.async {
                        guard
                            let archiveNbrInt = shareVO.recordVO?.archiveID else {
                            return
                        }
                        let archiveNbr: String = String(archiveNbrInt)
                        
                        let shareNotifPayload = ShareNotificationPayload(name: name, recordId: recordId, folderLinkId: folderLinkId, archiveNbr: archiveNbr, type: FileType.miscellaneous.rawValue, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName, accessRole: accessRole)
                        try? PreferencesManager.shared.setNonPlistObject(shareNotifPayload, forKey: Constants.Keys.StorageKeys.sharedFileKey)
                        
                        if let drawerVC = self?.rootViewController.current as? DrawerViewController {
                            drawerVC.dismiss(animated: false) {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                    if let sharesVC = drawerVC.rootViewController.visibleViewController as? SharesViewController {
                                        sharesVC.segmentedControl.selectedSegmentIndex = 1
                                        sharesVC.segmentedControlValueChanged(sharesVC.segmentedControl)
                                        
                                        _ = sharesVC.checkSavedFile()
                                    } else {
                                        let sharesVC = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
                                        sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
                                        
                                        drawerVC.leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![0]
                                        
                                        self?.rootViewController.changeDrawerRoot(viewController: sharesVC)
                                    }
                                }
                            }
                        }
                    }
                } else if let sharedFolderName: String = shareVO.folderVO?.displayName as? String {
                    DispatchQueue.main.async {
                        guard
                            let archiveNbrInt = shareVO.folderVO?.archiveID else {
                            return
                        }
                        let archiveNbr: String = String(archiveNbrInt)
                        
                        let shareNotifPayload = ShareNotificationPayload(name: sharedFolderName, recordId: 0, folderLinkId: folderLinkId, archiveNbr: archiveNbr, type: FileType.miscellaneous.rawValue, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName, accessRole: accessRole)
                        try? PreferencesManager.shared.setNonPlistObject(shareNotifPayload, forKey: Constants.Keys.StorageKeys.sharedFolderKey)
                        
                        if let drawerVC = self?.rootViewController.current as? DrawerViewController {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                if drawerVC.rootViewController.visibleViewController is SharesViewController == false {
                                    let sharesVC: SharesViewController = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
                                    
                                    drawerVC.leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![0]
                                    
                                    self?.rootViewController.changeDrawerRoot(viewController: sharesVC)
                                } else {
                                    let sharesVC = drawerVC.rootViewController.visibleViewController as! SharesViewController
                                    sharesVC.segmentedControl.selectedSegmentIndex = 1
                                    sharesVC.segmentedControlValueChanged(sharesVC.segmentedControl)
                                    
                                    _ = sharesVC.checkSavedFolder()
                                }
                            }
                        }
                    }
                }
                        
                    case .error(let error, _):
                        break
                        
                    default:
                        break
                    }
                }
                return true
            } else {
                if rootViewController.isDrawerRootActive {
                    return navigateFromUniversalLink(url: url)
                } else {
                    saveUnivesalLinkToken(url.lastPathComponent)
                    return false
                }
            }
            
        case "p":
            let archiveNbr: String = url.pathComponents[3]
            
            var folderArchiveNbr: String?
            if url.pathComponents.count > 4 {
                folderArchiveNbr = url.pathComponents[4]
            }
            var folderLinkId: String?
            if url.pathComponents.count > 5 {
                folderLinkId = url.pathComponents[5]
            }
            
            let publicDeeplinkPayload: PublicProfileDeeplinkPayload

            if url.pathComponents.count >= 8 && url.pathComponents[6] == "record" {
                let fileArchiveNbr = url.pathComponents[7]

                publicDeeplinkPayload = PublicProfileDeeplinkPayload(archiveNbr: archiveNbr, folderArchiveNbr: folderArchiveNbr, folderLinkId: folderLinkId, fileArchiveNbr: fileArchiveNbr)
            } else {
                publicDeeplinkPayload = PublicProfileDeeplinkPayload(archiveNbr: archiveNbr, folderArchiveNbr: folderArchiveNbr, folderLinkId: folderLinkId, fileArchiveNbr: "")
            }
            
            if rootViewController.isDrawerRootActive {
                return navigateFromPublicLink(publicDeeplinkPayload)
            } else {
                savePublicLinkToken(publicDeeplinkPayload)
                return false
            }
            
        case "app":
            if let components = URLComponents(url: url, resolvingAgainstBaseURL: true)
            {
                if components.path == "/app/auth/signup",
                   let inviteCode = components.queryItems?.first(where: { $0.name == "inviteCode" })?.value {
                    
                    // Check if user is already logged in
                    if let authData = KeychainSwift().getData(SessionKeychainHandler.keychainAuthDataKey),
                       let session = try? JSONDecoder().decode(PermSession.self, from: authData),
                       let archiveId = session.selectedArchive?.archiveID,
                       archiveId != .zero {
                        
                        // User is logged in - show popup that they can't create an account
                        DispatchQueue.main.async {
                            self.showAlreadyLoggedInAlert()
                        }
                        return true
                    } else {
                        // User is not logged in - store invite code for later use during signup
                        InviteCodeManager.shared.storeInviteCode(inviteCode)
                        
                        // Always navigate to signup screen when we have an invite code and user is not logged in
                        DispatchQueue.main.async {
                            // If user was in main flow, logout first
                            if self.rootViewController.isDrawerRootActive {
                                AuthenticationManager.shared.logout()
                            }
                            // Navigate directly to signup screen
                            self.rootViewController.setRoot(named: .signUp, from: .authentication, showRegisterView: true)
                        }
                        return true
                    }
                }
                
                if let redeemCode = components.queryItems?.first(where: { $0.name == "promoCode" })?.value {
                    if let authData = KeychainSwift().getData(SessionKeychainHandler.keychainAuthDataKey),
                       let session = try? JSONDecoder().decode(PermSession.self, from: authData),
                       let archiveId = session.selectedArchive?.archiveID,
                       archiveId != .zero {
                        let storageViewModel = StateObject(wrappedValue: StorageViewModel(reddemCode: redeemCode))
                        let storageView = StorageView(viewModel: storageViewModel)
                        
                        let host = UIHostingController(rootView: storageView)
                        self.window?.rootViewController?.present(host, animated: true, completion: nil)
                        
                        return true
                    }
                }
                if components.path == "/app/pr/manage" {
                    if rootViewController.isDrawerRootActive {
                        return navigateFromSharedArchive()
                    } else {
                        saveSharedArchiveToken()
                        return false
                    }
                }
            }
            return false
            
        default: return false
        }
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey: Any] = [:]) -> Bool {
        // Sends the URL to the current authorization flow (if any) which will
        // process it if it relates to an authorization response.
        
        return false
    }

    fileprivate func initFirebase() {
        let firebaseOpts = FirebaseOptions(googleAppID: googleServiceInfo.googleAppId, gcmSenderID: googleServiceInfo.gcmSenderId)
        firebaseOpts.clientID = googleServiceInfo.clientId
        firebaseOpts.apiKey = googleServiceInfo.apiKey
        firebaseOpts.projectID = googleServiceInfo.projectId
        firebaseOpts.storageBucket = googleServiceInfo.storageBucket

        FirebaseApp.configure(options: firebaseOpts)
        _ = RCValues.sharedInstance
        
        GMSServices.provideAPIKey(googleServiceInfo.apiKey)
        GMSPlacesClient.provideAPIKey(googleServiceInfo.apiKey)
    }
    
    fileprivate func configureLogging() {
        #if STAGING_ENVIRONMENT
            NetworkLogger.configuration.logLevel = .debug
            NetworkLogger.configuration.environmentRestriction = nil // Log in all environments
            NetworkLogger.configuration.logBodies = true
            NetworkLogger.enableLogging()
        #else
             NetworkLogger.disableLogging()
        #endif
    }
    
    fileprivate func initNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in }
        )
        
        Messaging.messaging().delegate = self
        
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    fileprivate func navigateFromUniversalLink(url: URL) -> Bool {
        guard let sharePreviewVC = UIViewController.create(
            withIdentifier: .sharePreview,
            from: .share
        ) as? SharePreviewViewController else { return false }
        
        let viewModel = SharePreviewViewModel()
        viewModel.urlToken = url.lastPathComponent
        sharePreviewVC.viewModel = viewModel
        
        rootViewController.navigateTo(viewController: sharePreviewVC)
        
        sharePreviewVC.navigateTo = { [weak self] params in
            self?.navigateToFolder(params: params)
        }
        
        return true
    }
    
    fileprivate func navigateToFolder(params: NavigateMinParams) {
        if let drawerVC = self.rootViewController.current as? DrawerViewController {
            try? PreferencesManager.shared.setCodableObject(NavigationDataForShareFolderLink(archiveNo: params.archiveNo, folderLinkId: params.folderLinkId, folderName: params.folderName), forKey: Constants.Keys.StorageKeys.navigationToShareFolderLink)
            if let mainVC = drawerVC.rootViewController.visibleViewController as? MainViewController {
                mainVC.navigationToShareFolderLink()
            } else {
                self.rootViewController.setDrawerRoot()
            }
        }
    }
    
    fileprivate func saveUnivesalLinkToken(_ token: String) {
        PreferencesManager.shared.set(token, forKey: Constants.Keys.StorageKeys.shareURLToken)
    }
    
    fileprivate func navigateFromPublicLink(_ publicDeeplinkPayload: PublicProfileDeeplinkPayload) -> Bool {
        let newRootVC = UIViewController.create(withIdentifier: .publicArchive, from: .profile) as! PublicArchiveViewController
        newRootVC.deeplinkPayload = publicDeeplinkPayload
        let newNav = NavigationController(rootViewController: newRootVC)
        
        if let presentedVC = rootViewController.presentedViewController {
            presentedVC.dismiss(animated: false) {
                self.rootViewController.present(newNav, animated: true)
            }
        } else {
            rootViewController.present(newNav, animated: true)
        }
        
        return true
    }

    fileprivate func savePublicLinkToken(_ publicDeeplinkPayload: PublicProfileDeeplinkPayload) {
        try? PreferencesManager.shared.setCodableObject(publicDeeplinkPayload, forKey: Constants.Keys.StorageKeys.publicURLToken)
    }
    
    fileprivate func navigateFromSharedArchive() -> Bool {
        let screenView = ViewRepresentableContainer(viewRepresentable: ArchivesViewControllerRepresentable(), title: ArchivesViewControllerRepresentable().title)
        let host = UIHostingController(rootView: screenView)
        host.modalPresentationStyle = .fullScreen
        self.rootViewController.present(host, animated: true, completion: nil)

        return true
    }
    
    fileprivate func  saveSharedArchiveToken() {
        PreferencesManager.shared.set(true, forKey: Constants.Keys.StorageKeys.sharedArchiveToken)
    }
}

extension AppDelegate {
    static var shared: AppDelegate {
        return UIApplication.shared.delegate as! AppDelegate
    }

    // TODO: Maybe make these optional?
    var rootViewController: RootViewController {
        return window!.rootViewController as! RootViewController
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        if let fcmToken = fcmToken {
            print("Saving push token: " + fcmToken)
            PreferencesManager.shared.set(fcmToken, forKey: Constants.Keys.StorageKeys.fcmPushTokenKey)
            
            if rootViewController.isDrawerRootActive && AuthenticationManager.shared.session != nil {
                rootViewController.sendPushNotificationToken()
            }
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Called when app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.list, .banner])
    }

    // Called after the user interacts with the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        clearShareDeepLinks()
        
        guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else { return }
        
        let userInfo = response.notification.request.content.userInfo
        if let notificationType = userInfo["notificationType"] as? String {
            switch notificationType {
            case "type.notification.share":
                openShareNotification(response.notification)
                
            case "type.notification.pa_response_non_transfer":
                openPARequestNotification(response.notification)
                
            case "type.notification.sharelink.request", "type.notification.share.invitation.acceptance":
                openShareLinkRequestNotification(response.notification)
                
            default:
                break
            }
        }
        
        completionHandler()
    }
    
    func openShareLinkRequestNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        let name: String
        let folderLinkId: Int
        
        if let linkId: Int = Int(userInfo["shareFolderLinkId"] as? String ?? ""),
        let itemName = userInfo["shareName"] as? String {
            folderLinkId = linkId
            name = itemName
        } else if let linkId: Int = Int(userInfo["folderLinkId"] as? String ?? ""),
            let itemName = userInfo["folderName"] as? String {
            folderLinkId = linkId
            name = itemName
        } else if let linkId: Int = Int(userInfo["folderLinkId"] as? String ?? ""),
            let itemName = userInfo["recordName"] as? String {
                   folderLinkId = linkId
                   name = itemName
        } else {
            return
        }
        
        guard
            let toArchiveNbr: String = userInfo["toArchiveNumber"] as? String,
            let toArchiveName: String = userInfo["toArchiveName"] as? String,
            let toArchiveId: Int = Int(userInfo["toArchiveId"] as? String ?? "") else {
            return
        }
        
        DispatchQueue.main.async {
            let requestAccessNotifPayload = RequestLinkAccessNotificationPayload(name: name, folderLinkId: folderLinkId, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName)
            try? PreferencesManager.shared.setNonPlistObject(requestAccessNotifPayload, forKey: Constants.Keys.StorageKeys.requestLinkAccess)
            
            if let drawerVC = self.rootViewController.current as? DrawerViewController {
                drawerVC.dismiss(animated: false) {
                    if let mainVC = drawerVC.rootViewController.visibleViewController as? MainViewController {
                        mainVC.checkForRequestShareAccess()
                    } else {
                        let rootVC = UIViewController.create(withIdentifier: .main, from: .main) as! MainViewController
                        rootVC.viewModel = MyFilesViewModel()
                        self.rootViewController.changeDrawerRoot(viewController: rootVC)
                    }
                }
            }
        }
    }
    
    func openShareNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        guard
            let folderLinkId: Int = Int(userInfo["folderLinkId"] as? String ?? ""),
            let archiveNbr: String = userInfo["fromArchiveId"] as? String,
            let toArchiveNbr: String = userInfo["toArchiveNumber"] as? String,
            let toArchiveName: String = userInfo["toArchiveName"] as? String,
            let toArchiveId: Int = Int(userInfo["toArchiveId"] as? String ?? ""),
            let accessRole: String = userInfo["accessRole"] as? String else {
            return
        }
        
        if let name: String = userInfo["recordName"] as? String,
        let recordId: Int = Int(userInfo["recordId"] as? String ?? "") {
            DispatchQueue.main.async {
                let shareNotifPayload = ShareNotificationPayload(name: name, recordId: recordId, folderLinkId: folderLinkId, archiveNbr: archiveNbr, type: FileType.miscellaneous.rawValue, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName, accessRole: accessRole)
                try? PreferencesManager.shared.setNonPlistObject(shareNotifPayload, forKey: Constants.Keys.StorageKeys.sharedFileKey)
                
                if let drawerVC = self.rootViewController.current as? DrawerViewController {
                    drawerVC.dismiss(animated: false) {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                            if let sharesVC = drawerVC.rootViewController.visibleViewController as? SharesViewController {
                                sharesVC.segmentedControl.selectedSegmentIndex = 1
                                sharesVC.segmentedControlValueChanged(sharesVC.segmentedControl)
                                
                                _ = sharesVC.checkSavedFile()
                            } else {
                                let sharesVC = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
                                sharesVC.selectedIndex = ShareListType.sharedWithMe.rawValue
                                
                                drawerVC.leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![0]
                                
                                self.rootViewController.changeDrawerRoot(viewController: sharesVC)
                            }
                        }
                    }
                }
            }
        } else if let sharedFolderName: String = userInfo["folderName"] as? String {
            DispatchQueue.main.async {
                let shareNotifPayload = ShareNotificationPayload(name: sharedFolderName, recordId: 0, folderLinkId: folderLinkId, archiveNbr: archiveNbr, type: FileType.miscellaneous.rawValue, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName, accessRole: accessRole)
                try? PreferencesManager.shared.setNonPlistObject(shareNotifPayload, forKey: Constants.Keys.StorageKeys.sharedFolderKey)
                
                if let drawerVC = self.rootViewController.current as? DrawerViewController {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                        if drawerVC.rootViewController.visibleViewController is SharesViewController == false {
                            let sharesVC: SharesViewController = UIViewController.create(withIdentifier: .shares, from: .share) as! SharesViewController
                            
                            drawerVC.leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![0]
                            
                            self.rootViewController.changeDrawerRoot(viewController: sharesVC)
                        } else {
                            let sharesVC = drawerVC.rootViewController.visibleViewController as! SharesViewController
                            sharesVC.segmentedControl.selectedSegmentIndex = 1
                            sharesVC.segmentedControlValueChanged(sharesVC.segmentedControl)
                            
                            _ = sharesVC.checkSavedFolder()
                        }
                    }
                }
            }
        } else {
            return
        }
    }
    
    func openPARequestNotification(_ notification: UNNotification) {
        let userInfo = notification.request.content.userInfo
        
        guard
            let toArchiveNbr: String = userInfo["toArchiveNumber"] as? String,
            let toArchiveName: String = userInfo["toArchiveName"] as? String,
            let toArchiveId: Int = Int(userInfo["toArchiveId"] as? String ?? "") else {
            return
        }
        
        DispatchQueue.main.async {
            let notifPayload = PARequestNotificationPayload(toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName)
            try? PreferencesManager.shared.setNonPlistObject(notifPayload, forKey: Constants.Keys.StorageKeys.requestPAAccess)
            
            if let drawerVC = self.rootViewController.current as? DrawerViewController {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                    let rootVC: UIViewController
                    
                    rootVC = UIViewController.create(withIdentifier: .members, from: .members) as! MembersViewController
                    self.rootViewController.changeDrawerRoot(viewController: rootVC)
                    
                    drawerVC.leftSideMenuController.selectedMenuOption = TableViewData.drawerData[DrawerSection.navigationScreens]![1]
                }
            }
        }
    }
    
    func clearShareDeepLinks() {
        PreferencesManager.shared.removeValues(
            forKeys: [
            Constants.Keys.StorageKeys.requestPAAccess,
            Constants.Keys.StorageKeys.sharedFolderKey,
            Constants.Keys.StorageKeys.sharedFileKey,
            Constants.Keys.StorageKeys.requestLinkAccess,
            Constants.Keys.StorageKeys.shareURLToken,
            Constants.Keys.StorageKeys.publicURLToken,
            Constants.Keys.StorageKeys.sharedArchiveToken,
            Constants.Keys.StorageKeys.pendingInviteCode
            ]
        )
    }
    
    fileprivate func showAlreadyLoggedInAlert() {
        let alert = UIAlertController(
            title: "Already Signed In",
            message: "You are already signed in to Permanent. To create a new account with this invite code, please sign out first.",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        
        if let topViewController = getTopMostViewController() {
            topViewController.present(alert, animated: true, completion: nil)
        }
    }
    
    fileprivate func getTopMostViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return self.window?.rootViewController
        }
        
        var topViewController = window.rootViewController
        
        while let presentedViewController = topViewController?.presentedViewController {
            topViewController = presentedViewController
        }
        
        return topViewController
    }
}

extension AppDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return Constants.Design.orientationLock
    }
}
