//
//  CustomButton.swift
//  Permanent
//
//  Created by Gabi Tiplea on 17/08/2020.
//

import UIKit

class CustomButton: UIButton {
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
