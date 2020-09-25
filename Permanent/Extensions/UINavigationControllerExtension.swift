//
//  UINavigationControllerExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import UIKit.UINavigationController

extension UINavigationController {
    func navigate(to vcIdentifier: ViewControllerIdentifier, from storyboard: StoryboardName) {
        let storyboard = UIStoryboard(name: storyboard.name, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: vcIdentifier.identifier)
        self.pushViewController(vc, animated: true)
    }
}

extension UINavigationBar {
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 55)
    }
}
