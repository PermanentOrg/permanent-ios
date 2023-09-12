//  
//  AccountVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22.12.2020.
//

import Foundation

struct AccountVOPayload: Model {
    let accountVO: AccountVOPayloadData
    
    init(accountId: Int, email: String, role: String) {
        self.accountVO = AccountVOPayloadData(
            accountId: accountId,
            email: email,
            role: role
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case accountVO = "AccountVO"
    }
}

struct AccountVOPayloadData: Model {
    let accountId: Int?
    let email: String
    let role: String
    
    enum CodingKeys: String, CodingKey {
        case accountId
        case email = "primaryEmail"
        case role = "accessRole"
    }
}
