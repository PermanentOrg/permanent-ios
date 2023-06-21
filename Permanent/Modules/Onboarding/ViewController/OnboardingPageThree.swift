//
//  OnboardingPageThree.swift
//  Permanent
//
//  Created by Lucian Cerbu on 21/08/2020.
//

import UIKit

class OnboardingPageThree: UIViewController {
    
    @IBOutlet weak var labelOne: UILabel!
    @IBOutlet weak var labelTwo: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .darkBlue
        labelOne.textColor = .white
        labelTwo.textColor = .white
        
        labelOne.attributedText = TextFontStyle.style.setTextWithLineSpacing(text: Constants.onboardingTextBold[2])
        labelOne.font = TextFontStyle.style.font
        labelOne.textAlignment = TextFontStyle.style.alignment
        labelOne.numberOfLines = 3
        
        labelTwo.attributedText = TextFontStyle.style2.setTextWithLineSpacing(text: Constants.onboardingTextNormal[2])
        labelTwo.font = TextFontStyle.style2.font
        labelTwo.textAlignment = TextFontStyle.style2.alignment
        labelTwo.numberOfLines = 3
    }
}
