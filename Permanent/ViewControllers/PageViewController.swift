//
//  PageViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 20/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class PageViewController: UIPageViewController {
    var currentViewControllers = [UIViewController]()
    var pageControl = UIPageControl.appearance(whenContainedInInstancesOf: [PageViewController.self])
    var currentPage = 0 {
        didSet {
            onCurrentPageChange?(currentPage,currentViewControllers.count)
        }
    }
    var onCurrentPageChange: ((Int, Int)->Void)?
    
    override func viewDidLoad() {
        dataSource = self
        delegate = self
        navigationController?.setNavigationBarHidden(true, animated: false)
        super.viewDidLoad()
        currentViewControllers.append(UIStoryboard(name: "OnboardingView", bundle: .main).instantiateViewController(withIdentifier: "OnboardingPageOne"))
        currentViewControllers.append(UIStoryboard(name: "OnboardingView", bundle: .main).instantiateViewController(withIdentifier: "OnboardingPageTwo"))
        currentViewControllers.append(UIStoryboard(name: "OnboardingView", bundle: .main).instantiateViewController(withIdentifier: "OnboardingPageThree"))
        
        if let firstVC = currentViewControllers.first {
            setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
        }
        
        pageControl.currentPageIndicatorTintColor = .tangerine
        pageControl.pageIndicatorTintColor = .white
        
    }
    
    func moveToNextPage () -> Bool {
        if currentPage < currentViewControllers.count - 1 {
            let viewController = self.currentViewControllers[self.currentPage + 1]
            self.setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
            self.currentPage += 1
            return true
        } else {
            return false
        }
    }
}
extension PageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let nextViewController = pendingViewControllers.first else {
            return
        }
        if let index = currentViewControllers.firstIndex(of: nextViewController)  {
            
            currentPage = index
        }
    }
}
extension PageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = currentViewControllers.firstIndex(of: viewController) else {
            print("Failed to find view controller")
            return nil
        }
        if index == 0 {
            // currentPage = 0
            return nil
        }
        else {
            let viewController = currentViewControllers[index - 1]
            return viewController
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = currentViewControllers.firstIndex(of: viewController) else {
            print("Failed to find view controller")
            return nil
        }
        if index == currentViewControllers.count - 1 {
            return nil
        }
        else {
            let viewController = currentViewControllers[index + 1]
            return viewController
        }
    }
    
    func presentationCount(for _: UIPageViewController) -> Int {
        return currentViewControllers.count
    }
    
    func presentationIndex(for _: UIPageViewController) -> Int {
        guard let viewController = viewControllers?.first else { return NSNotFound}
        guard let index = currentViewControllers.firstIndex(of: viewController) else {
            print("Failed to find view controller")
            return NSNotFound
        }
        return index
    }
}
