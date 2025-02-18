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
typealias Send2FAEnableCodeParameters = (method: String, value: String)
typealias Enable2FAParameters = (method: String, value: String, code: String)
typealias Send2FADisableCodeParameters = (method: String, code: String?)

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
    /// Gets user two factor authentication methods
    case getIDPUser
    /// Send code for enable 2FA
    case send2FAEnableCode(parameters: Send2FAEnableCodeParameters)
    /// Enable 2FA
    case enable2FA(parameters: Enable2FAParameters)
    /// Send code to delete 2FA method
    case send2FADisableCode(parameters: Send2FADisableCodeParameters)
    /// Disable 2FA
    case disable2FA(parameters: Send2FADisableCodeParameters)
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
        case .send2FAEnableCode:
            return ""
        case .enable2FA:
            return ""
        case .send2FADisableCode:
            return ""
        case .disable2FA:
            return ""
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
    
    var bodyData: Data? {
        switch self {
        case .send2FAEnableCode(let parameters):
            return try? JSONEncoder().encode(["method": parameters.method, "value": parameters.value])
        case .enable2FA(let parameters):
            return try? JSONEncoder().encode(["method": parameters.method, "value": parameters.value, "code": parameters.code])
        case .send2FADisableCode(let parameters):
            let method = parameters.method == "93ZC" ? "" : "GXT5"
            return try? JSONEncoder().encode(["methodId": method])
        case .disable2FA(let parameters):
            guard let code = parameters.code else { return nil }
            let method = parameters.method == "93ZC" ? "" : "GXT5"
            return try? JSONEncoder().encode(["methodId": method, "code": code])
        default:
            return nil
        }
    }
    
    var customURL: String? {
        let endpointPath = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .getIDPUser:
            return "\(endpointPath)api/v2/idpuser"
        case .send2FAEnableCode:
            return "\(endpointPath)api/v2/idpuser/send-enable-code"
        case .enable2FA:
            return "\(endpointPath)api/v2/idpuser/enable-two-factor"
        case .send2FADisableCode:
            return "\(endpointPath)api/v2/idpuser/disable-two-factor"
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
    
    func send2FAEnableCode(using parameters: Send2FAEnableCodeParameters) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [:]
                ]
            ]
        ]
    }
    
    func enable2FA(using parameters: Enable2FAParameters) -> RequestParameters {
        return [
            "RequestVO": [
                "data": [
                    [:]
                ]
            ]
        ]
    }
}
