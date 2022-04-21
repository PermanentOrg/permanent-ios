//
//  LocationEndpoint.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 19.03.2021.
//

import Foundation

typealias GeomapLatLongParams = (lat: Double, long: Double)

enum LocationEndpoint {
    case geomapLatLong(params: GeomapLatLongParams)
    case locnPost(location: LocnVO)
}

extension LocationEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .geomapLatLong:
            return "/locn/geomapLatLong"
        case .locnPost:
            return "/locn/post"
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .geomapLatLong, .locnPost:
            return .post
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .geomapLatLong, .locnPost:
            return .data
        }
    }
    
    var responseType: ResponseType {
        switch self {
        case .geomapLatLong, .locnPost:
            return .json
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .geomapLatLong(let params):
            return Payloads.geomapLatLong(params: params)
            
        case .locnPost(let location):
            return Payloads.locnPost(location: location)
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
