//
//  NavigationController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 13/10/2020.
//

import UIKit

class NavigationController: UINavigationController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        
        let style = viewControllers.last?.preferredStatusBarStyle
        return viewControllers.last?.preferredStatusBarStyle ?? .default
    }
}
