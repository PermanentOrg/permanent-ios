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

    var name: String {
        return self.rawValue.capitalized
    }
}

enum ViewControllerIdentifier: String {
    case main
    case login
    case signUp
    case onboarding
    case verificationCode
    case termsConditions
    case twoStepVerification
    case biometrics
    case fabActionSheet

    var identifier: String {
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
        default:
            return self.rawValue.capitalized
        }
    }
}
