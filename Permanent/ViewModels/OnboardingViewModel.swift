//
//  OnboardingViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class OnboardingViewModel: ViewModelInterface {
    weak var delegate: OnboardingViewModelDelegate?
}

protocol OnboardingViewModelDelegate: ViewModelDelegateInterface {
    func configureHolderView()
    func nextButtonPressed(page: Int, scrollView: UIScrollView)
    func goToLogin()
}
