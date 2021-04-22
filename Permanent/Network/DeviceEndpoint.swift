//
//  DeviceEndpoint.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 08.04.2021.
//

import Foundation

enum DeviceEndpoint {
    case new(token: String)
}

extension DeviceEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .new:
            return "/device/new"
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .new:
            return .post
        }
    }
    
    var headers: RequestHeaders? {
        switch self {
        case .new:
            return [
                "content-type": "application/json"
            ]
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .new:
            return .data
        }
    }
    
    var responseType: ResponseType {
        switch self {
        case .new:
            return .json
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .new(let token):
            return Payloads.newDevice(token: token)
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
