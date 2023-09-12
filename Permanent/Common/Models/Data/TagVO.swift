//
//  TagVO.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.03.2021.
//

import Foundation

struct TagVO: Model, Equatable, Hashable, Comparable {
    var tagVO: TagVOData
    
    enum CodingKeys: String, CodingKey {
        case tagVO = "TagVO"
    }
    
    static func == (lhs: TagVO, rhs: TagVO) -> Bool {
        return lhs.tagVO.name == rhs.tagVO.name
    }
    
    static func < (lhs: TagVO, rhs: TagVO) -> Bool {
        guard let lhsName = lhs.tagVO.name else {
            return true
        }
        guard let rhsName = rhs.tagVO.name else {
            return false
        }
        
        return lhsName < rhsName
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
