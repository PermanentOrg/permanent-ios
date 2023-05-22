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
        
        if viewModel?.getLegacyPlanningAccount() == true {
            showStatus()
        } else {
            showIntro()
        }
    }
    
    func showIntro() {
        if let legacyPlanningIntroVC = UIViewController.create(withIdentifier: .legacyPlanningIntro, from: .legacyPlanning) as? LegacyPlanningIntroViewController {
            legacyPlanningIntroVC.viewModel = viewModel
            navigationController?.viewControllers = [legacyPlanningIntroVC]
        }
    }
    
    func showStatus() {
        if let statusViewController = UIViewController.create(withIdentifier: .legacyPlanningStatus, from: .legacyPlanning) as? LegacyPlanningStatusViewController {
            statusViewController.viewModel = viewModel
            navigationController?.viewControllers = [statusViewController]
        }
    }
}
