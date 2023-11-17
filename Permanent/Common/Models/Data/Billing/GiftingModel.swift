//
//  GiftingModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2023.

import Foundation

/// MARK: - GiftingModel
struct GiftingModel: Model {
    let storageAmount: Int
    let recipientEmails: [String]
    let note: String?
}
