//
//  AccountEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 30/09/2020.
//

import Foundation

typealias SignUpCredentials = (name: String, loginCredentials: LoginCredentials)

enum AccountEndpoint {
    /// Creates an new user account.
    case signUp(credentials: SignUpCredentials)
    /// Updates user account.
    case update(accountId: String, updateData: UpdateData, csrf: String)
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
        case .update(let id, let data, let csrf):
            return Payloads.update(accountId: id, updateData: data, csrf: csrf)
        }
    }
    
    var method: RequestMethod { .post }
    
    var headers: RequestHeaders? { nil }
    
    var requestType: RequestType { .data }
    
    var responseType: ResponseType { .json }
}
