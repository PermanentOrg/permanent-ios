//
//  Constants.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//

import UIKit

struct Text {
    static var style = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!, TextStyle.calculateSpacing(fontSize: CGFloat(20),lineHeight: CGFloat(27)), NSTextAlignment.center)
    static var style14 = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!,TextStyle.calculateSpacing(fontSize: CGFloat(20),lineHeight: CGFloat(27)) , NSTextAlignment.center)
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
    static var style12 = TextStyle(UIFont(name: "OpenSans-Regular", size: 12)!,TextStyle.calculateSpacing(fontSize: CGFloat(12),lineHeight: CGFloat(17)) , NSTextAlignment.center)
}

struct Constants {
    struct API {}
    struct Design {}
    struct URL {}
    struct Keys {
        struct StorageKeys {}
    }
    
    // TODO: Move these to Translations
    static let onboardingTextBold = [
        "Share your most cherished \nmemories with total control.",
        "Preserve your most important \ndocuments with peace of mind.",
        "We will never mine your data, \nclaim your copyright or invade \nyour privacy."]
    static let onboardingTextNormal = [
        "Easily create links to privately shared \ncontent that limit how many people can \naccess the content or for how long.",
        "We are the most comprehensive consumer \ndigital preservation platform available today.",
        "We are backed by mission-driven \ncultural heritage nonprofit dedicated to \nthe public good."]
    static let onboardingBottomButtonText = [
        "Next",
        "Next",
        "Get Started"]
    static let onboardingPageImage = ["1","2","3"]
}

extension Constants.Design {
    static let customButtonHeight: CGFloat = 40
    static let customButtonCornerRadius: CGFloat = 20
}

extension Constants.API {
    static let apiKey = "5aef7dd1f32e0d9ca57290e3c82b59db"
}

extension Constants.URL {
    static let termsConditionsURL = "https://www.permanent.org/privacy-policy/"
}

extension Constants.Keys.StorageKeys {
    static let nameStorageKey = "nameStorageKey"
    static let accountIdStorageKey = "accountIdStorageKey"
    static let emailStorageKey = "emailStorageKey"
    static let csrfStorageKey = "csrfStorageKey"
    static let isNewUserStorageKey = "isNewUser"
}
