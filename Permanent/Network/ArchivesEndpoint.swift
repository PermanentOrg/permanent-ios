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
    case change(archiveId: Int, archiveNbr: String)
    case create(name: String, type: String)
}

extension ArchivesEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getArchivesByAccountId:
            return "/archive/getAllArchives"
            
        case .change:
            return "/archive/change"
            
        case .create:
            return "/archive/post"
        }
    }
    
    var method: RequestMethod {
        return .post
    }
    
    var headers: RequestHeaders? {
        return [
            "content-type": "application/json"
        ]
    }
    
    var requestType: RequestType {
        return .data
    }
    
    var responseType: ResponseType {
        return .json
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .getArchivesByAccountId(let accountId):
            return Payloads.getArchivesByAccountId(accountId: accountId)
            
        case .change(let archiveId, let archiveNbr):
            return Payloads.changeArchivePayload(archiveId: archiveId, archiveNbr: archiveNbr)
            
        case .create(let name, let type):
            return Payloads.createArchivePayload(name: name, type: type)
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
