//
//  LoginResponse.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23/09/2020.
//

import Foundation

// MARK: - LoginResponse
struct LoginResponse: Codable {
    let results: [LoginResult]?
    let isSuccessful: Bool?
    let actionFailKeys: [JSONAny]?
    let isSystemUp: Bool?
    let systemMessage: String?
    let sessionID: JSONAny?
    let createdDT, updatedDT: String?
    
    enum CodingKeys: String, CodingKey {
        case results = "Results"
        case isSuccessful, actionFailKeys, isSystemUp, systemMessage
        case sessionID = "sessionId"
        case createdDT, updatedDT
    }
}

// MARK: - LoginResult
struct LoginResult: Codable {
    let data: [LoginData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: String?
}

struct LoginData: Codable {
    let accountVO: AccountVOData?
    let archiveVO: ArchiveVOData?

    enum CodingKeys: String, CodingKey {
        case accountVO = "AccountVO"
        case archiveVO = "ArchiveVO"
    }
}

