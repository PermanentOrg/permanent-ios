//
//  ArchivesEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 25.08.2021.
//

import Foundation

typealias GetArchivesByAccountId = (Int)

enum ArchivesEndpoint {
    case getArchivesByAccountId(accountId: GetArchivesByAccountId)
}

extension ArchivesEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getArchivesByAccountId:
            return "/archive/getAllArchives"
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .getArchivesByAccountId:
            return .post
        }
    }
    
    var headers: RequestHeaders? {
        switch self {
        case .getArchivesByAccountId:
            return [
                "content-type": "application/json"
            ]
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .getArchivesByAccountId:
            return .data
        }
    }
    
    var responseType: ResponseType {
        switch self {
        case .getArchivesByAccountId:
            return .json
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .getArchivesByAccountId(let accountId):
            return Payloads.getArchivesByAccountId(accountId: accountId)
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
