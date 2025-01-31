//
//  AuthBannerMessage.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.09.2024.

enum AuthBannerMessage {
    case invalidData
    case invalidCredentials
    case invalidPassword
    case emptyPinCode
    case invalidPinCode
    case resentCodeError
    case codeExpiredError
    case successResendCode
    case successPasswordConfirmed
    case error
    case none
    
    var text: String {
        switch self {
        case .invalidData:
            return "The entered data is invalid"
        case .invalidCredentials:
            return "Incorrect email or password."
        case .invalidPassword:
            return "Incorrect password."
        case .emptyPinCode:
            return "The 4-digit code is incorrect."
        case .invalidPinCode:
            return "The 4-digit code is incorrect."
        case .resentCodeError:
            return "Resent code error"
        case .codeExpiredError:
            return "The code expired."
        case .successResendCode:
            return "The code was resent."
        case .successPasswordConfirmed:
            return "Password confirmed"
        case .error:
            return .errorMessage
        case .none:
            return ""
        }
    }
}
