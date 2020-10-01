//
//  AccountEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 30/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import Foundation

typealias SignUpCredentials = (name: String, loginCredentials: LoginCredentials)

enum AccountEndpoint {
    /// Creates an new user account.
    case signUp(credentials: SignUpCredentials)
    /// Updates user account.
    case update(accountId: String)
}

extension AccountEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .signUp:
            return "/account/post"
        case .update:
            return "/account/update"
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .signUp(let credentials):
            return Payloads.signUpPayload(for: credentials)
        case .update(let id):
            return Payloads.update(accountId: id)
        }
    }
    
    var method: RequestMethod { .post }
    
    var headers: RequestHeaders? { nil }
    
    var requestType: RequestType { .data }
    
    var responseType: ResponseType { .json }
}
