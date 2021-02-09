//
//  GetPresignedUrlResponse.swift
//  Permanent
//
//  Created by Constantin Georgiu on 08.02.2021.
//

import Foundation   

// MARK: - GetPresignedUrlResponse

struct GetPresignedUrlResponse: Codable {
    let results: [GetPresignedUrlResult]?
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

// MARK: - GetPresignedUrlResult

struct GetPresignedUrlResult: Codable {
    let data: [GetPresignedUrlData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: JSONAny?
}

// MARK: - GetPresignedUrlData

struct GetPresignedUrlData: Codable {
    let simpleVO: GetPresignedUrlVO?

    enum CodingKeys: String, CodingKey {
        case simpleVO = "SimpleVO"
    }
}

// MARK: - GetPresignedUrlVO
struct GetPresignedUrlVO: Codable {
    let value: DestinationUrlVO?
}

struct DestinationUrlVO: Codable {
    let presignedPost: PresignedPost?
}

struct PresignedPost: Codable {
    let url: String?
    let fields: [String: String]?
}
