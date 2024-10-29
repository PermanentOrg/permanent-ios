//
//  EventsEndpoint.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 28.10.2024.

import Foundation

enum EventsEndpoint {
    case sendEvent
}

extension EventsEndpoint: RequestProtocol {
    var path: String {
        "event"
    }
    
    var method: RequestMethod {
        return .post
    }
    
    var parameters: RequestParameters? {
        return getEventParameters()
    }
    
    var requestType: RequestType {
        return .data
    }
    
    var responseType: ResponseType {
        return .json
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

extension EventsEndpoint {
    
    func getEventParameters() -> RequestParameters {
        var parameters: [String : Any] = [
            "archiveId": "\(String(describing: archiveDetails.archiveId ?? 0))",
            "stewardEmail": archiveDetails.stewardEmail,
            "type": archiveDetails.type,
            "trigger": [
                "type": archiveDetails.triggerType
            ]
        ]
        return parameters
    }
    
}
