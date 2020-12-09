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
    case revokeLink(link: SharebyURLVOData, csrf: String)
}

extension ShareEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .getLink: return "/share/getLink"
        case .generateShareLink: return "/share/generateShareLink"
        case .revokeLink: return "/share/dropShareLink"
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
            
        case .revokeLink(let link, let csrf):
            guard
                let linkId = link.sharebyURLID,
                let byAccountId = link.byAccountID,
                let byArchiveId = link.byArchiveID else { return nil }
            
            let sharebyURLVO = SharebyURLVOPayload(
                linkId: linkId,
                byAccountId: byAccountId,
                byArchiveId: byArchiveId
            )
            let requestVO = APIPayload.make(fromData: [sharebyURLVO], csrf: csrf)
            
            return try? APIPayload<SharebyURLVOPayload>.encoder.encode(requestVO)
            
        default: return nil
        }
    }
    
    var customURL: String? { nil }
}
