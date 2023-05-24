//
//  LegacyPlanningLoadingViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 17.05.2023.
//

import UIKit

class LegacyPlanningLoadingViewController: BaseViewController<LegacyPlanningViewModel> {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkBlue
        
        styleNavBar()
        
        navigationItem.title = "Legacy Planning".localized()
        
        viewModel?.getLegacyPlanningAccount(completion: { [weak self] result in
            switch result {
            case .success(let haveLegacySteward):
                if let haveLegacySteward = haveLegacySteward, haveLegacySteward {
                    self?.showStatus()
                } else {
                    self?.showIntro()
                }
            case .failure(_):
                self?.showAlert(title: .error, message: .errorMessage)
            }
        })
    }
    
    func showIntro() {
        if let legacyPlanningIntroVC = UIViewController.create(withIdentifier: .legacyPlanningIntro, from: .legacyPlanning) as? LegacyPlanningIntroViewController {
            legacyPlanningIntroVC.viewModel = viewModel
            navigationController?.viewControllers = [legacyPlanningIntroVC]
        }
    }
    
    func showStatus() {
        if let statusViewController = UIViewController.create(withIdentifier: .legacyPlanningStatus, from: .legacyPlanning) as? LegacyPlanningStatusViewController {
            statusViewController.viewModel = LegacyPlanningStatusViewModel()
            navigationController?.viewControllers = [statusViewController]
        }
    }
}
