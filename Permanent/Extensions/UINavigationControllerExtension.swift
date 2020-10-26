//
//  UINavigationControllerExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import UIKit.UINavigationController

extension UINavigationController {
    func navigate(to vcIdentifier: ViewControllerIdentifier, from storyboard: StoryboardName) {
        let storyboard = UIStoryboard(name: storyboard.name, bundle: nil)
        let vc = storyboard.instantiateViewController(withIdentifier: vcIdentifier.identifier)

        self.pushViewController(vc, animated: true)
    }
    
    func navigate(to viewController: UIViewController) {
        self.pushViewController(viewController, animated: true)
    }
    
    func display(viewController: UIViewController) {
        viewController.modalPresentationStyle = .overCurrentContext
        self.present(viewController, animated: true)
    }

    func display(_ viewController: ViewControllerIdentifier, from storyboard: StoryboardName, modally: Bool = false) {
        let viewController = self.create(viewController: viewController, from: storyboard)
        
        if modally {
            viewController.modalPresentationStyle = .overFullScreen
            self.present(viewController, animated: true)
        } else {
            self.pushViewController(viewController, animated: true)
        }
    }

    func create(viewController: ViewControllerIdentifier, from storyboard: StoryboardName) -> UIViewController {
        let storyboard = UIStoryboard(name: storyboard.name, bundle: nil)
        return storyboard.instantiateViewController(withIdentifier: viewController.identifier)
    }
}

extension UINavigationBar {
    override open func sizeThatFits(_ size: CGSize) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 55)
    }
}
