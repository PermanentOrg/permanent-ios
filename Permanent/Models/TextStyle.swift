//
//  FontManager.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit
//MARK: - Font Parts

struct TextStyle {
  let font: UIFont
  let lineHeight: CGFloat
  let alignment: NSTextAlignment
  
  init(_ font: UIFont,_ lineHeight: CGFloat,_ alignment: NSTextAlignment) {
    self.font = font
    self.lineHeight = lineHeight
    self.alignment = alignment
  }

  //MARK: - Calculate line spacing

  static func calculateSpacing(fontSize: CGFloat, lineHeight: CGFloat) -> CGFloat {
    (lineHeight - fontSize) / 2
  }
  // Usage: setTextWithLineSpacing(myUILabel,text:"Hello",lineSpacing:20)
  static func setTextWithLineSpacing(label:UILabel,text:String,lineSpacing:CGFloat)
  {
      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.lineSpacing = lineSpacing

      let attrString = NSMutableAttributedString(string: text)
      attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attrString.length))

      label.attributedText = attrString
  }
}
