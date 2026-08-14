//  
//  RootNavigationController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24.11.2020.
//

import UIKit
import SwiftUI

class RootNavigationController: UINavigationController {
    weak var drawerDelegate: DrawerMenuDelegate?
    
    var barHeight: CGFloat { self.navigationBar.frame.height }

    public init(viewController: UIViewController) {
        super.init(rootViewController: viewController)

        configureNavigationBarAppearance()
        configureNavigationItems()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Re-apply the instance appearance after every modal dismissal: `styleNavBar()` runs once, so a
        // SwiftUI view clearing the global proxy on disappear would otherwise strip the bar's colour.
        configureNavigationBarAppearance()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func configureNavigationBarAppearance() {
        if #available(iOS 26.0, *) {
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
    
    func configureNavigationItems() {
        if #available(iOS 26.0, *) {
            topViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.hamburger, style: .prominent, target: self, action: #selector(didTapDrawerMenuButton))
            topViewController?.navigationItem.leftBarButtonItem?.tintColor = .darkBlue
        } else {
            topViewController?.navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage.hamburger, style: .plain, target: self, action: #selector(didTapDrawerMenuButton))
        }
        
        if #available(iOS 26.0, *) {
            topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.settings.templated, style: .prominent, target: self, action: #selector(didTapRightSideMenuButton))
            topViewController?.navigationItem.rightBarButtonItem?.tintColor = .darkBlue
        } else {
            topViewController?.navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage.settings.templated, style: .plain, target: self, action: #selector(didTapRightSideMenuButton))
        }
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
    @objc
    func didTapRightSideMenuButton() {
        drawerDelegate?.didTapRightSideMenuButton()
    }
}
