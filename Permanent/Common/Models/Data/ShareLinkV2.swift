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
    let creatorAccount: CreatorAccountForShare?
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
    
    // Memberwise initializer
    init(
        id: String?,
        itemId: String?,
        itemType: String?,
        token: String?,
        permissionsLevel: String?,
        accessRestrictions: String?,
        maxUses: Int?,
        usesExpended: Int?,
        expirationTimestamp: String?,
        creatorAccount: CreatorAccountForShare?,
        createdAt: String?,
        updatedAt: String?
    ) {
        self.id = id
        self.itemId = itemId
        self.itemType = itemType
        self.token = token
        self.permissionsLevel = permissionsLevel
        self.accessRestrictions = accessRestrictions
        self.maxUses = maxUses
        self.usesExpended = usesExpended
        self.expirationTimestamp = expirationTimestamp
        self.creatorAccount = creatorAccount
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = try container.decodeIfPresent(String.self, forKey: .id)
        itemId = try container.decodeIfPresent(String.self, forKey: .itemId)
        itemType = try container.decodeIfPresent(String.self, forKey: .itemType)
        token = try container.decodeIfPresent(String.self, forKey: .token)
        permissionsLevel = try container.decodeIfPresent(String.self, forKey: .permissionsLevel)
        accessRestrictions = try container.decodeIfPresent(String.self, forKey: .accessRestrictions)
        maxUses = try container.decodeIfPresent(Int.self, forKey: .maxUses)
        expirationTimestamp = try container.decodeIfPresent(String.self, forKey: .expirationTimestamp)
        creatorAccount = try container.decodeIfPresent(CreatorAccountForShare.self, forKey: .creatorAccount)
        createdAt = try container.decodeIfPresent(String.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(String.self, forKey: .updatedAt)
        
        // Handle usesExpended which can come as either String or Int from the API
        if let usesExpendedString = try? container.decodeIfPresent(String.self, forKey: .usesExpended) {
            usesExpended = Int(usesExpendedString)
        } else {
            usesExpended = try container.decodeIfPresent(Int.self, forKey: .usesExpended)
        }
    }
}


