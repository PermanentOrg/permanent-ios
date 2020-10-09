//
//  AppDelegate.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04/08/2020.
//

import Firebase
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
