//
//  LocationEndpoint.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 19.03.2021.
//

import Foundation

typealias GeomapLatLongParams = (lat: Double, long: Double, csrf: String)

enum LocationEndpoint {
    case geomapLatLong(params: GeomapLatLongParams)
}

extension LocationEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .geomapLatLong:
            return "/locn/geomapLatLong"
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .geomapLatLong:
            return .post
        }
    }
    
    var headers: RequestHeaders? {
        switch self {
        case .geomapLatLong:
            return [
                "content-type": "application/json"
            ]
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .geomapLatLong:
            return .data
        }
    }
    
    var responseType: ResponseType {
        switch self {
        case .geomapLatLong:
            return .json
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .geomapLatLong(let params):
            return Payloads.geomapLatLong(params: params)
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
