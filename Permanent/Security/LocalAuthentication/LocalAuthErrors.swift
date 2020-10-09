//
//  LocalAuthErrors.swift
//  Permanent
//
//  Created by Adrian Creteanu on 07/10/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import LocalAuthentication.LAError

struct LocalAuthErrors {
    static let unknownError = PermanentError(statusCode: -4000, errorDescription: Translations.authenticationFailed)
    static let localHardwareUnavailableError = PermanentError(statusCode: -4001, errorDescription: Translations.hardwareUnavailable)
    static let timeOutError = PermanentError(statusCode: -4002, errorDescription: Translations.authenticationTimedOut)
    static let notEnroledError = PermanentError(statusCode: -4003, errorDescription: Translations.authenticationNotEnrolled)
    static let contextNotSetError = PermanentError(statusCode: -4004, errorDescription: Translations.authenticationContextNotSet)
    static let applicationCanceledError = PermanentError(statusCode: -4005, errorDescription: Translations.authenticationCancelled)
    static let notInteractiveError = PermanentError(statusCode: -4005, errorDescription: Translations.authenticationInteractionFailed)
    static let biometryLockoutError = PermanentError(statusCode: -4006, errorDescription: Translations.authenticationLocked)

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
