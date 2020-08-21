//
//  OnboadingViewStoryboard.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class OnboadingViewStoryboard: BaseViewController<OnboardingViewModel> {
    
    override var prefersStatusBarHidden: Bool{
        return true
    }
    
    @IBOutlet weak var nextButtonLabel: RoundedButton!
    @IBOutlet weak var skipButtonLabel: UIButton!
    
    var delegate: OnboardingViewModelDelegate?
    weak var pageViewController: PageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .darkBlue
        skipButtonLabel.setTitleColor(.white, for: .normal)
        nextButtonLabel.setTitle("Next", for: .normal)
        
        
    }
    
    @IBAction func nextButton(_ sender: RoundedButton) {
        if pageViewController?.moveToNextPage() == false {
            goToLogin()
        }
    }
    @IBAction func skipButton(_ sender: UIButton) {
        goToLogin()
    }
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if  segue.identifier == "showPageViewControllerSegue" {
            
            pageViewController = segue.destination as? PageViewController
            
            pageViewController?.onCurrentPageChange = { [weak self] (currentPageIndex, numberOfPages) in
                self?.nextButtonLabel.setTitle("\(Constants.onboardingBottomButtonText[currentPageIndex])", for: .normal)
            }
        }
    }
    
}
extension OnboadingViewStoryboard: OnboardingViewModelDelegate,UIScrollViewDelegate {
    func configureHolderView() {
        
    }
    
    func nextButtonPressed(page: Int, scrollView: UIScrollView) {
        
    }
    
    func goToLogin() {
        
        UserDefaultsService.shared.setIsNotNewUser()
        navigationController?.setViewControllers([LoginViewController.init(nibName: "LoginViewController", bundle: .main)], animated: true)
    }
    
}
