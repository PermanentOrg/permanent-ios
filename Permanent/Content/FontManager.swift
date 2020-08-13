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
}

var textStyle = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!, calculateSpacing(fontSize: CGFloat(20),lineHeight: CGFloat(45)), NSTextAlignment.center)
var textStyle14 = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!,calculateSpacing(fontSize: CGFloat(20),lineHeight: CGFloat(45)) , NSTextAlignment.center)
var textStyle10 = TextStyle(UIFont(name: "OpenSans-Bold", size: 18)!,calculateSpacing(fontSize: CGFloat(18),lineHeight: CGFloat(45)) , NSTextAlignment.natural)
var textStyle9 = TextStyle(UIFont(name: "OpenSans-Bold", size: 18)!,calculateSpacing(fontSize: CGFloat(18),lineHeight: CGFloat(24)) , NSTextAlignment.natural)
var textStyle3 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 18)!,calculateSpacing(fontSize: CGFloat(18),lineHeight: CGFloat(24)) , NSTextAlignment.natural)
var textStyle4 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.natural)
var textStyle2 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.center)
var textStyle13 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.center)
var textStyle7 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.natural)
var textStyle6 = TextStyle(UIFont(name: "OpenSans-Italic", size: 16)!,calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.center)
var textStyle11 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 14)!,calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(19)) , NSTextAlignment.natural)
var textStyle15 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 14)!,calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(19)) , NSTextAlignment.natural)
var textStyle5 = TextStyle(UIFont(name: "OpenSans-Regular", size: 14)!,calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(20)) , NSTextAlignment.natural)
var textStyle8 = TextStyle(UIFont(name: "OpenSans-Regular", size: 14)!,calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(19)) , NSTextAlignment.natural)
var textStyle12 = TextStyle(UIFont(name: "OpenSans-Regular", size: 17)!,calculateSpacing(fontSize: CGFloat(17),lineHeight: CGFloat(12)) , NSTextAlignment.center)

//MARK: - Calculate line spacing

func calculateSpacing(fontSize: CGFloat, lineHeight: CGFloat) -> CGFloat {
  (lineHeight - fontSize) / 2
}
// Usage: setTextWithLineSpacing(myUILabel,text:"Hello",lineSpacing:20)
func setTextWithLineSpacing(label:UILabel,text:String,lineSpacing:CGFloat)
{
    let paragraphStyle = NSMutableParagraphStyle()
    paragraphStyle.lineSpacing = lineSpacing

    let attrString = NSMutableAttributedString(string: text)
    attrString.addAttribute(NSAttributedString.Key.paragraphStyle, value:paragraphStyle, range:NSMakeRange(0, attrString.length))

    label.attributedText = attrString
}

