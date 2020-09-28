//
//  AuthResponse.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import Foundation

// MARK: - AuthResponse
struct AuthResponse: Codable {
    let results: [AuthResult]?
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

// MARK: - Result
struct AuthResult: Codable {
    let data: [AuthData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: JSONNull?
}

// MARK: - Datum
struct AuthData: Codable {
    let simpleVO: SimpleVO?

    enum CodingKeys: String, CodingKey {
        case simpleVO = "SimpleVO"
    }
}

// MARK: - SimpleVO
struct SimpleVO: Codable {
    let key: String?
    let value: Bool?
    let createdDT, updatedDT: String?
}
