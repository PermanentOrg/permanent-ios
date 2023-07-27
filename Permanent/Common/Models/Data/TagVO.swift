//
//  TagVO.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.03.2021.
//

import Foundation

struct TagVO: Model, Equatable, Hashable {
    var tagVO: TagVOData
    
    enum CodingKeys: String, CodingKey {
        case tagVO = "TagVO"
    }
    
    static func == (lhs: TagVO, rhs: TagVO) -> Bool {
        return lhs.tagVO.name == rhs.tagVO.name
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(tagVO.name)
    }
}

struct TagVOData: Model, Equatable {
    var name: String?
    let status: String?
    let tagId: Int?
    let type: String?
    let createdDT, updatedDT: String?
}
