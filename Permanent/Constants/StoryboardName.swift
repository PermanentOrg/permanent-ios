//
//  StoryboardNames.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23/09/2020.
//

import Foundation

enum StoryboardName: String {
    case main
    case authentication
    case launch
    case onboarding
    case welcomePage
    case members
    case share
    case accountInfo
    case invitations
    case settings
    case archives
    
    var name: String {
        return self.rawValue.capitalized
    }
}

enum ViewControllerId: String {
    case main
    case login
    case signUp
    case onboarding
    case welcomePage
    case verificationCode
    case termsConditions
    case twoStepVerification
    case biometrics
    case fabActionSheet
    case sideMenu
    case rightSideMenu
    case share
    case shares
    case members
    case manageLink
    case accountInfo
    case accountDelete
    case accountSettings
    case sharePreview
    case invitations
    case filePreview
    case fileDetailsOnTap
    case locationSetOnTap
    case tagDetails
    case archives

    var value: String {
        switch self {
        case .signUp:
            return "SignUp"
        case .verificationCode:
            return "VerificationCode"
        case .termsConditions:
            return "TermsConditions"
        case .twoStepVerification:
            return "TwoStepVerification"
        case .fabActionSheet:
            return "FABActionSheet"
        case .sideMenu:
            return "SideMenu"
        case .rightSideMenu:
            return "RightSideMenu"
        case .manageLink:
            return "ManageLink"
        case .accountInfo:
            return "AccountInfo"
        case .accountDelete:
            return "AccountDelete"
        case .accountSettings:
            return "AccountSettings"
        case .sharePreview:
            return "SharePreview"
        case .filePreview:
            return "WebViewer"
        case .fileDetailsOnTap:
            return "FileDetailsOnTap"
        case .locationSetOnTap:
            return "LocationSetOnTap"
        case .tagDetails:
            return "TagDetails"
        case .welcomePage:
            return "WelcomePage"
        default:
            return self.rawValue.capitalized
        }
    }
}
