//
//  DeviceEndpoint.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 08.04.2021.
//

import Foundation

typealias NewDeviceParams = (token: String, csrf: String)

enum DeviceEndpoint {
    case new(params: NewDeviceParams)
}

extension DeviceEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .new:
            return "/device/registerDevice"
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
        case .new(let params):
            return Payloads.newDevice(params: params)
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
