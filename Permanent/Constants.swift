//
//  Constants.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

struct Text {
  static var style = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!, TextStyle.calculateSpacing(fontSize: CGFloat(20),lineHeight: CGFloat(45)), NSTextAlignment.center)
  static let style14 = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!,TextStyle.calculateSpacing(fontSize: CGFloat(20),lineHeight: CGFloat(45)) , NSTextAlignment.center)
  static let style10 = TextStyle(UIFont(name: "OpenSans-Bold", size: 18)!,TextStyle.calculateSpacing(fontSize: CGFloat(18),lineHeight: CGFloat(45)) , NSTextAlignment.natural)
  static let style9 = TextStyle(UIFont(name: "OpenSans-Bold", size: 18)!,TextStyle.calculateSpacing(fontSize: CGFloat(18),lineHeight: CGFloat(24)) , NSTextAlignment.natural)
  static let style3 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 18)!,TextStyle.calculateSpacing(fontSize: CGFloat(18),lineHeight: CGFloat(24)) , NSTextAlignment.natural)
  static let style4 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,TextStyle.calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.natural)
  static var style2 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,TextStyle.calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.center)
  static let style13 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,TextStyle.calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.center)
  static let style7 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!,TextStyle.calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.natural)
  static let style6 = TextStyle(UIFont(name: "OpenSans-Italic", size: 16)!,TextStyle.calculateSpacing(fontSize: CGFloat(16),lineHeight: CGFloat(22)) , NSTextAlignment.center)
  static let style11 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 14)!,TextStyle.calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(19)) , NSTextAlignment.natural)
  static let style15 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 14)!,TextStyle.calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(19)) , NSTextAlignment.natural)
  static let style5 = TextStyle(UIFont(name: "OpenSans-Regular", size: 14)!,TextStyle.calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(20)) , NSTextAlignment.natural)
  static let style8 = TextStyle(UIFont(name: "OpenSans-Regular", size: 14)!,TextStyle.calculateSpacing(fontSize: CGFloat(14),lineHeight: CGFloat(19)) , NSTextAlignment.natural)
  static let style12 = TextStyle(UIFont(name: "OpenSans-Regular", size: 17)!,TextStyle.calculateSpacing(fontSize: CGFloat(17),lineHeight: CGFloat(12)) , NSTextAlignment.center)
}

struct Constants {
  static let customButtonHeight: CGFloat = 45
  static let customButtonCornerRadius: CGFloat = 20
  static let onboardingTextBold = [
    "Share your most cherished \nmemories with total control.",
    "Preserve your most important \ndocuments with peace of mind.",
    "We will never mine your data, \nclaim your copyright or invade\n your privacy."]
  static let onboardingTextNormal = [
    "Easily create links to privately shared \n content that limit how many people can\n access the content or for how long.",
    "We are the most comprehensive consumer\n digital preservation platform available today.",
    "We are backed by mission-driven\n cultural heritage nonprofit dedicated to\n the public good."]
  static let onboardingBottomButtonText = [
  "Next",
  "Next",
  "Get Started"]
  static let onboardingPageImage = ["1","2","3"]
}
