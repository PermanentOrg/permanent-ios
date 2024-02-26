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
}
