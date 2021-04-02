//
//  AppDelegate.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04/08/2020.
//

import Firebase
import FirebaseMessaging
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = RootViewController()
        window?.makeKeyAndVisible()

        initFirebase()

        return true
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        
        guard
            userActivity.activityType == NSUserActivityTypeBrowsingWeb,
            let url = userActivity.webpageURL else {
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
        guard
            let infoDict = Bundle.main.infoDictionary,
            let fileName = infoDict["GOOGLE_PLIST_NAME"] as? String,
            let filePath = Bundle.main.path(forResource: fileName, ofType: "plist"),
            let fileOpts = FirebaseOptions(contentsOfFile: filePath)
        else {
            assert(false, "Cannot load config file")
            return
        }

        FirebaseApp.configure(options: fileOpts)
        
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
        
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    
}
