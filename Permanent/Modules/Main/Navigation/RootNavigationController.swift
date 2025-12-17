//  
//  RootNavigationController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24.11.2020.
//

import UIKit

class RootNavigationController: UINavigationController {
    weak var drawerDelegate: DrawerMenuDelegate?
    
    var barHeight: CGFloat { self.navigationBar.frame.height }

    public init(viewController: UIViewController) {
        super.init(rootViewController: viewController)

        configureNavigationItems()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureNavigationItems() {
        topViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.hamburger.templated, style: .plain, target: self, action: #selector(didTapDrawerMenuButton))
        topViewController?.navigationItem.leftBarButtonItem?.tintColor = .white
        
        topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.settings.templated, style: .plain, target: self, action: #selector(didTapRightSideMenuButton))
        topViewController?.navigationItem.rightBarButtonItem?.tintColor = .white
    }
    
    func changeRootController(viewController: UIViewController, useTabTransition: Bool = false) {
        if useTabTransition {
            // Cross-dissolve (fade) for workspace switching - native tab feel
            let transition = CATransition()
            transition.duration = 0.25
            transition.type = .fade
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            self.view.layer.add(transition, forKey: kCATransition)
            self.setViewControllers([viewController], animated: false)
        } else {
            // Default navigation behavior for other transitions
            self.setViewControllers([viewController], animated: true)
        }
        
        configureNavigationItems()
    }
}

extension RootNavigationController: DrawerMenuDelegate {
    @objc
    func didTapDrawerMenuButton() {
        drawerDelegate?.didTapDrawerMenuButton()
    }
    @objc
    func didTapRightSideMenuButton() {
        drawerDelegate?.didTapRightSideMenuButton()
    }
}
