//
//  NotificationsEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22.01.2021.
//

import Foundation

enum NotificationsEndpoint {
    case getMyNotifications
}

extension NotificationsEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getMyNotifications:
            return "/notification/getMyNotifications"
        }
    }
    
    var method: RequestMethod { .post }
    
    var headers: RequestHeaders? { nil }
    
    var parameters: RequestParameters? { nil }
    
    var requestType: RequestType { .data }
    
    var responseType: ResponseType { .json }
    
    var progressHandler: ProgressHandler? {
        get {
            nil
        }
        set {}
    }
    
    var bodyData: Data? {
        switch self {
        case .getMyNotifications:
            let emptyPayload = NoDataModel()
            let requestVO = APIPayload.make(fromData: [emptyPayload], csrf: nil)
            
            return try? APIPayload<NoDataModel>.encoder.encode(requestVO)
        }
    }
    
    var customURL: String? {
        nil
    }
}
