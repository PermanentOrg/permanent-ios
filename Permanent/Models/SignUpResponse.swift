//
//  SignUpResponse.swift
//  Permanent
//
//  Created by Adrian Creteanu on 30/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import Foundation

struct SignUpResponse: Codable {
    let results: [SignUpResult]?
    let isSuccessful: Bool?
    let actionFailKeys: [JSONAny]?
    let isSystemUp: Bool?
    let systemMessage: String?
    let sessionID: JSONNull?
    let csrf: String?
    let createdDT, updatedDT: String?
    
    enum CodingKeys: String, CodingKey {
        case results = "Results"
        case isSuccessful, actionFailKeys, isSystemUp, systemMessage
        case sessionID = "sessionId"
        case csrf, createdDT, updatedDT
    }
}

// MARK: - LoginResult
struct SignUpResult: Codable {
    let data: [SignUpData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: String?
}

struct SignUpData: Codable {
    let accountVO: AccountVO?

    enum CodingKeys: String, CodingKey {
        case accountVO = "AccountVO"
    }
}
