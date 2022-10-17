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
    
    func setTextSpacingBy(value: Double) {
      if let textString = self.text {
        let attributedString = NSMutableAttributedString(string: textString)
          attributedString.addAttribute(NSAttributedString.Key.kern, value: value, range: NSRange(location: 0, length: attributedString.length - 1))
        attributedText = attributedString
      }
    }
}
