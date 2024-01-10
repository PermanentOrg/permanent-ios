//
//  RedeemVO.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.12.2023.

import Foundation

struct RedeemVO: Model {
    let results: [RedeemResult]?
    let isSuccessful: Bool
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

struct RedeemResult: Codable {
    let data: PromoVO?
    let message: [String]
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: JSONAny?
}

struct PromoVO: Codable {
    let code: String
}
