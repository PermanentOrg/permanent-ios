//  
//  MembersEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.12.2020.
//

import Foundation

enum MembersEndpoint {
    
    case members(archiveNbr: String)
    
}

extension MembersEndpoint: RequestProtocol {
    
    var path: String {
        switch self {
        case .members:
            return "/archive/getShares"
        }
    }
    
    var method: RequestMethod { .post }
    
    var headers: RequestHeaders? { nil }
    
    var parameters: RequestParameters? { nil }
        
    var requestType: RequestType { .data }
    
    var responseType: ResponseType { .json }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        
        set { }
    }
    
    var bodyData: Data? {
        switch self {
        case.members(let archiveNbr):
            
            let archiveVO = ArchiveVOPayload(archiveNbr: archiveNbr)
            let requestVO = APIPayload.make(fromData: [archiveVO], csrf: nil)
            
            return try? APIPayload<ArchiveVOPayload>.encoder.encode(requestVO)
        }
    }
    
    var customURL: String? {
        nil
    }
    
}
