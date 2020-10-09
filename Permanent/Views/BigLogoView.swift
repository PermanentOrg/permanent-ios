//
//  BigLogoView.swift
//  Permanent
//
//  Created by Gabi Tiplea on 18/08/2020.
//

import UIKit

@IBDesignable
final class BigLogoView: CustomView {
  @IBOutlet var contentView: UIView!
  @IBOutlet weak var logoLabel: UILabel!

  override func setup() {
    let bundle = Bundle.init(for: type(of: self))
    bundle.loadNibNamed("BigLogoView", owner: self, options: nil)
    addSubview(contentView)
    contentView.backgroundColor = .clear
    logoLabel.font = Text.style.font
    logoLabel.textColor = UIColor.tangerine
    contentView.frame = self.bounds
    contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
  }

  override var intrinsicContentSize: CGSize {
     return CGSize(width: 200, height: 100)
  }
}
