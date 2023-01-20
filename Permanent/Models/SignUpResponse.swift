//
//  SignUpResponse.swift
//  Permanent
//
//  Created by Adrian Creteanu on 30/09/2020.
//

import Foundation

struct SignUpResponse: Codable {
    let token: String
    let user: SignUpUser
}

struct SignUpUser: Codable {
    let id: String
    let fullName: String
    let email: String
}
