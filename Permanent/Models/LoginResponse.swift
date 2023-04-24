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

extension LoginResponse {
    static func mock() -> LoginResponse {
        let accountVO = AccountVOData.mock()
        let archiveVO = ArchiveVOData.mock()
        let tokenVO = SimpleVOOf<String>(key: "token", value: "some_token", createdDT: nil, updatedDT: nil)

        let loginData = LoginData(accountVO: accountVO, archiveVO: archiveVO, tokenVO: tokenVO)
        let loginResult = LoginResult(data: [loginData], message: nil, status: true, resultDT: nil, createdDT: nil, updatedDT: nil)
        
        return LoginResponse(results: [loginResult], isSuccessful: true, actionFailKeys: nil, isSystemUp: true, systemMessage: nil, sessionID: nil, createdDT: nil, updatedDT: nil)
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
    let tokenVO: SimpleVOOf<String>?

    enum CodingKeys: String, CodingKey {
        case accountVO = "AccountVO"
        case archiveVO = "ArchiveVO"
        case tokenVO = "SimpleVO"
    }
}

