//  
//  ShareEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.12.2020.
//

import Foundation

enum ShareEndpoint {
    case getLink(file: FileViewModel, csrf: String)
    case generateShareLink
}

extension ShareEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getLink: return "/share/getLink"
        case .generateShareLink: return "/share/generateShareLink"
        }
    }
    
    var method: RequestMethod { .post }
    
    var headers: RequestHeaders? { nil }
    
    var parameters: RequestParameters? { nil }
    
    var requestType: RequestType { .data }
    
    var responseType: ResponseType { .json }
    
    var progressHandler: ProgressHandler? {
        get {
            nil
        }
        set {}
    }
    
    var bodyData: Data? {
        switch self {
        case .getLink(let file, let csrf):
            if file.type.isFolder {
                let folderVO = FolderVOPayload(folderLinkId: file.folderLinkId)
                let requestVO = APIPayload.make(fromData: [folderVO], csrf: csrf)
                
                return try? APIPayload<FolderVOPayload>.encoder.encode(requestVO)
                
            } else {
                let recordVO = RecordVOPayload(folderLinkId: file.folderLinkId, parentFolderLinkId: file.parentFolderLinkId)
                let requestVO = APIPayload.make(fromData: [recordVO], csrf: csrf)
                
                return try? APIPayload<RecordVOPayload>.encoder.encode(requestVO)
            }
            
        default: return nil
        }
    }
    
    var customURL: String? { nil }
}
