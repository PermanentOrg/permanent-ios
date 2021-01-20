//
//  LoggedInResponse.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.01.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import Foundation
// MARK: -loggedIn Response
struct LoggedInResponse: Codable {
    let Results: [LoggedInResult]?
    let actionFailKeys: [JSONAny]?
    let isSuccessful: Bool?
    let isSystemUp: Bool?
    let systemMessage: String?
    let sessionId: JSONAny?
    let csrf: String?
    let createdDT, updatedDT: String?
}
// MARK: -loggedIn Result
struct LoggedInResult:Codable {
    let data: [LoggedInData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: String?
}
// MARK: -loggedIn Data
struct LoggedInData: Codable {
    let SimpleVO: LoggedInSimpleVOdata?
}
struct LoggedInSimpleVOdata: Codable {
    let key: String?
    let value: Bool??
    let createdDT: String?
    let updatedDT: String?
}
