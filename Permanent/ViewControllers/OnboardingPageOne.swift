//
//  OnboardingPageOne.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class OnboardingPageOne: UIViewController {
    
    @IBOutlet weak var labelOne: UILabel!
    @IBOutlet weak var labelTwo: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .darkBlue
        
        labelOne.attributedText = Text.style.setTextWithLineSpacing(text: Constants.onboardingTextBold[0])
        labelOne.font = Text.style.font
        labelOne.textAlignment = Text.style.alignment
        labelOne.numberOfLines = 3
        labelOne.textColor = .white
        
        
        labelTwo.attributedText = Text.style2.setTextWithLineSpacing(text: Constants.onboardingTextNormal[0])
        labelTwo.font = Text.style2.font
        labelTwo.textAlignment = Text.style2.alignment
        labelTwo.numberOfLines = 3
        labelTwo.textColor = .white
        
    }
    
}
