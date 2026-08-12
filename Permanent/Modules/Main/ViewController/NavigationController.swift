//
//  NavigationController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 13/10/2020.
//

import UIKit

class NavigationController: UINavigationController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return viewControllers.last?.preferredStatusBarStyle ?? .default
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return Constants.Design.currentPlatform == .phone ? [.portrait] : [.landscape]
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        if #available(iOS 26.0, *) {
            // `CustomNavigationView` clears the global appearance proxy when it disappears, so set the
            // appearance per instance here and stay correct whatever the proxy holds.
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = UIColor.darkBlue
            appearance.titleTextAttributes = [
                .foregroundColor: UIColor.white,
                NSAttributedString.Key.font: TextFontStyle.style51.font
            ]
            navigationBar.standardAppearance = appearance
            navigationBar.compactAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.isTranslucent = false
            navigationBar.tintColor = .white
        }
    }
}
