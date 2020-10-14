//  
//  GetRootResponse.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

// MARK: - GetRootResponse
struct GetRootResponse: Codable {
    let results: [GetRootResult]?
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

// MARK: - Result
struct GetRootResult: Codable {
    let data: [GetRootData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: JSONNull?
}

// MARK: - Datum
struct GetRootData: Codable {
    let folderVO: FolderVO?

    enum CodingKeys: String, CodingKey {
        case folderVO = "FolderVO"
    }
}
