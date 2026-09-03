//
//  StoragePurchaseResponse.swift
//  Permanent
//
//  Created by Lucian Cerbu on 02.09.2026.
//

import Foundation

/// The 201 body of POST /api/v2/storage-purchases: an abridged Stripe PaymentIntent.
struct StoragePurchaseResponse: Model {
    struct Payload: Model {
        let clientSecret: String?
    }

    let data: Payload?
}
