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
    var leftSideMenuController: SideMenuViewController
    var rightSideMenuController: RightSideMenuViewController
    var isLeftMenuExpanded: Bool = false
    var isRightMenuExpanded: Bool = false
    let backgroundView = UIView()
    
    fileprivate var leftSideMenuOrigin: CGPoint { CGPoint(x: 0, y: view.safeAreaInsets.top + rootViewController.barHeight + 0.5) }
    fileprivate var rightSideMenuOrigin: CGPoint { CGPoint(x: view.bounds.width - (view.bounds.width * 0.75), y: view.safeAreaInsets.top + rootViewController.barHeight + 0.5) }
    fileprivate var leftSideMenuHeight: CGFloat { view.bounds.height - leftSideMenuOrigin.y }
    fileprivate var rightSideMenuHeight: CGFloat { view.bounds.height - rightSideMenuOrigin.y }
    
    init(rootViewController: RootNavigationController, leftSideMenuController: SideMenuViewController, rightSideMenuController: RightSideMenuViewController) {
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
        
        backgroundView.backgroundColor = .darkGray
        backgroundView.alpha = 0
    
        configureGestures()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func toggleMenu(animateBg: Bool = true) {
        isLeftMenuExpanded.toggle()
        rootViewController.view.hideKeyboard()
        leftSideMenuController.refreshCurrentArchive()
        
        if leftSideMenuController.parent == nil {
            let bgViewOrigin = CGPoint(x: 0, y: view.safeAreaInsets.top + rootViewController.barHeight)
            backgroundView.frame = CGRect(origin: bgViewOrigin, size: CGSize(width: view.bounds.width, height: view.bounds.height - bgViewOrigin.y))
            view.addSubview(backgroundView)
            
            addChild(leftSideMenuController)
            view.addSubview(leftSideMenuController.view)
            leftSideMenuController.didMove(toParent: self)
        }
        
        leftSideMenuController.view.frame = CGRect(
            origin: CGPoint(x: isLeftMenuExpanded ? -(view.bounds.width * 0.75) : 0, y: leftSideMenuOrigin.y),
            size: CGSize(width: view.bounds.width * 0.75, height: leftSideMenuHeight)
        )
        leftSideMenuController.adjustUIForAnimation(isOpening: isLeftMenuExpanded)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: { [self] in
            leftSideMenuController.view.frame = CGRect(
                origin: CGPoint(x: isLeftMenuExpanded ? 0 : -(view.bounds.width * 0.75), y: leftSideMenuOrigin.y),
                size: CGSize(width: view.bounds.width * 0.75, height: leftSideMenuHeight)
            )
            
            if animateBg {
                backgroundView.alpha = (isLeftMenuExpanded) ? 0.5 : 0.0
            }
        }, completion: { [self] finished in
            if isLeftMenuExpanded == false {
                leftSideMenuController.removeFromParent()
                leftSideMenuController.view.removeFromSuperview()
                
                if animateBg {
                    backgroundView.removeFromSuperview()
                }
            }
        })
    }
    
    func toggleRightSideMenu(animateBg: Bool = true) {
        isRightMenuExpanded.toggle()
        rootViewController.view.hideKeyboard()
        
        if rightSideMenuController.parent == nil {
            let bgViewOrigin = CGPoint(x: 0, y: view.safeAreaInsets.top + rootViewController.barHeight)
            backgroundView.frame = CGRect(origin: bgViewOrigin, size: CGSize(width: view.bounds.width, height: view.bounds.height - bgViewOrigin.y))
            view.addSubview(backgroundView)
            
            addChild(rightSideMenuController)
            view.addSubview(rightSideMenuController.view)
            rightSideMenuController.didMove(toParent: self)
        }
        
        let width: CGFloat = view.bounds.width * 0.75
        
        rightSideMenuController.view.frame = CGRect(
            origin: isRightMenuExpanded ? CGPoint(x: view.bounds.width, y: rightSideMenuOrigin.y) : rightSideMenuOrigin,
            size: CGSize(width: width, height: rightSideMenuHeight)
            )
        
        rightSideMenuController.adjustUIForAnimation(isOpening: isRightMenuExpanded)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: { [self] in
            rightSideMenuController.view.frame = CGRect(
                origin: isRightMenuExpanded ? rightSideMenuOrigin : CGPoint(x: view.bounds.width, y: rightSideMenuOrigin.y),
                size: CGSize(width: width, height: rightSideMenuHeight)
            )
            
            if animateBg {
                backgroundView.alpha = (isRightMenuExpanded) ? 0.5 : 0.0
            }
        }, completion: { [self] finished in
            if isRightMenuExpanded == false {
                rightSideMenuController.removeFromParent()
                rightSideMenuController.view.removeFromSuperview()
                
                if animateBg {
                    backgroundView.removeFromSuperview()
                }
            }
        })
    }

    func navigateTo(viewController: UIViewController) {
        rootViewController.display(viewController: viewController)
    }
    
    func changeRoot(viewController: UIViewController) {
        rootViewController.changeRootController(viewController: viewController)
        
        switch viewController {
        case _ where viewController is AccountInfoViewController:
            leftSideMenuController.selectedMenuOption = .none
            rightSideMenuController.selectedMenuOption = .accountInfo
            
        case _ where viewController is ActivityFeedViewController:
            leftSideMenuController.selectedMenuOption = .none
            rightSideMenuController.selectedMenuOption = .activityFeed
            
        case _ where viewController is InvitesViewController:
            leftSideMenuController.selectedMenuOption = .none
            rightSideMenuController.selectedMenuOption = .invitations
            
        case _ where viewController is AccountSettingsViewController:
            leftSideMenuController.selectedMenuOption = .none
            rightSideMenuController.selectedMenuOption = .security
            
        case _ where viewController is AccountSettingsViewController:
            leftSideMenuController.selectedMenuOption = .none
            rightSideMenuController.selectedMenuOption = .security
            
        case _ where viewController is MainViewController:
            if (viewController as! MainViewController).viewModel is PublicFilesViewModel {
                leftSideMenuController.selectedMenuOption = .publicFiles
            } else {
                leftSideMenuController.selectedMenuOption = .files
            }
            rightSideMenuController.selectedMenuOption = .none
            
        case _ where viewController is SharesViewController:
            leftSideMenuController.selectedMenuOption = .shares
            rightSideMenuController.selectedMenuOption = .none
            
        case _ where viewController is MembersViewController:
            leftSideMenuController.selectedMenuOption = .members
            rightSideMenuController.selectedMenuOption = .none
            
        case _ where viewController is ArchivesViewController:
            leftSideMenuController.selectedMenuOption = .manageArchives
            rightSideMenuController.selectedMenuOption = .none
            
        case _ where viewController is PublicArchiveViewController:
            leftSideMenuController.selectedMenuOption = .archives
            rightSideMenuController.selectedMenuOption = .none
            
        default:
            break
        }
        
        if isLeftMenuExpanded {
            toggleMenu()
        }
        
        if isRightMenuExpanded {
            toggleRightSideMenu()
        }
    }
    
    fileprivate func configureGestures() {
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeLeft))
        swipeLeftGesture.direction = .left
        backgroundView.addGestureRecognizer(swipeLeftGesture)
        
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(didSwipeRight))
        swipeRightGesture.direction = .right
        backgroundView.addGestureRecognizer(swipeRightGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTapOutside))
        backgroundView.addGestureRecognizer(tapGesture)
    }
    
    @objc
    fileprivate func didSwipeLeft() {
        if isLeftMenuExpanded {
            toggleMenu()
        }
    }
    
    @objc
    fileprivate func didSwipeRight() {
        if isRightMenuExpanded {
            toggleRightSideMenu()
        }
    }
    
    @objc
    fileprivate func didTapOutside() {
        if isLeftMenuExpanded {
            toggleMenu()
        }
        
        if isRightMenuExpanded {
            toggleRightSideMenu()
        }
    }
}

extension DrawerViewController: DrawerMenuDelegate {
    func didTapDrawerMenuButton() {
        var animateBG = true
        
        if isRightMenuExpanded {
            animateBG = false
            toggleRightSideMenu(animateBg: animateBG)
        }
        toggleMenu(animateBg: animateBG)
    }
    
    func didTapRightSideMenuButton() {
        var animateBG = true
        
        if isLeftMenuExpanded {
            animateBG = false
            toggleMenu(animateBg: animateBG)
        }
        toggleRightSideMenu(animateBg: animateBG)
    }
}
