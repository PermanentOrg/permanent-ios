//
//  ForgotPasswordResponse.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.01.2023.
//

import Foundation

// MARK: - ForgotPasswordResponse
struct ForgotPasswordResponse: Codable {
    let results: [ForgotPasswordResult]?
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

struct ForgotPasswordResult: Codable {
    let data: [JSONAny]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: JSONAny?
}

