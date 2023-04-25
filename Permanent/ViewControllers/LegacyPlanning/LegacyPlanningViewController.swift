//
//  LegacyPlanningViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.04.2023.
//

import UIKit

class LegacyPlanningViewController: BaseViewController<LegacyPlanningViewModel> {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .backgroundPrimary
        title = "Legacy Planning".localized()
    }
    
}
