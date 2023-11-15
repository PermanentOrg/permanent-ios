//
//  ResponseGiftingModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.11.2023.

import Foundation

/// MARK: - ResponseGiftingModel
struct ResponseGiftingModel<T: Model>: Model {
    let storageGifted: Int
    let giftDelivered: [String?]
    let invitationSent: [String?]
    let alreadyInvited: [String?]

    enum CodingKeys: String, CodingKey {
        case storageGifted
        case giftDelivered
        case invitationSent
        case alreadyInvited
    }
}
