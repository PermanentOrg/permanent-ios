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
        
        if let accountHasLegacySteward = viewModel?.getLegacyPlanningAccount(), !accountHasLegacySteward {
            if let legacyPlanningIntroVC = UIViewController.create(withIdentifier: .legacyPlanningIntro, from: .legacyPlanning) as? LegacyPlanningIntroViewController {
                legacyPlanningIntroVC.viewModel = viewModel
                navigationController?.viewControllers = [legacyPlanningIntroVC]
            }
        }
    }
}
