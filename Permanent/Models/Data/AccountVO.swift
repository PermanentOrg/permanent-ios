//
//  AccountVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//  Copyright © 2020 Victory Square Partners. All rights reserved.
//

import Foundation

struct AccountVO: Codable {
    let accountID: Int?
    let primaryEmail, fullName: String?
    let address, address2, country, city: JSONNull?
    let state, zip, primaryPhone: JSONNull?
    let defaultArchiveID: Int?
    let level, apiToken: JSONNull?
    let betaParticipant: Int?
    let facebookAccountID, googleAccountID: JSONNull?
    let status, type, emailStatus, phoneStatus: String?
    let notificationPreferences: String?
    let agreed, optIn, emailArray, inviteCode: JSONNull?
    let rememberMe, keepLoggedIn, accessRole: JSONNull?
    let spaceTotal, spaceLeft: Int?
    let fileTotal: JSONNull?
    let fileLeft: Int?
    let changePrimaryEmail, changePrimaryPhone: JSONNull?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case accountID = "accountId"
        case primaryEmail, fullName, address, address2, country, city, state, zip, primaryPhone
        case defaultArchiveID = "defaultArchiveId"
        case level, apiToken, betaParticipant
        case facebookAccountID = "facebookAccountId"
        case googleAccountID = "googleAccountId"
        case status, type, emailStatus, phoneStatus, notificationPreferences, agreed, optIn, emailArray, inviteCode, rememberMe, keepLoggedIn, accessRole, spaceTotal, spaceLeft, fileTotal, fileLeft, changePrimaryEmail, changePrimaryPhone, createdDT, updatedDT
    }
}
