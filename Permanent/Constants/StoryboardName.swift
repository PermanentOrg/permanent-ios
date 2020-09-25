//
//  StoryboardNames.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
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
    case onboarding
    case verificationCode

    var identifier: String {
        switch self {
        case .verificationCode:
            return "VerificationCode"
        default:
            return self.rawValue.capitalized
        }
    }
}
