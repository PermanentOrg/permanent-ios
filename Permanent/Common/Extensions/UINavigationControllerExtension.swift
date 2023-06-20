//
//  UINavigationControllerExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import UIKit.UINavigationController

extension UINavigationController {
    
    func display(viewController: UIViewController, modally: Bool = false) {
        if modally {
            viewController.modalPresentationStyle = .popover
            self.present(viewController, animated: true)
        } else {
            self.pushViewController(viewController, animated: true)
        }
    }

    func display(_ id: ViewControllerId, from storyboard: StoryboardName, modally: Bool = false) {
        let viewController = UIViewController.create(withIdentifier: id, from: storyboard)
        self.display(viewController: viewController, modally: modally)
    }
}

extension UINavigationBar {
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 55)
    }
}
