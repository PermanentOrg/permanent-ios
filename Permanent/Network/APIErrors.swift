//
//  APIErrors.swift
//  Permanent
//
//  Created by Adrian Creteanu on 01/10/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import Foundation

enum LoginError: String {
    case mfaToken = "warning.auth.mfaToken"
    case unknown = "warning.signin.unknown"

    var description: String {
        switch self {
        case .mfaToken:
            return Translations.MFARequired
        case .unknown:
            return Translations.incorrectCredentials
        }
    }
}

enum VerifyCodeError: String {
    case tokenExpired = "warning.auth.token_expired"
    case tokenIncorrect = "warning.auth.token_does_not_match"

    var description: String {
        switch self {
        case .tokenExpired:
            return Translations.tokenExpired
        case .tokenIncorrect:
            return Translations.tokenIncorrect
        }
    }
}

enum SignUpError: String {
    case duplicateEmail = "warning.registration.duplicate_email"

    var description: String {
        switch self {
        case .duplicateEmail:
            return Translations.emailAlreadyUsed
        }
    }
}

enum AccountUpdateError: String {
    case phoneInvalid = "warning.validation.phone"

    var description: String {
        switch self {
        case .phoneInvalid:
            return Translations.invalidPhone
        }
    }
}
