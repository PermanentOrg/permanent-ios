//
//  SharebyURLVOPayload.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08/12/2020.
//

import Foundation

struct SharebyURLVOPayload: Model {
    let shareVO: SharebyURLVOPayloadData

    init(sharebyURLVOData model: SharebyURLVOData) {
        self.shareVO = SharebyURLVOPayloadData(sharebyURLVOData: model)
    }
    
    enum CodingKeys: String, CodingKey {
        case shareVO = "Shareby_urlVO"
    }
}

struct SharebyURLVOPayloadData: Model {
    let linkId: Int?
    let byAccountId: Int?
    let byArchiveId: Int?
    let previewToggle: Int?
    let autoApproveToggle: Int?
    var expiresDT: String?
    let maxUses: Int?

    enum CodingKeys: String, CodingKey {
        case linkId = "shareby_urlId"
        case byAccountId, byArchiveId
        case previewToggle
        case autoApproveToggle
        case expiresDT
        case maxUses
    }
    
    init(sharebyURLVOData model: SharebyURLVOData) {
        self.linkId = model.sharebyURLID
        self.byAccountId = model.byAccountID
        self.byArchiveId = model.byArchiveID
        self.previewToggle = model.previewToggle
        self.autoApproveToggle = model.autoApproveToggle
        self.expiresDT = model.expiresDT
        self.maxUses = model.maxUses
    }
}
