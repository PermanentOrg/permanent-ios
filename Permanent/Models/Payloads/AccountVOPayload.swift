//  
//  AccountVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22.12.2020.
//

import Foundation

struct AccountVOPayload: Model {
    let accountVO: AccountVOPayloadData
    
    init(accountId: Int) {
        self.accountVO = AccountVOPayloadData(accountId: accountId)
    }
    
    enum CodingKeys: String, CodingKey {
        case accountVO = "AccountVO"
    }
}

struct AccountVOPayloadData: Model {
    let accountId: Int
}
