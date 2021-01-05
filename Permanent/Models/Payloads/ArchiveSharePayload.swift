//  
//  ArchiveSharePayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 05.01.2021.
//

import Foundation

struct ArchiveSharePayload: Model {
    let archiveVO: ArchiveVOPayloadData
    let accountVO: AccountVOPayloadData
    
    init(archiveNbr: String, accountData: AddMemberParams) {
        archiveVO = ArchiveVOPayloadData(archiveNbr: archiveNbr)
        accountVO = AccountVOPayloadData(accountId: nil, email: accountData.email, role: accountData.role)
    }
    
    enum CodingKeys: String, CodingKey {
        case archiveVO = "ArchiveVO"
        case accountVO = "AccountVO"
    }
}
