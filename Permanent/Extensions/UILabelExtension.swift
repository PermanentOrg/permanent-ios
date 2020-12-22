//  
//  UILabelExtension.swift
//  Permanent
//
//  Created by Adrian Creteanu on 21.12.2020.
//

import UIKit

extension UILabel {
    
    func style(
        withFont font: UIFont,
        textColor: UIColor = .textPrimary,
        text: String
    ) {
        self.font = font
        self.textColor = textColor
        self.text = text
    }
    
}
