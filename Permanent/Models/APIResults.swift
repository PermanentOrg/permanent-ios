//
//  APIResults.swift
//  Permanent
//
//  Created by Adrian Creteanu on 09/11/2020.
//

import Foundation

struct APIResults<T: Model>: Model {
    let results: [APIResultData<T>]
    let isSuccessful: Bool
    let actionFailKeys: [JSONAny]
    let isSystemUp: Bool
    let systemMessage: String
    let sessionID: String?
    let csrf: String
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case results = "Results"
        case isSuccessful
        case actionFailKeys
        case isSystemUp
        case systemMessage
        case sessionID
        case csrf
        case createdDT, updatedDT
    }
}

struct APIResultData<T: Model>: Model {
    let data: [T]?
    let message: [String]
    let status: Bool
    let resultDT: String
    let createdDT, updatedDT: String?
}

struct NoDataModel: Model {}

extension APIResults {
    static var decoder: JSONDecoder { T.decoder }
}
