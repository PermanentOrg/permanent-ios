//
//  ChangePasswordResponse.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.01.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import Foundation
// MARK: -PasswordChange Response
struct ChangePasswordResponse: Codable {
    let Results: [ChangePasswordResult]?
    let actionFailKeys: [JSONAny]?
    let isSuccessful: Bool?
    let isSystemUp: Bool?
    let systemMessage: String?
    let sessionID: JSONAny?
    let csrf: String?
    let createdDT, updatedDT: String?
}
// MARK: -PasswordChange Result
struct ChangePasswordResult:Codable {
    let data: [ChangePasswordData]?
    let message: [String]?
    let status: Bool?
    let resultDT: String?
    let createdDT, updatedDT: String?
}
// MARK: -PasswordChange Data
struct ChangePasswordData: Codable {
    let accountVO: AccountVOData?

}
