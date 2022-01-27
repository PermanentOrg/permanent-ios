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
    case delete(archiveId: Int, archiveNbr: String)
    case accept(archiveVO: ArchiveVOData)
    case decline(archiveVO: ArchiveVOData)
    case update(archiveVO: ArchiveVOData, file: FileViewModel)
    case transferOwnership(archiveNbr: String, primaryEmail: String)
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
            
        case .delete:
            return "/archive/delete"
            
        case .accept:
            return "/archive/accept"
            
        case .decline:
            return "/archive/decline"
            
        case .update:
            return "/archive/update"
            
        case .transferOwnership:
            return "/archive/transferOwnership"
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
            
        case .delete(let archiveId, let archiveNbr):
            return Payloads.deleteArchivePayload(archiveId: archiveId, archiveNbr: archiveNbr)
            
        case .accept(archiveVO: let archiveVO):
            return Payloads.acceptArchivePayload(archiveVO: archiveVO)
            
        case .decline(archiveVO: let archiveVO):
            return Payloads.declineArchivePayload(archiveVO: archiveVO)
            
        case .update(let archiveVO, let file):
            return Payloads.updateArchiveThumbPayload(archiveVO: archiveVO, file: file)
            
        case .transferOwnership(archiveNbr: let archiveNbr, primaryEmail: let primaryEmail):
            return Payloads.transferOwnership(archiveNbr:archiveNbr, primaryEmail:primaryEmail)
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
