//  
//  DrawerViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24.11.2020.
//

import UIKit

protocol DrawerMenuDelegate: AnyObject {
    func didTapDrawerMenuButton()
    func didTapRightSideMenuButton()
}

class DrawerViewController: UIViewController {
    var rootViewController: RootNavigationController
    var leftSideMenuController: UIViewController
    var rightSideMenuController: UIViewController
    var isLeftMenuExpanded: Bool = false
    var isRightMenuExpanded: Bool = false
    let backgroundView = UIView()
    
    fileprivate var leftSideMenuOrigin: CGPoint { CGPoint(x: 0, y: view.safeAreaInsets.top + rootViewController.barHeight + 0.5) }
    fileprivate var rightSideMenuOrigin: CGPoint { CGPoint(x: view.bounds.width - (view.bounds.width * 2 / 3), y: view.safeAreaInsets.top + rootViewController.barHeight + 0.5) }
    fileprivate var leftSideMenuHeight: CGFloat { view.bounds.height - leftSideMenuOrigin.y }
    fileprivate var rightSideMenuHeight: CGFloat { view.bounds.height - rightSideMenuOrigin.y }
    
    init(rootViewController: RootNavigationController, leftSideMenuController: UIViewController, rightSideMenuController: UIViewController) {
        self.rootViewController = rootViewController
        self.leftSideMenuController = leftSideMenuController
        self.rightSideMenuController = rightSideMenuController
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
        //view.addSubview(backgroundView)
                
        leftSideMenuController.view.frame = CGRect(
            origin: self.leftSideMenuOrigin,
            size: CGSize(width: 0, height: leftSideMenuHeight)
        )
        
        rightSideMenuController.view.frame = CGRect(
            origin: self.rightSideMenuOrigin,
            size: CGSize(width: 0, height: rightSideMenuHeight)
        )

        addChild(leftSideMenuController)
        addChild(rightSideMenuController)
        view.addSubview(leftSideMenuController.view)
        view.addSubview(rightSideMenuController.view)
        leftSideMenuController.didMove(toParent: self)
        rightSideMenuController.didMove(toParent: self)
        
        //configureGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        backgroundView.frame = view.bounds
        
        let leftWidth: CGFloat = isLeftMenuExpanded ? (view.bounds.width * 2 / 3) : 0
        let rightWidth: CGFloat = isRightMenuExpanded ? (view.bounds.width * 2 / 3) : 0
            
        leftSideMenuController.view.frame = CGRect(
            origin: self.leftSideMenuOrigin,
            size: CGSize(width: leftWidth, height: leftSideMenuHeight)
        )
        
        rightSideMenuController.view.frame = CGRect(
            origin: self.rightSideMenuOrigin,
            size: CGSize(width: rightWidth, height: rightSideMenuHeight)
        )
    }
    
    func toggleMenu() {
        isLeftMenuExpanded.toggle()
        rootViewController.view.hideKeyboard()
        
        let width: CGFloat = isLeftMenuExpanded ? (view.bounds.width * 2 / 3) : 0
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.leftSideMenuController.view.frame = CGRect(
                origin: self.leftSideMenuOrigin,
                size: CGSize(width: width, height: self.leftSideMenuHeight)
            )
            
            self.leftSideMenuController.view.layoutIfNeeded()
            self.backgroundView.alpha = (self.isLeftMenuExpanded) ? 0.5 : 0.0
            
            (self.leftSideMenuController as? SideMenuViewController)?.adjustUIForAnimation(isOpening: self.isLeftMenuExpanded)
            
        }, completion: nil)
    }
    
    func toggleRightSideMenu() {
        
        isRightMenuExpanded.toggle()
        rootViewController.view.hideKeyboard()
        
        let width: CGFloat = view.bounds.width * 2 / 3
        
        self.rightSideMenuController.view.frame = CGRect(
            origin: isRightMenuExpanded ? CGPoint(x: view.bounds.width, y: self.rightSideMenuOrigin.y) : self.rightSideMenuOrigin,
            size: CGSize(width: width, height: self.rightSideMenuHeight)
            )
        self.rightSideMenuController.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: {
            self.rightSideMenuController.view.frame = CGRect(
                origin: self.isRightMenuExpanded ? self.rightSideMenuOrigin : CGPoint(x: self.view.bounds.width, y: self.rightSideMenuOrigin.y),
                size: CGSize(width: width, height: self.rightSideMenuHeight)
            )
            
            self.rightSideMenuController.view.layoutIfNeeded()
            self.backgroundView.alpha = (self.isRightMenuExpanded) ? 0.5 : 0.0
            
            (self.rightSideMenuController as? RightSideMenuViewController)?.adjustUIForAnimation(isOpening: self.isRightMenuExpanded)
            
        }, completion: nil)
        
    }

    func navigateTo(viewController: UIViewController) {
        rootViewController.display(viewController: viewController)
    }
    
    func changeRoot(viewController: UIViewController) {
        rootViewController.changeRootController(viewController: viewController)
        
        if isLeftMenuExpanded {
            toggleMenu()
        }
        
    }
    
//    fileprivate func configureGestures() {
//      let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeLeft))
//      swipeLeftGesture.direction = .left
//      backgroundView.addGestureRecognizer(swipeLeftGesture)
//
//      let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOutside))
//      //backgroundView.addGestureRecognizer(tapGesture)
//    }
//
//    @objc
//    fileprivate func didSwipeLeft() {
//    //  toggleMenu()
//    }
//
//    @objc
//    fileprivate func didTapOutside() {
//     // toggleMenu()
//    }
}

extension DrawerViewController: DrawerMenuDelegate {
    func didTapDrawerMenuButton() {
        if isRightMenuExpanded {
            toggleRightSideMenu()
        }
        toggleMenu()
    }
    func didTapRightSideMenuButton() {
        if isLeftMenuExpanded {
            toggleMenu()
        }
        toggleRightSideMenu()
    }
}
