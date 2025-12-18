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

        configureNavigationBar()
        configureNavigationItems()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        configureNavigationBar()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Reposition buttons after layout to ensure correct positioning
        updateButtonPositions()
    }
    
    func configureNavigationBar() {
        // Configure navigation bar for consistent appearance across iOS versions
        navigationBar.isTranslucent = false
        navigationBar.barTintColor = .barneyPurple
        navigationBar.tintColor = .white
        navigationBar.titleTextAttributes = [.foregroundColor: UIColor.white]
        
        // Prevent iOS 26 from applying automatic glass effects
        if #available(iOS 15.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.configureWithOpaqueBackground()
            appearance.backgroundColor = .barneyPurple
            appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
            appearance.shadowColor = .clear
            
            navigationBar.standardAppearance = appearance
            navigationBar.scrollEdgeAppearance = appearance
            navigationBar.compactAppearance = appearance
        }
        
        // Configure title label to truncate properly
        if let titleLabel = navigationBar.subviews.first(where: { $0 is UILabel }) as? UILabel {
            titleLabel.lineBreakMode = .byTruncatingTail
        }
    }
    
    func configureNavigationItems() {
        // Clear any existing bar button items
        topViewController?.navigationItem.leftBarButtonItem = nil
        topViewController?.navigationItem.rightBarButtonItem = nil
        topViewController?.navigationItem.rightBarButtonItems = nil
        
        // Remove any existing custom buttons
        navigationBar.subviews.filter { $0.tag == 9999 || $0.tag == 9998 || $0.tag == 9997 }.forEach { $0.removeFromSuperview() }
        
        // Only show search button in MainViewController
        let shouldShowSearch = topViewController is MainViewController
        
        // Add plain buttons directly to navigation bar to bypass iOS 26 Liquid Glass
        // Use standard navigation bar height (44pt) for positioning
        let navBarHeight: CGFloat = 44
        let buttonSize: CGFloat = 32
        
        let leftButton = UIButton(type: .custom)
        leftButton.setImage(UIImage.hamburger.templated?.withRenderingMode(.alwaysTemplate), for: .normal)
        leftButton.tintColor = .white
        leftButton.frame = CGRect(x: 12, y: (navBarHeight - buttonSize) / 2, width: buttonSize, height: buttonSize)
        leftButton.addTarget(self, action: #selector(didTapDrawerMenuButton), for: .touchUpInside)
        leftButton.tag = 9999
        leftButton.autoresizingMask = [.flexibleTopMargin, .flexibleBottomMargin]
        leftButton.clipsToBounds = true
        navigationBar.addSubview(leftButton)
        
        if shouldShowSearch {
            // Search button (second from right) - only for MainViewController
            let searchButton = UIButton(type: .custom)
            searchButton.setImage(UIImage(systemName: "magnifyingglass")?.withRenderingMode(.alwaysTemplate), for: .normal)
            searchButton.tintColor = .white
            searchButton.frame = CGRect(x: navigationBar.frame.width - 100, y: (navBarHeight - buttonSize) / 2, width: buttonSize, height: buttonSize)
            searchButton.addTarget(self, action: #selector(didTapSearchButton), for: .touchUpInside)
            searchButton.tag = 9997
            searchButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
            searchButton.clipsToBounds = true
            navigationBar.addSubview(searchButton)
        }
        
        // Settings button (rightmost)
        let rightButton = UIButton(type: .custom)
        rightButton.setImage(UIImage.settings.templated?.withRenderingMode(.alwaysTemplate), for: .normal)
        rightButton.tintColor = .white
        rightButton.frame = CGRect(x: navigationBar.frame.width - 52, y: (navBarHeight - buttonSize) / 2, width: buttonSize, height: buttonSize)
        rightButton.addTarget(self, action: #selector(didTapRightSideMenuButton), for: .touchUpInside)
        rightButton.tag = 9998
        rightButton.autoresizingMask = [.flexibleLeftMargin, .flexibleTopMargin, .flexibleBottomMargin]
        rightButton.clipsToBounds = true
        navigationBar.addSubview(rightButton)
        
        // Reserve space for buttons using layout margins so title knows where buttons are
        let leftMargin: CGFloat = 56  // 12 (button x) + 32 (button width) + 12 (padding)
        let rightMargin: CGFloat = shouldShowSearch ? 116 : 68  // Space for settings + search or just settings
        
        navigationBar.layoutMargins = UIEdgeInsets(top: 0, left: leftMargin, bottom: 0, right: rightMargin)
        
        // Force navigation bar to update layout with new margins
        navigationBar.setNeedsLayout()
        navigationBar.layoutIfNeeded()
    }
    
    func updateButtonPositions() {
        let navBarHeight: CGFloat = 44
        let buttonSize: CGFloat = 32
        let shouldShowSearch = topViewController is MainViewController
        
        // Update left button position
        if let leftButton = navigationBar.viewWithTag(9999) as? UIButton {
            leftButton.frame.origin.y = (navBarHeight - buttonSize) / 2
        }
        
        // Update search button position
        if shouldShowSearch, let searchButton = navigationBar.viewWithTag(9997) as? UIButton {
            searchButton.frame.origin.x = navigationBar.frame.width - 100
            searchButton.frame.origin.y = (navBarHeight - buttonSize) / 2
        }
        
        // Update right button position
        if let rightButton = navigationBar.viewWithTag(9998) as? UIButton {
            rightButton.frame.origin.x = navigationBar.frame.width - 52
            rightButton.frame.origin.y = (navBarHeight - buttonSize) / 2
        }
    }
    
    @objc func didTapSearchButton() {
        // Forward search action to the MainViewController if it exists
        if let mainVC = topViewController as? MainViewController {
            mainVC.searchButtonPressed(self)
        }
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
