//
//  Constants.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

struct Text {
  static let style = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!, TextStyle.calculateSpacing(fontSize: CGFloat(20),lineHeight: CGFloat(45)), NSTextAlignment.center)
  static let style14 = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!,TextStyle.calculateSpacing(fontSize: CGFloat(20),lineHeight: CGFloat(45)) , NSTextAlignment.center)
  static let style10 = TextStyle(UIFont(name: "OpenSans-Bold", size: 18)!,TextStyle.calculateSpacing(fontSize: CGFloat(18),lineHeight: CGFloat(45)) , NSTextAlignment.natural)
  static let style9 = TextStyle(UIFont(name: "OpenSans-Bold", size: 18)!,TextStyle.calculateSpacing(fontSize: CGFloat(18),lineHeight: CGFloat(24)) , NSTextAlignment.natural)
  static let style3 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 18)!,TextStyle.calculateSpacing(fontSize: CGFloat(18),lineHeight: CGFloat(24)) , NSTextAlignment.natural)
  static let style4 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,TextStyle.calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.natural)
  static let style2 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,TextStyle.calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.center)
  static let style13 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,TextStyle.calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.center)
  static let style7 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,TextStyle.calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.natural)
  static let style6 = TextStyle(UIFont(name: "OpenSans-Italic", size: 16)!,TextStyle.calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.center)
  static let style11 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 14)!,TextStyle.calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(19)) , NSTextAlignment.natural)
  static let style15 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 14)!,TextStyle.calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(19)) , NSTextAlignment.natural)
  static let style5 = TextStyle(UIFont(name: "OpenSans-Regular", size: 14)!,TextStyle.calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(20)) , NSTextAlignment.natural)
  static let style8 = TextStyle(UIFont(name: "OpenSans-Regular", size: 14)!,TextStyle.calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(19)) , NSTextAlignment.natural)
  static let style12 = TextStyle(UIFont(name: "OpenSans-Regular", size: 12)!,TextStyle.calculateSpacing(fontSize: CGFloat(17),lineHeight: CGFloat(12)) , NSTextAlignment.center)
}

struct Constants {
  static let customButtonHeight: CGFloat = 45
  static let customButtonCornerRadius: CGFloat = 20
}
