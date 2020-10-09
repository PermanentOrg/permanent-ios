//
//  CustomTextField.swift
//  Permanent
//
//  Created by Gabi Tiplea on 18/08/2020.
//

import UIKit

class CustomTextField: UITextField {
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setup()
  }

  override func prepareForInterfaceBuilder() {
    super.prepareForInterfaceBuilder()
    setup()
  }

  func setup() {}
}
