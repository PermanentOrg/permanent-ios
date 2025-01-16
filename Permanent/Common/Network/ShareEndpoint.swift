//  
//  ShareEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.12.2020.
//

import Foundation

enum ShareEndpoint {
    
    case getLink(file: FileModel)
    
    case generateShareLink(file: FileModel) // TODO: Create typealias
    
    case revokeLink(link: SharebyURLVOData)
    
    case updateShareLink(link: SharebyURLVOData)
    
    case getShares
    
    case checkLink(token: String)
    
    case requestShareAccess(token: String)
    
    case getShareForPreview(shareId: Int, folder_linkId: Int)
    
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
        case .getShareForPreview: return "/share/getShareForPreview"
        }
    }
    
    var method: RequestMethod { .post }
    
    var parameters: RequestParameters? {
        switch self {
        case .getShareForPreview(let shareId, let folder_linkId):
            return getShareForPreview(shareId: shareId, folder_linkId: folder_linkId)
        default :
            return nil
        }
    }
    
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
        case .getLink(let file),
             .generateShareLink(let file):
            if file.type.isFolder {
                let folderVO = FolderVOPayload(folderLinkId: file.folderLinkId)
                let requestVO = APIPayload.make(fromData: [folderVO])
                
                return try? APIPayload<FolderVOPayload>.encoder.encode(requestVO)
                
            } else {
                let recordVO = RecordVOPayload(folderLinkId: file.folderLinkId, parentFolderLinkId: file.parentFolderLinkId)
                let requestVO = APIPayload.make(fromData: [recordVO])
                
                return try? APIPayload<RecordVOPayload>.encoder.encode(requestVO)
            }
            
        case .revokeLink(let link),
             .updateShareLink(let link):

            let sharebyURLVO = SharebyURLVOPayload(sharebyURLVOData: link)
            let requestVO = APIPayload.make(fromData: [sharebyURLVO])
            
            return try? APIPayload<SharebyURLVOPayload>.encoder.encode(requestVO)
            
        case .checkLink(let token):
            let sharebyURLTokenVO = SharebyURLVOTokenPayload(token: token)
            
            let requestVO = APIPayload.make(fromData: [sharebyURLTokenVO])
            return try? APIPayload<SharebyURLVOTokenPayload>.encoder.encode(requestVO)
            
        case .requestShareAccess(let token):
            let sharebyURLTokenVO = SharebyURLVOTokenPayload(token: token)
            
            let requestVO = APIPayload.make(fromData: [sharebyURLTokenVO])
            return try? APIPayload<SharebyURLVOTokenPayload>.encoder.encode(requestVO)
            
        default:
            return nil
        }
    }
    
    var customURL: String? { nil }
}

extension ShareEndpoint {
    func getShareForPreview(shareId: Int, folder_linkId: Int) -> RequestParameters {
        return [
            "RequestVO":
                [
                    "data": [
                        [
                            "ShareVO": [
                                "shareId": "\(shareId)",
                                "folder_linkId": "\(folder_linkId)"
                            ]
                        ]
                    ]
                ]
        ]
    }
}
