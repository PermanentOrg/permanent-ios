//
//  RoundedButton.swift
//  Permanent
//
//  Created by Gabi Tiplea on 17/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class RoundedButton: CustomButton {
    
    override func setup() {
        backgroundColor = UIColor.tangerine
        titleLabel?.font = Text.style.font
        titleLabel?.textAlignment = Text.style.alignment
        setTitleColor(UIColor.white, for: .normal)
        layer.cornerRadius = Constants.customButtonCornerRadius
        heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.customButtonHeight).isActive = true
    }
}
