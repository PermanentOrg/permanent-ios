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
    let pageOnePendingVC = UIViewController.create(withIdentifier: .accountOnboardingPg1Pending, from: .accountOnboarding) as! AccountOnboardingPageOneWithPendingArchives
    let pageTwoVC = UIViewController.create(withIdentifier: .accountOnboardingPg2, from: .accountOnboarding) as! AccountOnboardingPageTwo
    let pageTwoPendingVC = UIViewController.create(withIdentifier: .accountOnboardingPg2Pending, from: .accountOnboarding) as! AccountOnboardingPageTwoWithPendingArchives
    let pageThreeVC = UIViewController.create(withIdentifier: .accountOnboardingPg3, from: .accountOnboarding) as! AccountOnboardingPageThree

    override func viewDidLoad() {
        super.viewDidLoad()
        
        viewModel = AccountOnboardingViewModel()
        pageOneVC.viewModel = viewModel
        pageTwoVC.viewModel = viewModel
        pageThreeVC.viewModel = viewModel
        pageOnePendingVC.viewModel = viewModel
        pageTwoPendingVC.viewModel = viewModel
        
        viewModel?.getAccountInfo({ _, _ in })
        
        updatePageIndicator()
        updateNavButtons()
        
        addChild(pageViewController)
        containerView.addSubview(pageViewController.view)
        pageViewController.view.frame = containerView.bounds
        pageViewController.didMove(toParent: self)
        
        viewModel?.getAccountArchives({ [self] error in
            if let pendingArchives = viewModel?.accountArchives,
               pendingArchives.count > .zero {
                viewModel?.currentPage = .pendingInvitation
                updateCurrentPage(direction: .forward)
                pageViewController.setViewControllers([pageOnePendingVC], direction: .forward, animated: false)
            } else {
                pageViewController.setViewControllers([pageOneVC], direction: .forward, animated: false)
            }
        })
        
        NotificationCenter.default.addObserver(forName: AccountOnboardingViewModel.archiveTypeChanged, object: viewModel, queue: nil) { [weak self] notification in
            self?.updateNavButtons()
        }
        NotificationCenter.default.addObserver(forName: AccountOnboardingViewModel.archiveNameChanged, object: viewModel, queue: nil) { [weak self] notification in
            self?.updateNavButtons()
        }
    }
    
    func initUI() {
        if viewModel?.currentPage == .pendingInvitation {
            nextButton.setup()
            nextButton.setTitleColor(UIColor.white.darker(by: 30), for: .disabled)
            nextButton.setTitleColor(UIColor.white, for: .highlighted)
            nextButton.configureActionButtonUI(title: viewModel?.nextButtonTitle ?? "")
            
            backButton.setup()
            backButton.setTitleColor(UIColor.white, for: .normal)
            backButton.setTitleColor(UIColor.white, for: .highlighted)
            backButton.configureActionButtonUI(title: viewModel?.backButtonTitle ?? "", bgColor: .doveGray)
        } else {
            nextButton.setup()
            nextButton.setTitleColor(UIColor.white.darker(by: 30), for: .disabled)
            nextButton.setTitleColor(UIColor.white, for: .highlighted)
            nextButton.configureActionButtonUI(title: viewModel?.nextButtonTitle ?? "")
            
            backButton.setup()
            backButton.setTitleColor(UIColor.white, for: .normal)
            backButton.setTitleColor(UIColor.white, for: .highlighted)
            backButton.configureActionButtonUI(title: "Back".localized(), bgColor: .doveGray)
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
        nextButton.isHidden = viewModel?.currentPage.nextButtonHidden ?? false
        
        backButton.configureActionButtonUI(title: viewModel?.backButtonTitle ?? "")
        backButton.isHidden = !(viewModel?.hasBackButton ?? false)
    }
    
    func updatePageIndicator() {
        switch viewModel?.currentPage {
        case .getStarted:
            firstStepIndicator.backgroundColor = .primary
            secondStepIndicator.backgroundColor = .lightGray
            thirdStepIndicator.backgroundColor = .lightGray
            
        case .createArchive:
            firstStepIndicator.backgroundColor = .primary
            secondStepIndicator.backgroundColor = .primary
            thirdStepIndicator.backgroundColor = .lightGray
            
        case .nameArchive:
            firstStepIndicator.backgroundColor = .primary
            secondStepIndicator.backgroundColor = .primary
            thirdStepIndicator.backgroundColor = .primary
            
        default: break
        }
    }
    
    func updateDisplayedVC(direction: UIPageViewController.NavigationDirection) {
        let nextViewController: UIViewController
        
        switch viewModel?.currentPage {
        case .getStarted: nextViewController = pageOneVC
            
        case .createArchive: nextViewController = pageTwoVC
            
        case .nameArchive: nextViewController = pageThreeVC
            
        case .pendingInvitation: nextViewController = pageOnePendingVC
            
        case .acceptedInvitation: nextViewController = pageTwoPendingVC
            
        default: nextViewController = pageOneVC
        }
        
        pageViewController.setViewControllers([nextViewController], direction: direction, animated: true)
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        var direction: UIPageViewController.NavigationDirection = .reverse
        switch viewModel?.currentPage {
        case .createArchive:
            if let archives = viewModel?.accountArchives {
                if archives.contains(where: { archive in
                    archive.archiveVO?.status == .pending
                }) {
                    viewModel?.currentPage = .pendingInvitation
                } else if archives.contains(where: { archive in
                    archive.archiveVO?.status == .ok
                }) {
                    viewModel?.currentPage = .acceptedInvitation
                } else {
                    viewModel?.currentPage = .getStarted
                }
            }
            
        case .nameArchive: viewModel?.currentPage = .createArchive
            
        case .pendingInvitation:
            viewModel?.currentPage = .createArchive
            direction = .forward
            
        case .acceptedInvitation: viewModel?.currentPage = .createArchive
            direction = .forward
            
        default: viewModel?.currentPage = .getStarted
        }
        
        updateCurrentPage(direction: direction)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any) {
        switch viewModel?.currentPage {
        case .getStarted: viewModel?.currentPage = .createArchive
    
        case .createArchive: viewModel?.currentPage = .nameArchive
            
        case .nameArchive: viewModel?.currentPage = .nameArchive
            
        case .pendingInvitation:
            showSpinner()
            viewModel?.acceptAllPendingArchives({ [weak self] result, error in
                self?.hideSpinner()
                if result {
                    self?.viewModel?.currentPage = .acceptedInvitation
                    self?.updateCurrentPage(direction: .forward)
                    return
                } else {
                    self?.showErrorAlert(message: .errorMessage)
                }
            })
            
        case .acceptedInvitation: viewModel?.currentPage = .acceptedInvitation
            
        default: viewModel?.currentPage = .getStarted
        }
        
        if viewModel?.currentPage == .nameArchive {
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
