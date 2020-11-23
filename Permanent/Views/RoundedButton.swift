//
//  RoundedButton.swift
//  Permanent
//
//  Created by Gabi Tiplea on 17/08/2020.
//

import UIKit

@IBDesignable
class RoundedButton: CustomButton {
    
    var color: HighlightColor = (.secondary, UIColor.secondary.lighter(by: 5) ?? .secondary)
    
    var bgColor: UIColor? {
        didSet {
            guard let bgColor = bgColor else { return }
            
            backgroundColor = bgColor
            self.color = (default: bgColor, highlightColor: bgColor.lighter(by: 5) ?? bgColor)
        }
    }
    
    @IBInspectable
    var radius: CGFloat = 0.0 {
        didSet {
            layer.cornerRadius = radius
        }
    }
    
    override var isHighlighted: Bool {
        didSet {
            backgroundColor = isHighlighted ? color.highlightColor : color.default
        }
    }
    
    override func setup() {
        backgroundColor = UIColor.tangerine
        titleLabel?.font = Text.style.font
        titleLabel?.textAlignment = Text.style.alignment
        setTitleColor(UIColor.white, for: .normal)
        layer.cornerRadius = Constants.Design.customButtonCornerRadius
        heightAnchor.constraint(greaterThanOrEqualToConstant: Constants.Design.customButtonHeight).isActive = true
    }
}
