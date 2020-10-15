//
//  FilesEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

enum FilesEndpoint {
    /// Retrieves the “root” of an archive: the parent folder that contains the My Files and Public folders.
    case getRoot
    
    case navigateMin(params: NavigateMinParams)
    
    case getLeanItems(params: GetLeanItemsParams)
}

extension FilesEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getRoot:
            return "/folder/getRoot"
        case .navigateMin:
            return "/folder/navigateMin"
        case .getLeanItems:
            return "/folder/getLeanItems"
        }
    }
    
    var method: RequestMethod {
        .post
    }
    
    var headers: RequestHeaders? {
        nil
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .navigateMin(let params):
            return Payloads.navigateMinPayload(for: params)
        case .getLeanItems(let params):
            return Payloads.getLeanItemsPayload(for: params)
        default:
            return nil
        }
    }
    
    var requestType: RequestType {
        .data
    }
    
    var responseType: ResponseType {
        .json
    }
}
