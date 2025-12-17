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
    
    // iOS 26+ Workspace Tab Bar (fixed at root level)
    private var workspaceTabViewModel: WorkspaceTabViewModel?
    private var workspaceTabBarHostingController: UIHostingController<AnyView>?
    
    fileprivate var leftSideMenuOrigin: CGPoint { CGPoint(x: 0, y: view.safeAreaInsets.top + rootViewController.barHeight) }
    fileprivate var rightSideMenuOrigin: CGPoint { CGPoint(x: view.bounds.width - (view.bounds.width * 0.75), y: view.safeAreaInsets.top + rootViewController.barHeight + 0.5) }
    fileprivate var leftSideMenuHeight: CGFloat { view.bounds.height - leftSideMenuOrigin.y }
    fileprivate var rightSideMenuHeight: CGFloat { view.bounds.height - rightSideMenuOrigin.y }
    
    init(rootViewController: RootNavigationController, leftSideMenuController: SideMenuViewController, showArchives: Bool = false) {
        self.rootViewController = rootViewController
        self.leftSideMenuController = leftSideMenuController
        self.settingsRouter = SettingsRouter(rootViewController: rootViewController)
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
    
        // Setup fixed workspace tab bar for iOS 26+
        if #available(iOS 26, *) {
            setupWorkspaceTabBar()
        }
    
        configureGestures()
        showArchivesView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func toggleMenu(animateBg: Bool = true) {
        let offset: CGFloat = view.safeAreaInsets.top > 47 ? 6 : 0
        let menuWidth: CGFloat = view.bounds.width * (Constants.Design.isPhone ? 0.75 : 0.33)
        
        
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
            origin: CGPoint(x: isLeftMenuExpanded ? -(menuWidth) : 0, y: leftSideMenuOrigin.y - offset),
            size: CGSize(width: menuWidth, height: leftSideMenuHeight + offset)
        )
        leftSideMenuController.adjustUIForAnimation(isOpening: isLeftMenuExpanded)
        
        UIView.animate(withDuration: 0.3, delay: 0, options: .curveEaseInOut, animations: { [self] in
            leftSideMenuController.view.frame = CGRect(
                origin: CGPoint(x: isLeftMenuExpanded ? 0 : -(menuWidth), y: leftSideMenuOrigin.y - offset),
                size: CGSize(width: menuWidth, height: leftSideMenuHeight + offset)
            )
            
            if animateBg {
                backgroundView.alpha = (isLeftMenuExpanded) ? (Constants.Design.isPhone ? 0.5 : 0.2) : 0.0
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
    
    func changeRoot(viewController: UIViewController, useTabTransition: Bool = false) {
        rootViewController.changeRootController(viewController: viewController, useTabTransition: useTabTransition)
        
        // Update workspace tab bar selection for iOS 26+
        if #available(iOS 26, *) {
            updateWorkspaceTabSelection(for: viewController)
        }
        
        switch viewController {
            
        case _ where viewController is MainViewController:
            if (viewController as! MainViewController).viewModel is PublicFilesViewModel {
                leftSideMenuController.selectedMenuOption = .publicFiles
            } else {
                leftSideMenuController.selectedMenuOption = .files
            }
            
        case _ where viewController is SharesViewController:
            leftSideMenuController.selectedMenuOption = .shares
            
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
    
    // MARK: - iOS 26+ Workspace Tab Bar Setup
    
    @available(iOS 26, *)
    private func setupWorkspaceTabBar() {
        // Initialize view model
        workspaceTabViewModel = WorkspaceTabViewModel()
        
        // Set initial workspace based on current root view controller
        if let mainVC = rootViewController.viewControllers.first as? MainViewController {
            if mainVC.viewModel is PublicFilesViewModel {
                workspaceTabViewModel?.selectedWorkspace = .public
            } else {
                workspaceTabViewModel?.selectedWorkspace = .private
            }
        } else if rootViewController.viewControllers.first is SharesViewController {
            workspaceTabViewModel?.selectedWorkspace = .shared
        }
        
        guard let viewModel = workspaceTabViewModel else { return }
        
        // Create the SwiftUI workspace tab bar
        let tabBarView = WorkspaceTabBarView(
            viewModel: viewModel,
            onWorkspaceSelected: { [weak self] workspace in
                self?.handleWorkspaceSelection(workspace)
            },
            onPlusButtonTapped: { [weak self] in
                self?.handlePlusButtonTapped()
            },
            onChecklistButtonTapped: { [weak self] in
                self?.handleChecklistButtonTapped()
            }
        )
        
        // Wrap in AnyView for type erasure
        let hostingController = UIHostingController(rootView: AnyView(tabBarView))
        hostingController.view.backgroundColor = .clear
        hostingController.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Add as child view controller
        addChild(hostingController)
        view.addSubview(hostingController.view)
        hostingController.didMove(toParent: self)
        
        // Position at bottom using constraints (FIXED - never moves)
        NSLayoutConstraint.activate([
            hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hostingController.view.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -8),
            hostingController.view.heightAnchor.constraint(equalToConstant: 80)
        ])
        
        workspaceTabBarHostingController = hostingController
    }
    
    @available(iOS 26, *)
    private func updateWorkspaceTabSelection(for viewController: UIViewController) {
        guard let viewModel = workspaceTabViewModel else { return }
        
        switch viewController {
        case let mainVC as MainViewController:
            if mainVC.viewModel is PublicFilesViewModel {
                viewModel.selectedWorkspace = .public
            } else {
                viewModel.selectedWorkspace = .private
            }
        case _ as SharesViewController:
            viewModel.selectedWorkspace = .shared
        default:
            break
        }
    }
    
    @available(iOS 26, *)
    private func handleWorkspaceSelection(_ workspace: WorkspaceType) {
        // Get or create cached view controller
        guard let currentArchive = AuthenticationManager.shared.session?.selectedArchive else { return }
        let currentArchiveId = currentArchive.archiveID ?? 0
        
        if let cachedVC = WorkspaceControllerCache.shared.get(workspace: workspace, archiveId: currentArchiveId) {
            // Use cached view controller with fade transition
            changeRoot(viewController: cachedVC, useTabTransition: true)
        } else {
            // Create new view controller
            let newVC: UIViewController
            
            switch workspace {
            case .private:
                let privateViewModel = MyFilesViewModel()
                let mainVC = UIViewController.create(
                    withIdentifier: .main,
                    from: .main
                ) as! MainViewController
                mainVC.viewModel = privateViewModel
                newVC = mainVC
            case .shared:
                newVC = UIViewController.create(
                    withIdentifier: .shares,
                    from: .share
                )
            case .public:
                let publicViewModel = PublicFilesViewModel()
                let mainVC = UIViewController.create(
                    withIdentifier: .main,
                    from: .main
                ) as! MainViewController
                mainVC.viewModel = publicViewModel
                newVC = mainVC
            }
            
            // Cache the new view controller
            WorkspaceControllerCache.shared.set(newVC, workspace: workspace, archiveId: currentArchiveId)
            
            // Display with fade transition
            changeRoot(viewController: newVC, useTabTransition: true)
        }
    }
    
    @available(iOS 26, *)
    private func handlePlusButtonTapped() {
        // Delegate to current view controller
        if let mainVC = rootViewController.viewControllers.first as? MainViewController {
            mainVC.didTap()
        }
    }
    
    @available(iOS 26, *)
    private func handleChecklistButtonTapped() {
        // Delegate to current view controller
        if let mainVC = rootViewController.viewControllers.first as? MainViewController {
            mainVC.didTapChecklist()
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
