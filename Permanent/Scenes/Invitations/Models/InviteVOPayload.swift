//  
//  InviteVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import Foundation

struct InviteVOPayload: Model {
    let inviteVO: InviteVOPayloadData
    
    enum CodingKeys: String, CodingKey {
        case inviteVO = "InviteVO"
    }
    
    init(id: Int? = nil, name: String?, email: String?) {
        self.inviteVO = InviteVOPayloadData(
            id: id,
            name: name,
            email: email
        )
    }
}

struct InviteVOPayloadData: Model {
    let id: Int?
    let name: String?
    let email: String?
    
    enum CodingKeys: String, CodingKey {
        case id = "inviteId"
        case name = "fullName"
        case email
    }
}
