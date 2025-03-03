//
//  BannerBottomMessage.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.02.2025.


enum BannerBottomMessage {
    case invalidData
    case invalidPassword
    case incorrectEmail
    case invalidPhoneNumber
    case emptyPinCode
    case invalidPinCode
    case invalidEmail
    case resentCodeError
    case codeExpiredError
    case successResendCode
    case successCodeSend
    case successPasswordConfirmed
    case successEmailAdded
    case successSmsAdded
    case successEmailDeleted
    case successSmsDeleted
    case error
    case generalError
    case none
    
    var text: String {
        switch self {
        case .invalidData:
            return "The entered data is invalid"
        case .invalidPassword:
            return "Incorrect password."
        case .incorrectEmail:
            return "Incorrect email."
        case .invalidEmail:
            return "Invalid email entered."
        case .invalidPhoneNumber:
            return "Incorrect phone number."
        case .emptyPinCode:
            return "The 4-digit code is incorrect."
        case .invalidPinCode:
            return "The 4-digit code is incorrect."
        case .resentCodeError:
            return "Resent code error"
        case .codeExpiredError:
            return "The code expired."
        case .successCodeSend:
            return "The code was sent."
        case .successResendCode:
            return "The code was resent."
        case .successPasswordConfirmed:
            return "Password confirmed"
        case .successSmsAdded:
            return "SMS verification method was added."
        case .successEmailAdded:
            return "Email verification method was added."
        case .successSmsDeleted:
            return "Text verification was disabled."
        case .successEmailDeleted:
            return "Email verification was disabled."
        case .error:
            return "An error occurred."
        case .generalError:
            return "Something went wrong."
        case .none:
            return ""
        }
    }
    
    var isError: Bool {
        switch self {
        case .successResendCode, .successCodeSend, .successPasswordConfirmed,
             .successEmailAdded, .successSmsAdded, .successEmailDeleted, .successSmsDeleted, .none:
            return false
        case .invalidData, .invalidPassword, .incorrectEmail,
             .invalidPhoneNumber, .emptyPinCode, .invalidPinCode, .invalidEmail,
             .resentCodeError, .codeExpiredError, .error, .generalError:
            return true
        }
    }
} 
