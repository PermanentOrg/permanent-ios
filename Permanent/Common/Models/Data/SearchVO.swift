//
//  SearchVO.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 02.11.2021.
//

import Foundation

struct SearchVO: Model {
    let searchVO: SearchVOData
    
    enum CodingKeys: String, CodingKey {
        case searchVO = "SearchVO"
    }
}

struct SearchVOData: Model {
    let childItemVOs: [ItemVO]?
    
    enum CodingKeys: String, CodingKey {
        case childItemVOs = "ChildItemVOs"
    }
}
