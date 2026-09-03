//
//  BillingEndpoint.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 01.04.2022.
//

import Foundation

enum BillingEndpoint {
    case claimPledge
    case giftStorage(gift: GiftingModel)
    /// POST /api/v2/storage-purchases — Stela opens a Stripe PaymentIntent for `amountInUSD` whole dollars.
    case purchaseStorage(amountInUSD: Int)
}

extension BillingEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .claimPledge:
            return "/billing/claimpledge"
        case .giftStorage:
            return "/billing/giftStorage"
        case .purchaseStorage:
            return ""  // Not used - we use customURL
        }
    }
    
    var method: RequestMethod {
        return .post
    }
    
    var headers: RequestHeaders? {
        return [
            "content-type": "application/json"
        ]
    }
    
    var requestType: RequestType {
        return .data
    }
    
    var responseType: ResponseType {
        return .json
    }
    
    var parameters: RequestParameters? {
        return nil
    }
    
    var progressHandler: ProgressHandler? {
        get {
            nil
        }
        set {}
    }
    
    var bodyData: Data? {
        switch self {
        case .giftStorage(let gift):
            return try? APIPayload<GiftingModel>.encoder.encode(gift)
        case .purchaseStorage(let amountInUSD):
            return try? JSONSerialization.data(withJSONObject: ["amountInUSD": amountInUSD])
        default: return nil
        }
    }
    
    var customURL: String? {
        let endpointPath = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .giftStorage(_):
            return "\(endpointPath)api/v2/billing/gift"
        case .purchaseStorage:
            return "\(endpointPath)api/v2/storage-purchases"
        default : return nil
        }
    }
}
