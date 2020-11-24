//  
//  DrawerViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24.11.2020.
//

import UIKit

protocol DrawerMenuDelegate: class {
    func didTapDrawerMenuButton()
}

class DrawerViewController: UIViewController {
    var rootViewController: RootNavigationController // UINavController?
    var sideMenuController: SideMenuViewController
    var isMenuExpanded: Bool = false
    let backgroundView = UIView()
    
    fileprivate var sideMenuOrigin: CGPoint { CGPoint(x: 0, y: view.safeAreaInsets.top + rootViewController.barHeight) }
    fileprivate var sideMenuHeight: CGFloat { view.bounds.height - sideMenuOrigin.y }
    
    init(rootViewController: RootNavigationController, sideMenuController: SideMenuViewController) {
        self.rootViewController = rootViewController
        self.sideMenuController = sideMenuController
        super.init(nibName: nil, bundle: nil)
        
        self.rootViewController.drawerDelegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        addChild(rootViewController)
        view.addSubview(rootViewController.view)
        rootViewController.didMove(toParent: self)
        
        backgroundView.backgroundColor = .clear
        backgroundView.alpha = 0
        view.addSubview(backgroundView)
                
        sideMenuController.view.frame = CGRect(
            origin: self.sideMenuOrigin,
            size: CGSize(width: 0, height: sideMenuHeight)
        )
        
        addChild(sideMenuController)
        view.addSubview(sideMenuController.view)
        sideMenuController.didMove(toParent: self)
        
        configureGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        backgroundView.frame = view.bounds
        // Verify why we need this
        let width: CGFloat = isMenuExpanded ? (view.bounds.width * 2 / 3) : 0
        
        sideMenuController.view.frame = CGRect(
            origin: self.sideMenuOrigin,
            size: CGSize(width: width, height: sideMenuHeight)
        )
    }
    
    func toggleMenu() {
        isMenuExpanded.toggle()
        
        let bounds = self.view.bounds
        let width: CGFloat = isMenuExpanded ? (bounds.width * 2 / 3) : 0
        
        UIView.animate(withDuration: 0.3, animations: {
            self.sideMenuController.view.frame = CGRect(
                origin: self.sideMenuOrigin,
                size: CGSize(width: width, height: self.sideMenuHeight)
            )
            self.backgroundView.alpha = (self.isMenuExpanded) ? 0.5 : 0.0
        })
    }
    
    fileprivate func configureGestures() {
      let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeLeft))
      swipeLeftGesture.direction = .left
      backgroundView.addGestureRecognizer(swipeLeftGesture)
      
      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOutside))
      backgroundView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    fileprivate func didSwipeLeft() {
      toggleMenu()
    }
    
    @objc
    fileprivate func didTapOutside() {
        toggleMenu()
    }
}

extension DrawerViewController: DrawerMenuDelegate {
    func didTapDrawerMenuButton() {
        toggleMenu()
    }
}
