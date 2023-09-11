//
//  SharebyURLVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 12/01/2021.
//

import Foundation

struct SharebyURLVOTokenPayload: Model {
    let shareVO: SharebyURLVOTokenPayloadData

    init(token: String) {
        self.shareVO = SharebyURLVOTokenPayloadData(urlToken: token)
    }
    
    enum CodingKeys: String, CodingKey {
        case shareVO = "Shareby_urlVO"
    }
}

struct SharebyURLVOTokenPayloadData: Model {
    let urlToken: String
}
