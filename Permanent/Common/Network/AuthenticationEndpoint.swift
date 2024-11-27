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
typealias CreateCredentials = (name: String, password: String, email: String, phone: String?)

enum AuthenticationEndpoint {
    /// Verifies if user is authenticated.
    case verifyAuth
    /// Performs a login with an email & password credentials.
    case login(credentials: LoginCredentials)
    /// Verifies the code received on mail or sms.
    case verify(credentials: VerifyCodeCredentials)
    /// Sends an email in order to change the password.
    case forgotPassword(email: String)
    /// Creates a user object
    case createCredentials(credentials: CreateCredentials)
    /// Logs out the user.
    case logout
    case getIDPUser
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
        case .createCredentials(let credentials):
            return createCredentialsPayload(for: credentials)
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
        case .getIDPUser:
            return ""
        case .verifyAuth:
            return "/auth/loggedin"
        case .login:
            return "/auth/login"
        case .verify:
            return "/auth/verify"
        case .forgotPassword:
            return "/auth/sendEmailForgotPassword"
        case .createCredentials:
            return "/auth/createCredentials"
        case .logout:
            return "/auth/logout"
        }
    }

    var method: RequestMethod {
        switch self {
        case .getIDPUser:
            return .get
        default:
            return .post
        }
    }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        // swiftlint:disable:next unused_setter_value
        set {}
    }
    
    var bodyData: Data? { nil }
    
    var customURL: String? {
        let endpointPath = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .getIDPUser:
            return "\(endpointPath)api/v2/idpuser"
        default:
            return nil
        }
    }
    
    var headers: RequestHeaders? {
        if method == .post {
            if case .createCredentials(_) = self {
                return [
                    "content-type": "application/json; charset=utf-8",
                    "Request-Version": "2"
                ]
            } else {
                return ["content-type": "application/json; charset=utf-8"]
            }
        } else if case .getIDPUser = self {
            return [
                "content-type": "application/json; charset=utf-8",
                "Request-Version": "2"
            ]
        } else {
            return nil
        }
    }
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
    
    func createCredentialsPayload(for credentials: CreateCredentials) -> RequestParameters {
        return [
            "fullName": credentials.name,
            "password": credentials.password,
            "passwordVerify": credentials.password,
            "primaryEmail": credentials.email,
            "primaryPhone": (credentials.phone ?? NSNull()) as Any
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
