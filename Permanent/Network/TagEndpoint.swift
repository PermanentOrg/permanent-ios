//
//  TagEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 30.03.2021.
//

import Foundation

typealias TagParams = (name: String, refID: Int, csrf: String)

enum TagEndpoint {
    case tagParams(params: TagParams)
}

extension TagEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .tagParams:
            return "/tag/post"
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .tagParams:
            return .post
        }
    }
    
    var headers: RequestHeaders? {
        switch self {
        case .tagParams:
            return [
                "content-type": "application/json"
            ]
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .tagParams:
            return .data
        }
    }
    
    var responseType: ResponseType {
        switch self {
        case .tagParams:
            return .json
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .tagParams(let params):
            return Payloads.tagParams(params: params)
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
