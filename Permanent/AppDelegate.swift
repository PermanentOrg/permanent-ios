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
    let onboardingViewController = OnboardingViewController.init(nibName: "OnboardingViewController", bundle: .main)
    
    if Core.shared.isNewUser(){
      mainNavicationController.viewControllers = [onboardingViewController]
    } else {
      mainNavicationController.viewControllers = [loginViewController]
    }

    window?.rootViewController = mainNavicationController
    window?.makeKeyAndVisible()

    return true
  }

}

