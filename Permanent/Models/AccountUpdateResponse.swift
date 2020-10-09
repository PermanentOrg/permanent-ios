//
//  SignUpResponse.swift
//  Permanent
//
//  Created by Adrian Creteanu on 30/09/2020.
//

import Foundation

struct AccountUpdateResponse: Codable {
    let results: [AccountUpdateResult]?
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
struct AccountUpdateResult: Codable {
    let data: [AccountUpdateData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: String?
}

struct AccountUpdateData: Codable {
    let accountVO: AccountUpdateVO?

    enum CodingKeys: String, CodingKey {
        case accountVO = "AccountVO"
    }
}
