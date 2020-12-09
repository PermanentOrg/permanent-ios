//
//  SharebyURLVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08/12/2020.
//

import Foundation

struct SharebyURLVOPayload: Model {
    let shareVO: SharebyURLVOPayloadData
    
    init(linkId: Int, byAccountId: Int, byArchiveId: Int) {
        self.shareVO = SharebyURLVOPayloadData(
            linkId: linkId,
            byAccountId: byAccountId,
            byArchiveId: byArchiveId
        )
    }
    
    enum CodingKeys: String, CodingKey {
        case shareVO = "Shareby_urlVO"
    }
}

struct SharebyURLVOPayloadData: Model {
    let linkId: Int
    let byAccountId: Int
    let byArchiveId: Int

    enum CodingKeys: String, CodingKey {
        case linkId = "shareby_urlId"
        case byAccountId, byArchiveId
    }
}


