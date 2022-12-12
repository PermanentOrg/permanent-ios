//
//  LoginEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//

import Foundation

// TODO: See if this type is appropiate.
typealias LoginCredentials = (email: String, password: String)

enum AuthenticationEndpoint {
    /// Verifies if user is authenticated.
    case verifyAuth
    /// Sends an email in order to change the password.
    case forgotPassword(email: String)
    /// Logs out the user.
    case logout
}

extension AuthenticationEndpoint: RequestProtocol {
    var parameters: RequestParameters? {
        switch self {
        case .forgotPassword(let email):
            return Payloads.forgotPasswordPayload(for: email)
            
        case .verifyAuth:
            return Payloads.verifyAuth()

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
