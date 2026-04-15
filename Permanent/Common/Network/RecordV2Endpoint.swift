//
//  RecordV2Endpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.02.2026.
//

import Foundation

enum RecordV2Endpoint {
    case getRecordById(recordId: String, shareToken: String?)
}

extension RecordV2Endpoint: RequestProtocol {
    var path: String { "" }  // Not used - we use customURL
    
    var method: RequestMethod { .get }
    
    var requestType: RequestType { .data }
    
    var responseType: ResponseType { .json }
    
    var parameters: RequestParameters? { nil }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        set { }
    }
    
    var bodyData: Data? { nil }
    
    var customURL: String? {
        let baseURL = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .getRecordById(let recordId, _):
            return "\(baseURL)api/v2/records/\(recordId)"
        }
    }
    
    var shareToken: String? {
        switch self {
        case .getRecordById(_, let token):
            return token
        }
    }
    
    var headers: RequestHeaders? {
        return ["Content-Type": "application/json", "Request-Version": "2"]
    }
    
    var ignoreErrors: Bool { false }
}
