//
//  LocalAuthErrors.swift
//  Permanent
//
//  Created by Adrian Creteanu on 07/10/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import LocalAuthentication.LAError

struct LocalAuthErrors {
    static let unknownError = PermanentError(statusCode: -4000, errorDescription: "Local authentication failed.")
    static let localHardwareUnavailableError = PermanentError(statusCode: -4001, errorDescription: "Hardware unavailable for local authentication")
    static let timeOutError = PermanentError(statusCode: -4002, errorDescription: "Local authentication timed out.")
    static let localHardwareNotPresentError = PermanentError(statusCode: -4003, errorDescription: "Hardware doesn't exist for local authentication")
    static let notEnroledError = PermanentError(statusCode: -4004, errorDescription: "Local authentication not enroled")
    static let contextNotSetError = PermanentError(statusCode: -4005, errorDescription: "Context not set for local authentication")
    static let applicationCanceledError = PermanentError(statusCode: -4006, errorDescription: "Authentication was cancelled by application")
    static let notInteractiveError = PermanentError(statusCode: -4007, errorDescription: "Authentication failed because interaction is disabled")
    static let biometryLockoutError = PermanentError(statusCode: -4008, errorDescription: "Biometry is now locked because of too many failed attempts. Passcode is required to unlock biometry")
    
    static func extractAuthError(errorCode: Int?) -> PermanentError? {
        guard let errorCode = errorCode else {
            return nil
        }

        var error = LocalAuthErrors.unknownError

        switch errorCode {
        case LAError.authenticationFailed.rawValue:
            error = LocalAuthErrors.unknownError
        case LAError.appCancel.rawValue:
            error = LocalAuthErrors.applicationCanceledError
        case LAError.invalidContext.rawValue:
            error = LocalAuthErrors.contextNotSetError
        case LAError.notInteractive.rawValue:
            error = LocalAuthErrors.notInteractiveError
        case LAError.passcodeNotSet.rawValue:
            error = LocalAuthErrors.notEnroledError
        case LAError.systemCancel.rawValue:
            break
        case LAError.userCancel.rawValue:
            break
        case LAError.userFallback.rawValue:
            break
        case LAError.biometryNotAvailable.rawValue:
            error = LocalAuthErrors.localHardwareUnavailableError
        case LAError.biometryLockout.rawValue:
            error = LocalAuthErrors.biometryLockoutError
        case LAError.biometryNotEnrolled.rawValue:
            error = LocalAuthErrors.notEnroledError
        default:
            error = LocalAuthErrors.unknownError
        }

        return error
    }
    
    
}
