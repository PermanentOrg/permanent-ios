//
//  Constants.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//

import UIKit

typealias ButtonAction = () -> Void
typealias CellButtonTapAction = (UITableViewCell) -> Void

struct Text {
    static var style = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!, TextStyle.calculateSpacing(fontSize: CGFloat(20), lineHeight: CGFloat(27)), NSTextAlignment.center)
    static var style2 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.center)
    static let style3 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 18)!, TextStyle.calculateSpacing(fontSize: CGFloat(18), lineHeight: CGFloat(24)), NSTextAlignment.natural)
    static let style4 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.natural)
    static let style5 = TextStyle(UIFont(name: "OpenSans-Regular", size: 14)!, TextStyle.calculateSpacing(fontSize: CGFloat(14), lineHeight: CGFloat(20)), NSTextAlignment.natural)
    static let style6 = TextStyle(UIFont(name: "OpenSans-Italic", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.center)
    static let style7 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.natural)
    static let style8 = TextStyle(UIFont(name: "OpenSans-Regular", size: 14)!, TextStyle.calculateSpacing(fontSize: CGFloat(14), lineHeight: CGFloat(19)), NSTextAlignment.natural)
    static let style9 = TextStyle(UIFont(name: "OpenSans-Bold", size: 18)!, TextStyle.calculateSpacing(fontSize: CGFloat(18), lineHeight: CGFloat(24)), NSTextAlignment.natural)
    static let style10 = TextStyle(UIFont(name: "OpenSans-Bold", size: 18)!, TextStyle.calculateSpacing(fontSize: CGFloat(18), lineHeight: CGFloat(45)), NSTextAlignment.natural)
    static let style11 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 14)!, TextStyle.calculateSpacing(fontSize: CGFloat(14), lineHeight: CGFloat(19)), NSTextAlignment.natural)
    static var style12 = TextStyle(UIFont(name: "OpenSans-Regular", size: 12)!, TextStyle.calculateSpacing(fontSize: CGFloat(12), lineHeight: CGFloat(17)), NSTextAlignment.center)
    static let style13 = TextStyle(UIFont(name: "OpenSans-Regular", size: 16)!, TextStyle.calculateSpacing(fontSize: CGFloat(16), lineHeight: CGFloat(22)), NSTextAlignment.center)
    static var style14 = TextStyle(UIFont(name: "OpenSans-Bold", size: 20)!, TextStyle.calculateSpacing(fontSize: CGFloat(20), lineHeight: CGFloat(27)), NSTextAlignment.center)
    static let style15 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 14)!, TextStyle.calculateSpacing(fontSize: CGFloat(14), lineHeight: CGFloat(19)), NSTextAlignment.natural)
    static let style16 = TextStyle(UIFont(name: "OpenSans-SemiBold", size: 13)!, TextStyle.calculateSpacing(fontSize: CGFloat(13), lineHeight: CGFloat(18)), NSTextAlignment.natural)
    static let style17 = TextStyle(UIFont(name: "OpenSans-Bold", size: 14)!, TextStyle.calculateSpacing(fontSize: CGFloat(14), lineHeight: CGFloat(19)), NSTextAlignment.natural)
}

struct Constants {
    struct API {
        struct FileType {}
    }

    struct Design {}
    struct URL {}
    struct Keys {
        struct StorageKeys {}
    }

    // TODO: Move these to String
    static let onboardingTextBold = [
        "Share your most cherished \nmemories with total control.",
        "Preserve your most important \ndocuments with peace of mind.",
        "We will never mine your data, \nclaim your copyright or invade \nyour privacy.",
    ]
    static let onboardingTextNormal = [
        "Easily create links to privately shared \ncontent that limit how many people can \naccess the content or for how long.",
        "We are the most comprehensive consumer \ndigital preservation platform available today.",
        "We are backed by mission-driven \ncultural heritage nonprofit dedicated to \nthe public good.",
    ]
    static let onboardingBottomButtonText = [
        "Next",
        "Next",
        "Get Started",
    ]
    static let onboardingPageImage = ["1", "2", "3"]
}

extension Constants.Design {
    static let customButtonHeight: CGFloat = 40
    static let customButtonCornerRadius: CGFloat = 20
    static let actionButtonRadius: CGFloat = 4
}

extension Constants.API {
    static let apiKey = "5aef7dd1f32e0d9ca57290e3c82b59db"

    static let TYPE_AUTH_CREATED_ACCOUNT_EMAIL = "type.auth.created_account_email"
    static let TYPE_AUTH_CREATED_ACCOUNT_TEXT = "type.auth.created_account_text"
    static let TYPE_AUTH_EMAIL = "type.auth.email"
    static let TYPE_AUTH_KEEP_LOGGED_IN = "type.auth.keep_logged_in"
    static let TYPE_AUTH_PASSWORD = "type.auth.password"
    static let TYPE_AUTH_PERM_SESSION = "type.auth.perm_session"
    static let TYPE_AUTH_PHONE = "type.auth.phone"
    static let TYPE_AUTH_REMEMBER_ME = "type.auth.remember_me"
    static let TYPE_AUTH_SESSION = "type.auth.session"
    static let TYPE_AUTH_SIGNUP = "type.auth.signup"
    static let TYPE_AUTH_VAULT = "type.auth.vault"
    static let TYPE_AUTH_MFA = "type.auth.mfa"
    static let TYPE_AUTH_MFAVALIDATION = "type.auth.mfaValidation"
}

extension Constants.API.FileType {
    static let MY_FILES_FOLDER = "My Files"

    static let TYPE_FOLDER_ROOT_PRIVATE = "type.folder.root.private"
    static let TYPE_FOLDER_ROOT_PUBLIC = "type.folder.root.public"
    static let TYPE_FOLDER_PRIVATE = "type.folder.private"
    static let TYPE_RECORD_IMAGE = "type.record.image"
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
    static let uploadFilesKey = "uploadFilesKey"
}
