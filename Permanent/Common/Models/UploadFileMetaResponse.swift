//  
//  UploadFileMetaResponse.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26/10/2020.
//

import Foundation

// MARK: - UploadFileMetaResponse
struct UploadFileMetaResponse: Codable {
    let results: [UploadFileMetaResult]?
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

// MARK: - Result
struct UploadFileMetaResult: Codable {
    let data: [UploadFileMetaData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: JSONAny?
}

// MARK: - Datum
struct UploadFileMetaData: Codable {
    let recordVO: RecordVOData?

    enum CodingKeys: String, CodingKey {
        case recordVO = "RecordVO"
    }
}
