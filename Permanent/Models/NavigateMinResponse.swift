//
//  NavigateMinResponse.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

// MARK: - NavigateMinResponse

struct NavigateMinResponse: Codable {
    let results: [NavigateMinResult]?
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

// MARK: - NavigateMinResult

struct NavigateMinResult: Codable {
    let data: [NavigateMinData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: JSONAny?
}

// MARK: - NavigateMinData

struct NavigateMinData: Codable {
    let folderVO: MinFolderVO?

    enum CodingKeys: String, CodingKey {
        case folderVO = "FolderVO"
    }
}
