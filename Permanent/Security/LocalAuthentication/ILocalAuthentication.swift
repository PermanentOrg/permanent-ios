//
//  ILocalAuthentication.swift
//  Permanent
//
//  Created by Adrian Creteanu on 06/10/2020.
//

import Foundation

typealias LocalAuthSuccessCallback = () -> Void
typealias LocalAuthFailureCallback = (PermanentError) -> Void
typealias LocalAuthStatus = (canAuthenticate: Bool, error: PermanentError?)

protocol ILocalAuthentication {
    func cancelAuthentication()
    func canAuthenticate() -> LocalAuthStatus
    func authenticate(onSuccess: LocalAuthSuccessCallback?, onFailure: LocalAuthFailureCallback?)
}
