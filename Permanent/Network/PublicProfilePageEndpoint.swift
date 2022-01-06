//
//  PublicProfilePageEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.11.2021.
//

import Foundation

enum PublicProfileEndpoint {
    case getAllByArchiveNbr(archiveId: Int, archiveNbr: String)
    case safeAddUpdate(profileItemVOData: ProfileItemModel)
    case deleteProfileItem(profileItemVOData: ProfileItemModel)
    
}

extension PublicProfileEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getAllByArchiveNbr:
            return "/profile_item/getAllByArchiveNbr"
            
        case .safeAddUpdate:
            return "/profile_item/safeAddUpdate"
            
        case .deleteProfileItem:
            return "/profile_item/delete"
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
        case .getAllByArchiveNbr(let archiveId,let archiveNbr):
            return Payloads.getAllByArchiveNbr(archiveId: archiveId, archiveNbr: archiveNbr)
            
        case .safeAddUpdate(let profileItemVOData):
            return Payloads.safeAddUpdate(profileItemVOData: profileItemVOData)
            
        case .deleteProfileItem(let profileItemVOData):
            return Payloads.safeAddUpdate(profileItemVOData: profileItemVOData)
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


