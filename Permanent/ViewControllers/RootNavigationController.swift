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
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configureNavigationItems() {
        topViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.hamburger.templated, style: .plain, target: self, action: #selector(didTapDrawerMenuButton))
        topViewController?.navigationItem.leftBarButtonItem?.tintColor = .white
    }
    
    func changeRootController(viewController: UIViewController) {
        self.setViewControllers([viewController], animated: true)
        
        configureNavigationItems()
    }
}

extension RootNavigationController: DrawerMenuDelegate {
    @objc
    func didTapDrawerMenuButton() {
        drawerDelegate?.didTapDrawerMenuButton()
    }
}
