//  
//  InvitationVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import Foundation

struct InviteVO: Model {
    let invite: InviteVOData?
    
    enum CodingKeys: String, CodingKey {
        case invite = "InviteVO"
    }
}

struct InviteVOData: Model {
    let inviteID: Int?
    let email: String?
    let byArchiveID, byAccountID: Int?
    let expiresDT, fullName: String?
    let message, relationship, accessRole: String? // TODO
    let timesSent: Int?
    let giftSizeInMB: JSONAny? // TODO
    let token, status, type, createdDT: String?
    let updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case inviteID = "inviteId"
        case email
        case byArchiveID = "byArchiveId"
        case byAccountID = "byAccountId"
        case expiresDT, fullName, message, relationship, accessRole, timesSent, giftSizeInMB, token, status, type, createdDT, updatedDT
    }
}
