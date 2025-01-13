//
//  APIErrors.swift
//  Permanent
//
//  Created by Adrian Creteanu on 01/10/2020.
//

import Foundation

enum LoginError: String {
    case mfaToken = "warning.auth.mfaToken"
    case unknown = "warning.signin.unknown"

    var description: String {
        switch self {
        case .mfaToken:
            return .MFARequired
            
        case .unknown:
            return .incorrectCredentials
        }
    }
}

enum VerifyCodeError: String {
    case tokenExpired = "warning.auth.token_expired"
    case tokenIncorrect = "warning.auth.token_does_not_match"

    var description: String {
        switch self {
        case .tokenExpired:
            return .tokenExpired
            
        case .tokenIncorrect:
            return .tokenIncorrect
        }
    }
}

enum SignUpError: String {
    case duplicateEmail = "warning.registration.duplicate_email"

    var description: String {
        switch self {
        case .duplicateEmail:
            return .emailAlreadyUsed
        }
    }
}

enum AccountUpdateError: String {
    case phoneInvalid = "warning.validation.phone"
    case nameFieldIsEmpty = "error.empty.name"
    case dataIsNotModified = "warning.same.data"
    case emailIsEmpty = "warning.validation.empty"
    case emailIsNotValid = "error.invalid.email"

    var description: String {
        switch self {
        case .phoneInvalid:
            return .invalidPhone
            
        case .nameFieldIsEmpty:
            return .emptyNameField
            
        case .dataIsNotModified:
            return .noDataModification
            
        case .emailIsEmpty:
            return .emailFieldIsEmpty
            
        case .emailIsNotValid:
            return .emailIsNotValid
        }
    }
}

enum PasswordChangeError: String {
    case incorrectOldPassword = "warning.auth.bad_old_password"
    case lowPasswordComplexity = "warning.registration.password_complexity"
    case passwordMatchError = "warning.registration.password_match"
    
    var description: String {
        switch self {
        case .incorrectOldPassword:
            return .incorrectOldPassword
            
        case .lowPasswordComplexity:
            return .lowPasswordComplexity
            
        case .passwordMatchError:
            return .passwordMatchError
        }
    }
}

enum MembersOperationsError: String {
    case ownerAccountPending = "error.pr.pending_owner"
    case emailNotValid = "warning.archive.no_email_found"
    case duplicateAccount = "error.pr.duplicate_share"
    
    var description: String {
        switch self {
        case .ownerAccountPending:
            return "There is already a pending owner for this Permanent Archive".localized()
            
        case .emailNotValid:
            return "No account found for the inserted email".localized()
            
        case .duplicateAccount:
            return "This account already has access to the Permanent Archive".localized()
            
        default:
            return .errorMessage
        }
    }
}

enum ShareOperationsError: String {
    case noShareSelf = "warning.share.no_share_self"
    
    var description: String {
        switch self {
        case .noShareSelf:
            return "You cannot share an item with yourself".localized()
            
        default:
            return .errorMessage
        }
    }
}
