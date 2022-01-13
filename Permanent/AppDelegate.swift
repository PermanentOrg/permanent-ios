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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        clearShareDeepLinks()
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootViewController()
        window?.makeKeyAndVisible()

        initFirebase()
        initNotifications()

        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        clearShareDeepLinks()
        
        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL,
            url.pathComponents.count > 1,
            url.pathComponents[1] == "share"  else {
            return false
        }
        
        if rootViewController.isDrawerRootActive {
            return navigateFromUniversalLink(url: url)
        } else {
            saveUnivesalLinkToken(url.lastPathComponent)
            return false
        }
        
    }

    fileprivate func initFirebase() {
        let firebaseOpts = FirebaseOptions(googleAppID: googleServiceInfo.googleAppId, gcmSenderID: googleServiceInfo.gcmSenderId)
        firebaseOpts.clientID = googleServiceInfo.clientId
        firebaseOpts.apiKey = googleServiceInfo.apiKey
        firebaseOpts.projectID = googleServiceInfo.projectId
        firebaseOpts.storageBucket = googleServiceInfo.storageBucket

        FirebaseApp.configure(options: firebaseOpts)
        
        GMSServices.provideAPIKey(googleServiceInfo.apiKey)
        GMSPlacesClient.provideAPIKey(googleServiceInfo.apiKey)
    }
    
    fileprivate func initNotifications() {
        UNUserNotificationCenter.current().delegate = self
        
        let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
        UNUserNotificationCenter.current().requestAuthorization(
            options: authOptions,
            completionHandler: {_, _ in })
        
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
        return true
    }
    
    fileprivate func saveUnivesalLinkToken(_ token: String) {
        PreferencesManager.shared.set(token, forKey: Constants.Keys.StorageKeys.shareURLToken)
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
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String) {
        print("Saving push token: " + fcmToken)
        PreferencesManager.shared.set(fcmToken, forKey: Constants.Keys.StorageKeys.fcmPushTokenKey)
        
        if rootViewController.isDrawerRootActive {
            rootViewController.sendPushNotificationToken()
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Called when app is in the foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if #available(iOS 14.0, *) {
            completionHandler([.list, .banner])
        } else {
            completionHandler(.alert)
        }
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
            case "type.notification.sharelink.request","type.notification.share.invitation.acceptance":
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
            let toArchiveId: Int = Int(userInfo["toArchiveId"] as? String ?? "") else {
            return
        }
        
        if let name: String = userInfo["recordName"] as? String,
           let recordId: Int = Int(userInfo["recordId"] as? String ?? "") {
            DispatchQueue.main.async {
                let shareNotifPayload = ShareNotificationPayload(name: name, recordId: recordId, folderLinkId: folderLinkId, archiveNbr: archiveNbr, type: FileType.miscellaneous.rawValue, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName)
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
                let shareNotifPayload = ShareNotificationPayload(name: sharedFolderName, recordId: 0, folderLinkId: folderLinkId, archiveNbr: archiveNbr, type: FileType.miscellaneous.rawValue, toArchiveId: toArchiveId, toArchiveNbr: toArchiveNbr, toArchiveName: toArchiveName)
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
        PreferencesManager.shared.removeValues(forKeys: [
            Constants.Keys.StorageKeys.requestPAAccess,
            Constants.Keys.StorageKeys.sharedFolderKey,
            Constants.Keys.StorageKeys.sharedFileKey,
            Constants.Keys.StorageKeys.requestLinkAccess,
            Constants.Keys.StorageKeys.shareURLToken])
    }
}
