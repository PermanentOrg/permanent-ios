//
//  StoryboardNames.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import Foundation

enum StoryboardNames {
    case authentication
    case launch
    case onboarding
    
    var name: String {
        switch self {
        case .authentication:
            return "Authentication"
        case .launch:
            return "LaunchScreen"
        case .onboarding:
            return "Onboarding"
        }
    }
}

enum ViewControllerIdentifiers {
    case login
    case onboarding
    case verificationCode
    
    var identifier: String {
        switch self {
        case .login:
            return "Login"
        case .onboarding:
            return "Onboarding"
        case .verificationCode:
            return "VerificationCode"
        }
    }
}
