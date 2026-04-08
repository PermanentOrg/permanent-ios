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
            // On iOS 26, CustomNavigationView resets the global UINavigationBar.appearance()
            // proxy to defaults when it disappears. Since NavigationController relied on that
            // proxy for its dark blue style, set the appearance at instance level here so it
            // is always correct regardless of the global proxy state.
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
        }
    }
}
