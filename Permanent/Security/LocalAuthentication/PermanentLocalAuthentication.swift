//
//  PermanentLocalAuthentication.swift
//  Permanent
//
//  Created by Adrian Creteanu on 06/10/2020.
//

import Foundation
import LocalAuthentication

class PermanentLocalAuthentication: NSObject {
    static let instance = PermanentLocalAuthentication(policy: .deviceOwnerAuthentication)
    var currentContext: LAContext
    var policy: LAPolicy

    private init(policy: LAPolicy) {
        self.policy = policy
        self.currentContext = LAContext()
        super.init()
    }
}

extension PermanentLocalAuthentication: ILocalAuthentication {
    func authenticate(onSuccess: LocalAuthSuccessCallback?, onFailure: LocalAuthFailureCallback?) {
        currentContext.localizedCancelTitle = Translations.cancel
        currentContext.localizedFallbackTitle = Translations.usePasscode

        let authStatus = canAuthenticate()

        if authStatus.canAuthenticate {
            currentContext.evaluatePolicy(policy, localizedReason: Translations.biometricsReason, reply: { success, error in
                if success {
                    onSuccess?()
                } else {
                    guard let error = error else {
                        onFailure?(LocalAuthErrors.unknownError)
                        return
                    }

                    let authError = LocalAuthErrors.extractAuthError(errorCode: (error as NSError).code) ?? LocalAuthErrors.unknownError
                    onFailure?(authError)
                }
            })

        } else {
            let error = authStatus.error ?? LocalAuthErrors.unknownError
            onFailure?(error)
        }
    }

    func canAuthenticate() -> LocalAuthStatus {
        var evalError: NSError?
        let canEvaluatePolicy = currentContext.canEvaluatePolicy(policy, error: &evalError)
        let error = LocalAuthErrors.extractAuthError(errorCode: evalError?.code)

        return (canEvaluatePolicy, error)
    }

    func cancelAuthentication() {
        currentContext.invalidate()
    }
}
