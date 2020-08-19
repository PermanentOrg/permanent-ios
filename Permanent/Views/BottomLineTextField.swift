//
//  BottomLineTextField.swift
//  Permanent
//
//  Created by Gabi Tiplea on 18/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

@IBDesignable
class BottomLineTextField: CustomTextField {
  var contentEdgeInsets: UIEdgeInsets = .zero
  var bottomLine = CALayer()

  override func setup() {
    bottomLine.frame = CGRect(x: 0.0, y: frame.height - 1, width: frame.width, height: 1.0)
    bottomLine.backgroundColor = UIColor.white.cgColor
    borderStyle = UITextField.BorderStyle.none
    layer.addSublayer(bottomLine)
    layer.masksToBounds = true
    textColor = .white

    attributedPlaceholder = NSAttributedString(string: attributedPlaceholder?.string ?? "",
                                               attributes: [NSAttributedString.Key.foregroundColor: UIColor.white])

    contentEdgeInsets = UIEdgeInsets(top: 8,
                                     left: 10,
                                     bottom: 8,
                                     right: 10)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    bottomLine.frame = CGRect(x: 0.0, y: frame.height  - 1, width: frame.width, height: 1)
  }

  override func textRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: contentEdgeInsets)
  }

  override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: contentEdgeInsets)
  }

  override func editingRect(forBounds bounds: CGRect) -> CGRect {
    return bounds.inset(by: contentEdgeInsets)
  }
}
