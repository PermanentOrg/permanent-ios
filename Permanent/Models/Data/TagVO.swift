//
//  TagVO.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.03.2021.
//

import Foundation

struct TagVO: Model {
    let tagVO: TagVOData
    
    enum CodingKeys: String, CodingKey {
        case tagVO = "TagVO"
    }
}

struct TagVOData: Model {
    
    let name: String?
    let status: String?
    let tagId: Int?
    let type: String?
    let createdDT, updatedDT: String?
}
