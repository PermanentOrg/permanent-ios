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
    let tagLinkId: Int?
    let type: String?
    
    enum CodingKeys: String, CodingKey {
        case createdDT
        case updatedDT
        case refId
        case refTable
        case status
        case tagId
        case tagLinkId = "tag_linkId"
        case type
    }
}
