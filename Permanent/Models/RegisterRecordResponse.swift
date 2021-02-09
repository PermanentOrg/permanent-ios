//
//  RegisterRecordResponse.swift
//  Permanent
//
//  Created by Constantin Georgiu on 08.02.2021.
//

import Foundation

// MARK: - RegisterRecordResponse

struct RegisterRecordResponse: Codable {
    let results: [RegisterRecordResult]?
    let isSuccessful: Bool?
    let actionFailKeys: [JSONAny]?
    let isSystemUp: Bool?
    let systemMessage: String?
    let sessionID: JSONAny?
    let csrf: String?
    let createdDT, updatedDT: JSONAny?

    enum CodingKeys: String, CodingKey {
        case results = "Results"
        case isSuccessful, actionFailKeys, isSystemUp, systemMessage
        case sessionID = "sessionId"
        case csrf, createdDT, updatedDT
    }
}

// MARK: - RegisterRecordResult

struct RegisterRecordResult: Codable {
    let data: [RegisterRecordData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: JSONAny?
}

// MARK: - RegisterRecordData

struct RegisterRecordData: Codable {
    let simpleVO: RegisterRecord?

    enum CodingKeys: String, CodingKey {
        case simpleVO = "SimpleVO"
    }
}

// MARK: - RegisterRecord
struct RegisterRecord: Codable {
    let key: String?
    let value: String?
}
