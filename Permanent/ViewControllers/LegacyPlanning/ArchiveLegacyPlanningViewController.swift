//
//  ArchiveLegacyPlanningViewController.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.04.2023.
//

import UIKit

class ArchiveLegacyPlanningViewController: BaseViewController<LegacyPlanningViewModel> {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupUI()
    }
    
    private func setupUI() {
        view.backgroundColor = .backgroundPrimary
        title = "Archive Legacy Planning".localized()
    }
}
