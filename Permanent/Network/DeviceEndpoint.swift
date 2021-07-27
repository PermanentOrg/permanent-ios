//
//  DeviceEndpoint.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 08.04.2021.
//

import Foundation

typealias NewDeviceParams = (String)
typealias DeleteDeviceParams = (String)

enum DeviceEndpoint {
    case new(params: NewDeviceParams)
    case delete(params: DeleteDeviceParams)
}

extension DeviceEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .new:
            return "/device/registerDevice"
        case .delete:
            return "/device/deleteToken"
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .new, .delete:
            return .post
        }
    }
    
    var headers: RequestHeaders? {
        switch self {
        case .new, .delete:
            return [
                "content-type": "application/json"
            ]
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .new, .delete:
            return .data
        }
    }
    
    var responseType: ResponseType {
        switch self {
        case .new, .delete:
            return .json
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .new(let params):
            return Payloads.devicePayload(params: params)
        case .delete(let params):
            return Payloads.devicePayload(params: params)
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
