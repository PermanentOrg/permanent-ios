//
//  OnboadingViewStoryboard.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20/08/2020.
//

import UIKit

class OnboadingViewController: BaseViewController<OnboardingViewModel> {
    @IBOutlet var nextButtonLabel: RoundedButton!
    @IBOutlet var skipButtonLabel: UIButton!
    
    var delegate: OnboardingViewModelDelegate?
    weak var pageViewController: PageViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.backgroundColor = .darkBlue
        skipButtonLabel.setTitleColor(.white, for: .normal)
        nextButtonLabel.setTitle(Translations.next, for: .normal)
    }
    
    @IBAction func nextButton(_ sender: RoundedButton) {
        if pageViewController?.viewModel?.moveToNextPage() == false {
            goToLogin()
        }
    }

    @IBAction func skipButton(_ sender: UIButton) {
        goToLogin()
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showPageViewControllerSegue" {
            pageViewController = segue.destination as? PageViewController
            
            pageViewController?.viewModel = PageViewModel()
            pageViewController?.viewModel?.delegate = pageViewController
            
            pageViewController?.viewModel?.onCurrentPageChange = { [weak self] currentPageIndex, _ in
                self?.nextButtonLabel.setTitle("\(Constants.onboardingBottomButtonText[currentPageIndex])", for: .normal)
            }
        }
    }
}

extension OnboadingViewController: OnboardingViewModelDelegate, UIScrollViewDelegate {
    func configureHolderView() {}
    
    func nextButtonPressed(page: Int, scrollView: UIScrollView) {}
    
    func goToLogin() {
        PreferencesManager.shared.set(false, forKey: Constants.Keys.StorageKeys.isNewUserStorageKey)
        
        let signUpController = UIStoryboard(name: StoryboardName.authentication.name, bundle: nil)
            .instantiateViewController(withIdentifier: ViewControllerIdentifier.signUp.identifier)
        
        navigationController?.setViewControllers([signUpController], animated: true)
    }
}
