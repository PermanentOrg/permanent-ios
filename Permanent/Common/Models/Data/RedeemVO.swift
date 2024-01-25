//
//  RedeemVO.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.12.2023.

import Foundation

struct RedeemVO: Model {
    let promoVO: PromoVOdata?

    enum CodingKeys: String, CodingKey {
        case promoVO = "PromoVO"
    }
}

struct PromoVOdata: Codable {
    let promoId: Int?
    let code: String?
    let sizeInMB: Int?
    let expiresDT: String?
    let remainingUses: Int?
    let status: String?
    let type: String?
    let createdDT, updatedDT: String?
}
