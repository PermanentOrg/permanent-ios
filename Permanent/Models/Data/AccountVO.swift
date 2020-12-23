//
//  AccountVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import Foundation

struct AccountVO: Model {
    let accountVO: AccountVOData?
    
    enum CodingKeys: String, CodingKey {
        case accountVO = "AccountVO"
    }
}

struct AccountVOData: Model {
    let accountID: Int?
    let primaryEmail, fullName: String?
    let address, address2, country, city: String?
    let state, zip: String?
    let primaryPhone: String?
    let defaultArchiveID: Int?
    let level, apiToken: JSONAny?
    let betaParticipant: Int?
    let facebookAccountID, googleAccountID: JSONAny?
    let status, type, emailStatus, phoneStatus: String?
    let notificationPreferences: String?
    let agreed, optIn, emailArray, inviteCode: JSONAny?
    let rememberMe, keepLoggedIn: JSONAny?
    let accessRole: String?
    let spaceTotal, spaceLeft: Int?
    let fileTotal: JSONAny?
    let fileLeft: Int?
    let changePrimaryEmail, changePrimaryPhone: JSONAny?
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
