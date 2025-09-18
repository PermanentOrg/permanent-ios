//
//  ShareLinkV2Response.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.09.2025.
import Foundation

struct ShareLinkV2Response: Model {
    let items: [ShareLinkV2Data]?
    
    enum CodingKeys: String, CodingKey {
        case items
    }
}
