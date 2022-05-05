//
//  AccountOnboardingPageOne.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 04.05.2022.
//

import UIKit

class AccountOnboardingPageOne: BaseViewController<AccountOnboardingViewModel> {
    
    @IBOutlet weak var welcomeLabel: UILabel!
    @IBOutlet weak var detailsLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        welcomeLabel.font = Text.style.font
        detailsLabel.font = Text.style5.font
    }
}
