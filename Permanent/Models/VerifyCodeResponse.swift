//
//  VerifyCodeResponse.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import Foundation

// MARK: - VerifyCodeResponse
struct VerifyResponse: Codable {
    let results: [VerifyResult]?
    let isSuccessful: Bool?
    let actionFailKeys: [JSONAny]?
    let isSystemUp: Bool?
    let systemMessage: String?
    let sessionID: JSONNull?
    let csrf: String?
    let createdDT, updatedDT: JSONNull?

    enum CodingKeys: String, CodingKey {
        case results = "Results"
        case isSuccessful, actionFailKeys, isSystemUp, systemMessage
        case sessionID = "sessionId"
        case csrf, createdDT, updatedDT
    }
}

struct VerifyResult: Codable {
    let data: [VerifyData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: JSONNull?
}

// MARK: - Datum
struct VerifyData: Codable {
    let accountVO: AccountVO?

    enum CodingKeys: String, CodingKey {
        case accountVO = "AccountVO"
    }
}

