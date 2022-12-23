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
    let sessionID: JSONAny?
    let createdDT, updatedDT: JSONAny?

    enum CodingKeys: String, CodingKey {
        case results = "Results"
        case isSuccessful, actionFailKeys, isSystemUp, systemMessage
        case sessionID = "sessionId"
        case createdDT, updatedDT
    }
}

struct VerifyResult: Codable {
    let data: [VerifyData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: JSONAny?
}

// MARK: - Datum
struct VerifyData: Codable {
    let accountVO: AccountVOData?
    let tokenVO: SimpleVOOf<String>?

    enum CodingKeys: String, CodingKey {
        case accountVO = "AccountVO"
        case tokenVO = "AuthSimpleVO"
    }
}

