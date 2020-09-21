//
//  LoginEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation

// TODO: See if this type is appropiate.
typealias LoginCredentials = (email: String, password: String)

enum LoginEndpoint {
    /// Verifies if user is authenticated.
    case verifyAuth
    /// Performs a login with an email & password credentials.
    case login(credentials: LoginCredentials)
}

extension LoginEndpoint: RequestProtocol {
    var headers: RequestHeaders? {
        return nil
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .login:
            return [:]
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
        }
    }
    
    var method: RequestMethod {
        return .post
    }
}
