//
//  OnboardingPageTwo.swift
//  Permanent
//
//  Created by Lucian Cerbu on 21/08/2020.
//

import UIKit

class OnboardingPageTwo: UIViewController {
    @IBOutlet weak var labelOne: UILabel!
    @IBOutlet weak var labelTwo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .darkBlue
        labelOne.textColor = .white
        labelTwo.textColor = .white
        
        labelOne.attributedText = Text.style.setTextWithLineSpacing(text: Constants.onboardingTextBold[1])
        labelOne.font = Text.style.font
        labelOne.textAlignment = Text.style.alignment
        labelOne.numberOfLines = 3
        
        labelTwo.attributedText = Text.style2.setTextWithLineSpacing(text: Constants.onboardingTextNormal[1])
        labelTwo.font = Text.style2.font
        labelTwo.textAlignment = Text.style2.alignment
        labelTwo.numberOfLines = 3
    }
}
