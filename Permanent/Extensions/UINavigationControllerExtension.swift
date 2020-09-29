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

    func display(_ viewController: ViewControllerIdentifier, from storyboard: StoryboardName, modally: Bool = false) {
        let viewController = self.createViewController(withIdentifier: viewController.identifier, from: storyboard.name)
        
        if modally {
            viewController.modalPresentationStyle = .overFullScreen
            self.present(viewController, animated: true)
        } else {
            self.pushViewController(viewController, animated: true)
        }
    }

    fileprivate func createViewController(withIdentifier id: String, from storyboard: String) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboard, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: id)
    }
}

extension UINavigationBar {
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 55)
    }
}
