//
//  TagLinkVO.swift
//  Permanent
//
//  Created by Lucian Cerbu on 31.03.2021.
//

import Foundation

struct TagLinkVO: Model {
    let tagLinkVO: TagLinkVOData
    
    enum CodingKeys: String, CodingKey {
        case tagLinkVO = "TagLinkVO"
    }
}

struct TagLinkVOData: Model {
    
    let createdDT, updatedDT: String?
    let refId: Int?
    let refTable: String?
    let status: String?
    let tagId: Int?
    let tag_linkId: Int?
    let type: String?

    enum CodingKeys: String, CodingKey {
        case refId, refTable, status, tagId, tag_linkId, type, createdDT, updatedDT
    }
}
