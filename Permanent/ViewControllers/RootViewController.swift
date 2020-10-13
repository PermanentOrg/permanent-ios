//
//  RootViewController.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25/09/2020.
//

import UIKit

class RootViewController: UIViewController {
    private var current: UIViewController
    
    init() {
        self.current = SplashViewController()
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        self.current = SplashViewController()
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupChild(current)
    }
    
    func setRoot(named controller: ViewControllerIdentifier, from storyboard: StoryboardName) {
        let navController = NavigationController()
        let viewController = UIStoryboard(name: storyboard.name, bundle: nil)
            .instantiateViewController(withIdentifier: controller.identifier)
        
        navController.viewControllers = [viewController]
        
        setupChild(navController)
        removeChild(current)
        current = navController
    }
    
    func setRoot<T: UIViewController>(_ viewController: T.Type) {
        let navController = NavigationController(rootViewController: T())
        
        setupChild(navController)
        removeChild(current)
        current = navController
    }
    
    fileprivate func setupChild(_ viewController: UIViewController) {
        addChild(viewController)
        viewController.view.frame = view.bounds
        view.addSubview(viewController.view)
        viewController.didMove(toParent: self)
    }
    
    fileprivate func removeChild(_ viewController: UIViewController) {
        viewController.willMove(toParent: nil)
        viewController.view.removeFromSuperview()
        viewController.removeFromParent()
    }
}
