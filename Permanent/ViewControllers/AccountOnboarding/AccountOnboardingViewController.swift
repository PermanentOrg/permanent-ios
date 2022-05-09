//
//  AccountOnboardingViewController.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 03.05.2022.
//

import UIKit

class AccountOnboardingViewController: BaseViewController<AccountOnboardingViewModel> {
    @IBOutlet weak var firstStepIndicator: UIView!
    @IBOutlet weak var secondStepIndicator: UIView!
    @IBOutlet weak var thirdStepIndicator: UIView!
    
    @IBOutlet weak var backButton: RoundedButton!
    @IBOutlet weak var nextButton: RoundedButton!
    
    @IBOutlet weak var containerView: UIView!
    
    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
    let pageOneVC = UIViewController.create(withIdentifier: .accountOnboardingPg1, from: .accountOnboarding) as! AccountOnboardingPageOne
    let pageTwoVC = UIViewController.create(withIdentifier: .accountOnboardingPg2, from: .accountOnboarding) as! AccountOnboardingPageTwo
    let pageThreeVC = UIViewController.create(withIdentifier: .accountOnboardingPg3, from: .accountOnboarding) as! AccountOnboardingPageThree

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = AccountOnboardingViewModel()
        pageOneVC.viewModel = viewModel
        pageTwoVC.viewModel = viewModel
        pageThreeVC.viewModel = viewModel
        
        viewModel?.getAccountInfo({ _, _ in })
        
        nextButton.setup()
        nextButton.setTitleColor(UIColor.white.darker(by: 30), for: .disabled)
        nextButton.setTitleColor(UIColor.white, for: .highlighted)
        nextButton.configureActionButtonUI(title: viewModel?.nextButtonTitle ?? "")
        
        backButton.setup()
        backButton.setTitleColor(UIColor.white, for: .normal)
        backButton.setTitleColor(UIColor.white, for: .highlighted)
        backButton.configureActionButtonUI(title: "Back".localized(), bgColor: .doveGray)
        
        updatePageIndicator()
        updateNavButtons()
        
        addChild(pageViewController)
        containerView.addSubview(pageViewController.view)
        pageViewController.view.frame = containerView.bounds
        pageViewController.didMove(toParent: self)
        
        pageViewController.setViewControllers([pageOneVC], direction: .forward, animated: false)
        
        NotificationCenter.default.addObserver(forName: AccountOnboardingViewModel.archiveTypeChanged, object: viewModel, queue: nil) { [weak self] notification in
            self?.updateNavButtons()
        }
        NotificationCenter.default.addObserver(forName: AccountOnboardingViewModel.archiveNameChanged, object: viewModel, queue: nil) { [weak self] notification in
            self?.updateNavButtons()
        }
    }
    
    func updateCurrentPage(direction: UIPageViewController.NavigationDirection) {
        updatePageIndicator()
        updateDisplayedVC(direction: direction)
        updateNavButtons()
    }
    
    func updateNavButtons() {
        nextButton.configureActionButtonUI(title: viewModel?.nextButtonTitle ?? "")
        nextButton.isEnabled = viewModel?.nextButtonEnabled ?? false
        
        backButton.isHidden = !(viewModel?.hasBackButton ?? false)
    }
    
    func updatePageIndicator() {
        switch viewModel?.currentPage {
        case 0:
            firstStepIndicator.backgroundColor = .primary
            secondStepIndicator.backgroundColor = .lightGray
            thirdStepIndicator.backgroundColor = .lightGray
            
        case 1:
            firstStepIndicator.backgroundColor = .primary
            secondStepIndicator.backgroundColor = .primary
            thirdStepIndicator.backgroundColor = .lightGray
            
        case 2:
            firstStepIndicator.backgroundColor = .primary
            secondStepIndicator.backgroundColor = .primary
            thirdStepIndicator.backgroundColor = .primary
            
        default: break
        }
    }
    
    func updateDisplayedVC(direction: UIPageViewController.NavigationDirection) {
        let nextViewController: UIViewController
        
        switch viewModel?.currentPage {
        case 0: nextViewController = pageOneVC
            
        case 1: nextViewController = pageTwoVC
            
        case 2: nextViewController = pageThreeVC
            
        default: nextViewController = pageOneVC
        }
        
        pageViewController.setViewControllers([nextViewController], direction: direction, animated: true)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        viewModel?.currentPage -= 1
        
        updateCurrentPage(direction: .reverse)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        viewModel?.currentPage += 1
        
        if viewModel?.currentPage == 3 {
            showSpinner()
            viewModel?.finishOnboard({ status in
                self.hideSpinner()
                if status == .success {
                    AppDelegate.shared.rootViewController.setDrawerRoot()
                } else {
                    self.showErrorAlert(message: .errorMessage)
                }
            })
        } else {
            updateCurrentPage(direction: .forward)
        }
    }
}
