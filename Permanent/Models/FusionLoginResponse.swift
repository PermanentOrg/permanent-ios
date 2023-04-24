//
//  FusionLoginResponse.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.12.2022.
//

import Foundation

class FusionLoginResponse: Model, Equatable {
    static func == (lhs: FusionLoginResponse, rhs: FusionLoginResponse) -> Bool {
        return lhs.token == rhs.token
    }
    
    let token: String?
    let tokenExpirationInstant: Int?
    let user: Dictionary<String, JSONAny>?
    let methods: [MultiFactorParameters]?
    let twoFactorId : String?
    
    enum CodingKeys: String, CodingKey {
        case token, tokenExpirationInstant, user, methods, twoFactorId
    }
}

struct MultiFactorParameters: Model {
    let email: String?
    let id : String?
    let lastUsed : Bool?
    let method : String?
    
    enum CodingKeys: String, CodingKey {
        case email, id, lastUsed, method
    }
}
