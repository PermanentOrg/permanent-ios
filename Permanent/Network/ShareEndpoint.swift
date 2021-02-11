//  
//  ShareEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.12.2020.
//

import Foundation

enum ShareEndpoint {
    
    case getLink(file: FileViewModel, csrf: String)
    
    case generateShareLink(file: FileViewModel, csrf: String) // TODO: Create typealias
    
    case revokeLink(link: SharebyURLVOData, csrf: String)
    
    case updateShareLink(link: SharebyURLVOData, csrf: String)
    
    case getShares
    
    case checkLink(token: String)
    
    case requestShareAccess(token: String, csrf: String)
    
    case updateShareRequest(file: FileViewModel, csrf: String)
    
    case deleteShareRequest(file: FileViewModel, csrf: String)
}

extension ShareEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getLink: return "/share/getLink"
        case .generateShareLink: return "/share/generateShareLink"
        case .revokeLink: return "/share/dropShareLink"
        case .updateShareLink: return "/share/updateShareLink"
        case .getShares: return "/share/getShares"
        case .checkLink: return "/share/checkShareLink"
        case .requestShareAccess: return "/share/requestShareAccess"
        case .updateShareRequest: return "/share/upsert"
        case .deleteShareRequest: return "/share/delete"
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
        case .getLink(let file, let csrf),
             .generateShareLink(let file, let csrf):
            if file.type.isFolder {
                let folderVO = FolderVOPayload(folderLinkId: file.folderLinkId)
                let requestVO = APIPayload.make(fromData: [folderVO], csrf: csrf)
                
                return try? APIPayload<FolderVOPayload>.encoder.encode(requestVO)
                
            } else {
                let recordVO = RecordVOPayload(folderLinkId: file.folderLinkId, parentFolderLinkId: file.parentFolderLinkId)
                let requestVO = APIPayload.make(fromData: [recordVO], csrf: csrf)
                
                return try? APIPayload<RecordVOPayload>.encoder.encode(requestVO)
            }
            
        case .revokeLink(let link, let csrf),
             .updateShareLink(let link, let csrf):

            let sharebyURLVO = SharebyURLVOPayload(sharebyURLVOData: link)
            let requestVO = APIPayload.make(fromData: [sharebyURLVO], csrf: csrf)
            
            return try? APIPayload<SharebyURLVOPayload>.encoder.encode(requestVO)
            
        case .checkLink(let token):
            
            let sharebyURLTokenVO = SharebyURLVOTokenPayload(token: token)
            
            let requestVO = APIPayload.make(fromData: [sharebyURLTokenVO], csrf: nil)
            return try? APIPayload<SharebyURLVOTokenPayload>.encoder.encode(requestVO)
            
        case .requestShareAccess(let token, let csrf):
            
            let sharebyURLTokenVO = SharebyURLVOTokenPayload(token: token)
            
            let requestVO = APIPayload.make(fromData: [sharebyURLTokenVO], csrf: csrf)
            return try? APIPayload<SharebyURLVOTokenPayload>.encoder.encode(requestVO)
            
        default:
            return nil
        }
    }
    
    var customURL: String? { nil }
}
