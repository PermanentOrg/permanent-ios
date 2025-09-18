//
//  CreatorAccountForShare.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.09.2025.

import Foundation


struct CreatorAccountForShare: Model {
    let id: String?
    let name: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
    }
}
