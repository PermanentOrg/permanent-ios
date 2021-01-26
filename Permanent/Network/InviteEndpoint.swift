//
//  InviteEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import Foundation

enum InviteEndpoint {
    case getMyInvites
}

extension InviteEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getMyInvites:
            return "/invite/getMyInvites"
        }
    }
    
    var method: RequestMethod { .post }
    
    var headers: RequestHeaders? { nil }
    
    var parameters: RequestParameters? { nil }
        
    var requestType: RequestType { .data }
    
    var responseType: ResponseType { .json }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        
        set {}
    }
    
    var bodyData: Data? {
        switch self {
        case .getMyInvites:
            
            let emptyPayload = NoDataModel()
            let requestVO = APIPayload.make(fromData: [emptyPayload], csrf: nil)
            
            return try? APIPayload<NoDataModel>.encoder.encode(requestVO)
        }
    }
    
    var customURL: String? {
        nil
    }
}
