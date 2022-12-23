//
//  LoginEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

enum CodeVerificationType: String {
    case phone = "type.auth.phone"
    case mfa = "type.auth.mfaValidation"
}


// TODO: See if this type is appropiate.
typealias VerifyCodeCredentials = (email: String, code: String, type: CodeVerificationType)

enum AuthenticationEndpoint {
    /// Verifies if user is authenticated.
    case verifyAuth
    /// Performs a login with an email & password credentials.
    case login(credentials: LoginCredentials)
    /// Verifies the code received on mail or sms.
    case verify(credentials: VerifyCodeCredentials)
    /// Sends an email in order to change the password.
    case forgotPassword(email: String)
    /// Logs out the user.
    case logout
}

extension AuthenticationEndpoint: RequestProtocol {
    var parameters: RequestParameters? {
        switch self {
        case .login(let credentials):
            return loginPayload(for: credentials)
        case .verify(let credentials):
            return verifyPayload(for: credentials)
        case .forgotPassword(let email):
            return forgotPasswordPayload(for: email)
        case .verifyAuth:
            return verifyAuth()

        default:
            return nil
        }
    }

    var requestType: RequestType {
        .data
    }

    var responseType: ResponseType {
        .json
    }

    var path: String {
        switch self {
        case .verifyAuth:
            return "/auth/loggedin"
        case .login:
            return "/auth/login"
        case .verify:
            return "/auth/verify"
        case .forgotPassword:
            return "/auth/sendEmailForgotPassword"
        case .logout:
            return "/auth/logout"
        }
    }

    var method: RequestMethod {
        return .post
    }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        // swiftlint:disable:next unused_setter_value
        set {}
    }
    
    var bodyData: Data? { nil }
    
    var customURL: String? { nil }
}

extension AuthenticationEndpoint {
    func forgotPasswordPayload(for email: String) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [
                        "AccountVO": [
                            "primaryEmail": email
                        ]
                    ]
                ]
            ]
        ]
    }
    
    func loginPayload(for credentials: LoginCredentials) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "primaryEmail": credentials.email
                    ],
                    "AccountPasswordVO": [
                        "password": credentials.password
                    ]
                ]]
            ]
        ]
    }
    
    func verifyPayload(for credentials: VerifyCodeCredentials) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [[
                    "AccountVO": [
                        "primaryEmail": credentials.email
                    ],
                    "AuthVO": [
                        "type": credentials.type.rawValue,
                        "token": credentials.code
                    ]
                ]]
            ]
        ]
    }
    
    func verifyAuth() -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [:]
                ]
            ]
        ]
    }
}
