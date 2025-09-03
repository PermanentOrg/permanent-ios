//
//  ShareLinkV2.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.09.2025.
//

import Foundation

struct ShareLinkV2: Model {
    let data: ShareLinkV2Data?
    
    enum CodingKeys: String, CodingKey {
        case data
    }
}

struct ShareLinkV2Data: Model {
    let id: String?
    let itemId: String?
    let itemType: String?
    let token: String?
    let permissionsLevel: String?
    let accessRestrictions: String?
    let maxUses: Int?
    let usesExpended: Int?
    let expirationTimestamp: String?
    let creatorAccount: CreatorAccount?
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case itemId
        case itemType
        case token
        case permissionsLevel
        case accessRestrictions
        case maxUses
        case usesExpended
        case expirationTimestamp
        case creatorAccount
        case createdAt
        case updatedAt
    }
}

struct CreatorAccount: Model {
    let id: String?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}
