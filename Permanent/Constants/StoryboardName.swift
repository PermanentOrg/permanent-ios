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
    case members
    case share
    case accountInfo
    case invitations
    case settings
    
    var name: String {
        return self.rawValue.capitalized
    }
}

enum ViewControllerId: String {
    case main
    case login
    case signUp
    case onboarding
    case verificationCode
    case termsConditions
    case twoStepVerification
    case biometrics
    case fabActionSheet
    case sideMenu
    case share
    case shares
    case members
    case manageLink
    case accountInfo
    case accountSettings
    case sharePreview
    case invitations
    case filePreview
    case fileDetailsOnTap
    case locationSetOnTap
    case tagDetails

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
        case .manageLink:
            return "ManageLink"
        case .accountInfo:
            return "AccountInfo"
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
        default:
            return self.rawValue.capitalized
        }
    }
}
