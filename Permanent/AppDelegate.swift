//
//  AppDelegate.swift
//  Permanent
//
//  Created by Lucian Cerbu on 04/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        window = UIWindow(frame: UIScreen.main.bounds)
        let mainNavicationController = UINavigationController()
        let loginViewController = LoginViewController.init(nibName: "LoginViewController", bundle: .main)
        
        if UserDefaultsService.shared.isNewUser(){
            
            let onboardingView = UIStoryboard(name: "Onboarding", bundle: .main).instantiateViewController(withIdentifier: "Onboarding")
            
            mainNavicationController.viewControllers = [onboardingView]
        } else {
            mainNavicationController.viewControllers = [loginViewController]
            
        }
        window?.rootViewController = mainNavicationController
        window?.makeKeyAndVisible()
        
        return true
    }
    
}

