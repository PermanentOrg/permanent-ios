//  
//  DrawerViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24.11.2020.
//

import UIKit
import SwiftUI

protocol DrawerMenuDelegate: AnyObject {
    func didTapDrawerMenuButton()
    func didTapRightSideMenuButton()
}

class DrawerViewController: UIViewController {
    var rootViewController: RootNavigationController
    var leftSideMenuController: SideMenuViewController
    var isLeftMenuExpanded: Bool = false
    let backgroundView = UIView()
    var settingsRouter: SettingsRouter
    var showArchives: Bool
    
    fileprivate var leftSideMenuOrigin: CGPoint { CGPoint(x: 0, y: view.safeAreaInsets.top + rootViewController.barHeight) }
    fileprivate var rightSideMenuOrigin: CGPoint { CGPoint(x: view.bounds.width - (view.bounds.width * 0.75), y: view.safeAreaInsets.top + rootViewController.barHeight + 0.5) }
    fileprivate var leftSideMenuHeight: CGFloat { view.bounds.height - leftSideMenuOrigin.y }
    fileprivate var rightSideMenuHeight: CGFloat { view.bounds.height - rightSideMenuOrigin.y }
    
    init(rootViewController: RootNavigationController, leftSideMenuController: SideMenuViewController, showArchives: Bool = false) {
        self.rootViewController = rootViewController
        self.leftSideMenuController = leftSideMenuController
        self.settingsRouter = SettingsRouter(rootViewController: rootViewController, currentView: .settings)
        self.showArchives = showArchives
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
        showArchivesView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func toggleMenu(animateBg: Bool = true) {
        let offset: CGFloat = view.safeAreaInsets.top > 47 ? 6 : 0
        
        isLeftMenuExpanded.toggle()
        rootViewController.view.hideKeyboard()
        
        if leftSideMenuController.parent == nil {
            let bgViewOrigin = CGPoint(x: 0, y: view.safeAreaInsets.top + rootViewController.barHeight - offset)
            backgroundView.frame = CGRect(origin: bgViewOrigin, size: CGSize(width: view.bounds.width, height: view.bounds.height - bgViewOrigin.y + offset))
            view.addSubview(backgroundView)
            
            addChild(leftSideMenuController)
            view.addSubview(leftSideMenuController.view)
            leftSideMenuController.didMove(toParent: self)
        }
        
        leftSideMenuController.view.frame = CGRect(
            origin: CGPoint(x: isLeftMenuExpanded ? -(view.bounds.width * 0.75) : 0, y: leftSideMenuOrigin.y - offset),
            size: CGSize(width: view.bounds.width * 0.75, height: leftSideMenuHeight + offset)
        )
        leftSideMenuController.adjustUIForAnimation(isOpening: isLeftMenuExpanded)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: { [self] in
            leftSideMenuController.view.frame = CGRect(
                origin: CGPoint(x: isLeftMenuExpanded ? 0 : -(view.bounds.width * 0.75), y: leftSideMenuOrigin.y - offset),
                size: CGSize(width: view.bounds.width * 0.75, height: leftSideMenuHeight + offset)
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

    func navigateTo(viewController: UIViewController) {
        rootViewController.display(viewController: viewController)
    }
    
    func changeRoot(viewController: UIViewController) {
        rootViewController.changeRootController(viewController: viewController)
        
        switch viewController {
            
        case _ where viewController is MainViewController:
            if (viewController as! MainViewController).viewModel is PublicFilesViewModel {
                leftSideMenuController.selectedMenuOption = .publicFiles
            } else {
                leftSideMenuController.selectedMenuOption = .files
            }
            
        default:
            break
        }
        
        if isLeftMenuExpanded {
            toggleMenu()
        }
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
        if isLeftMenuExpanded {
            toggleMenu()
        }
    }
    
    @objc
    fileprivate func didTapOutside() {
        if isLeftMenuExpanded {
            toggleMenu()
        }
    }
    
    func showArchivesView() {
        if showArchives {
            let screenView = ViewRepresentableContainer(viewRepresentable: ArchivesViewControllerRepresentable(), title: ArchivesViewControllerRepresentable().title)
            let host = UIHostingController(rootView: screenView)
            host.modalPresentationStyle = .fullScreen
            rootViewController.present(host, animated: true, completion: nil)
        }
    }
}

extension DrawerViewController: DrawerMenuDelegate {
    func didTapDrawerMenuButton() {
        var animateBG = true
        
        toggleMenu(animateBg: animateBG)
    }
    
    func didTapRightSideMenuButton() {
        var animateBG = true
        
        if isLeftMenuExpanded {
            animateBG = false
            toggleMenu(animateBg: animateBG)
        }
        
        isLeftMenuExpanded = false
        backgroundView.alpha = 0.0
        rootViewController.view.hideKeyboard()
        
        settingsRouter.navigate(to: .settings, router: settingsRouter)
    }
}
