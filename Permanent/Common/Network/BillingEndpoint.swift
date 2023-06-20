//
//  BillingEndpoint.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 01.04.2022.
//

import Foundation

enum BillingEndpoint {
    case claimPledge
}

extension BillingEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .claimPledge:
            return "/billing/claimpledge"
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
        switch self {
        case .claimPledge:
            return nil
        }
    }
    
    var progressHandler: ProgressHandler? {
        get {
            nil
        }
        set {}
    }
    
    var bodyData: Data? {
        nil
    }
    
    var customURL: String? {
        nil
    }
}
