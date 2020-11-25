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

        topViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.profile.original, style: .plain, target: self, action: #selector(didTapDrawerMenuButton))
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension RootNavigationController: DrawerMenuDelegate {
    @objc
    func didTapDrawerMenuButton() {
        drawerDelegate?.didTapDrawerMenuButton()
    }
}
