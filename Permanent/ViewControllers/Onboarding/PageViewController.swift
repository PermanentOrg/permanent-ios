//
//  PageViewController.swift
//  Permanent
//
//  Created by Gabi Tiplea on 20/08/2020.
//

import UIKit

class PageViewController: BasePageViewController<PageViewModel> {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self

        navigationController?.setNavigationBarHidden(true, animated: false)
        pageControl.currentPageIndicatorTintColor = .tangerine
        pageControl.pageIndicatorTintColor = .white
    }
}

extension PageViewController: UIPageViewControllerDelegate {
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let nextViewController = pendingViewControllers.first else {
            return
        }
        if let index = currentViewControllers.firstIndex(of: nextViewController) {
            viewModel?.currentPage = index
        }
    }
}

extension PageViewController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = currentViewControllers.firstIndex(of: viewController) else {
            print("Failed to find view controller")
            return nil
        }
        if let beforePageIndex = viewModel?.beforePageIndex(before: index) {
            return currentViewControllers[beforePageIndex]
        } else {
            return nil
        }
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = currentViewControllers.firstIndex(of: viewController) else {
            print("Failed to find view controller")
            return nil
        }
        if let nextPageIndex = viewModel?.nextPageIndex(after: index) {
            return currentViewControllers[nextPageIndex]
        } else {
            return nil
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

extension PageViewController: PageViewModelDelegate {
    func numberOfViewControllers() -> Int {
        return currentViewControllers.count
    }
    
    func setViewController(of index: Int) {
        if !(0..<currentViewControllers.count ~= index)  {
            return
        }
        let viewController = currentViewControllers[index]
        setViewControllers([viewController], direction: .forward, animated: true, completion: nil)
    }
    
    func createViewControllers() {
        currentViewControllers.append(UIStoryboard(name: "Onboarding", bundle: .main).instantiateViewController(withIdentifier: "OnboardingPageOne"))
        currentViewControllers.append(UIStoryboard(name: "Onboarding", bundle: .main).instantiateViewController(withIdentifier: "OnboardingPageTwo"))
        currentViewControllers.append(UIStoryboard(name: "Onboarding", bundle: .main).instantiateViewController(withIdentifier: "OnboardingPageThree"))
    }
}
