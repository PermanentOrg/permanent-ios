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
}

extension BillingEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .claimPledge:
            return "/billing/claimpledge"
        case .giftStorage:
            return "/billing/giftStorage"
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
        default: return nil
        }
    }
    
    var customURL: String? {
        let endpointPath = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .giftStorage(_):
            
            return "\(endpointPath)api/v2/billing/gift"
        default : return nil
        }
    }
}
