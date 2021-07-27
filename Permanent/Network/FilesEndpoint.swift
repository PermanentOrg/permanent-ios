//
//  FilesEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

typealias UpdateRecordParams = (name: String?, description: String?, date: Date?, location: LocnVO?, recordId: Int, folderLinkId: Int, archiveNbr: String)

enum FilesEndpoint {
    // NAVIGATION
    /// Retrieves the “root” of an archive: the parent folder that contains the My Files and Public folders.
    case getRoot
    case navigateMin(params: NavigateMinParams)
    case getLeanItems(params: GetLeanItemsParams)
    
    // FILES MANAGEMENT
    case newFolder(params: NewFolderParams)
    case delete(params: ItemInfoParams)
    case relocate(params: RelocateParams)
    case update(params: UpdateRecordParams)
    
    // UPLOAD
    case getPresignedUrl(params: GetPresignedUrlParams)
    case registerRecord(params: RegisterRecordParams)
    
    // DOWNLOAD
    case getRecord(itemInfo: GetRecordParams)
    case getFolder(itemInfo: GetRecordParams)
    case download(url: URL, filename: String, progressHandler: ProgressHandler?)
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
        case .getPresignedUrl:
            return "/record/getPresignedUrl"
        case .registerRecord:
            return "/record/registerRecord"
        case .newFolder:
            return "/folder/post"
        case .delete(let parameters):
            if parameters.type.isFolder {
                return "/folder/delete"
            } else {
                return "/record/delete"
            }
        case .getRecord:
            return "/record/get"
            
        case .getFolder:
            return "/folder/get"
            
        case .relocate(let parameters):
            if parameters.items.source.type.isFolder {
                return "/folder/\(parameters.action.endpointValue)"
            } else {
                return "/record/\(parameters.action.endpointValue)"
            }
            
        case .update:
            return "/record/update"

        default:
            return ""
        }
    }
    
    var method: RequestMethod {
        switch self {
        case .download:
            return .get
        default:
            return .post
        }
    }
    
    var headers: RequestHeaders? {
        switch self {
        default:
            return [
                "content-type": "application/json"
            ]
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .navigateMin(let params):
            return Payloads.navigateMinPayload(for: params)
        case .getLeanItems(let params):
            return Payloads.getLeanItemsPayload(for: params)
        case .getPresignedUrl(let params):
            return Payloads.getPresignedUrlPayload(for: params)
        case .registerRecord(let params):
            return Payloads.registerRecord(for: params)
        case .newFolder(let params):
            return Payloads.newFolderPayload(for: params)
        case .download(_, let filename, _):
            return ["filename": filename]
        case .update(let params):
            return Payloads.updateRecordRequest(params: params)
        default:
            return nil
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .download:
            return .download
            
        default:
            return .data
        }
    }
    
    var responseType: ResponseType {
        switch self {
        case .download:
            return .file
            
        default:
            return .json
        }
    }
    
    var progressHandler: ProgressHandler? {
        get {
            switch self {
            case .download(_, _, let handler): return handler
            default: return nil
            }
        }
        set {}
    }
    
    var bodyData: Data? {
        switch self {
        case .delete(let parameters):
            if parameters.type.isFolder {
                let folderVO = FolderVOPayload(folderLinkId: parameters.folderLinkId)
                let requestVO = APIPayload.make(fromData: [folderVO])
                
                return try? APIPayload<FolderVOPayload>.encoder.encode(requestVO)
                
            } else {
                let recordVO = RecordVOPayload(folderLinkId: parameters.folderLinkId, parentFolderLinkId: parameters.parentFolderLinkId)
                let requestVO = APIPayload.make(fromData: [recordVO])
                
                return try? APIPayload<RecordVOPayload>.encoder.encode(requestVO)
            }
            
        case .getRecord(let itemInfo):
            let recordVO = RecordVOPayload(folderLinkId: itemInfo.folderLinkId, parentFolderLinkId: itemInfo.parentFolderLinkId)
            
            let requestVO = APIPayload.make(fromData: [recordVO])
            
            return try? APIPayload<RecordVOPayload>.encoder.encode(requestVO)
            
        case .getFolder(let itemInfo):
            let folderVO = FolderVOPayload(folderLinkId: itemInfo.folderLinkId)
            
            let requestVO = APIPayload.make(fromData: [folderVO])
            
            return try? APIPayload<FolderVOPayload>.encoder.encode(requestVO)
            
        case .relocate(let parameters):
            if parameters.items.source.type.isFolder {
                let copyVO = RelocateFolderPayload(folderLinkId: parameters.items.source.folderLinkId,
                                                   folderDestLinkId: parameters.items.destination.folderLinkId)
                let requestVO = APIPayload.make(fromData: [copyVO])
                
                return try? APIPayload<RelocateFolderPayload>.encoder.encode(requestVO)
            } else {
                let relocateVO = RelocateRecordPayload(folderLinkId: parameters.items.source.folderLinkId,
                                                       folderDestLinkId: parameters.items.destination.folderLinkId,
                                                       parentFolderLinkId: parameters.items.source.parentFolderLinkId)
                let requestVO = APIPayload.make(fromData: [relocateVO])
                
                return try? APIPayload<RelocateRecordPayload>.encoder.encode(requestVO)
            }

        default:
            return nil
        }
    }

    
    var customURL: String? {
        switch self {
        case .download(let url, _, _):
            return url.absoluteString
        default:
            return nil
        }
    }
}
