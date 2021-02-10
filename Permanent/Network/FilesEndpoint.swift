//
//  FilesEndpoint.swift
//  Permanent
//
//  Created by Adrian Creteanu on 14/10/2020.
//

import Foundation

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
    
    // UPLOAD

    case getPresignedUrl(params: GetPresignedUrlParams)

    case upload(s3Url: String?, file: FileInfo, fields: [String:String]?, progressHandler: ProgressHandler?, usingBoundry: String)

    case registerRecord(params: RegisterRecordParams)
    // DOWNLOAD
    
    case getRecord(itemInfo: GetRecordParams)
    
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
            if parameters.file.type.isFolder {
                return "/folder/delete"
            } else {
                return "/record/delete"
            }
        case .getRecord:
            return "/record/get"
            
        case .relocate(let parameters):
            if parameters.items.source.type.isFolder {
                return "/folder/\(parameters.action.endpointValue)"
            } else {
                return "/record/\(parameters.action.endpointValue)"
            }

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
        case .upload(_, _, _, _, let boundary):
            return [
                "content-type": "multipart/form-data; boundary=\(boundary)"
            ]
        default:
            return nil
        }
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .navigateMin(let params):
            return Payloads.navigateMinPayload(for: params)
        case .getLeanItems(let params):
            return Payloads.getLeanItemsPayload(for: params)
        case .upload(_, _, let fields, _, _):
            return fields
        case .getPresignedUrl(let params):
            return Payloads.getPresignedUrlPayload(for: params)
        case .registerRecord(let params):
            return Payloads.registerRecord(for: params)
        case .newFolder(let params):
            return Payloads.newFolderPayload(for: params)
        case .download(_, let filename, _):
            return ["filename": filename]
        default:
            return nil
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .upload:
            return .upload
            
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
            case .upload(_, _, _, let handler, _): return handler
            case .download(_, _, let handler): return handler
            default: return nil
            }
        }
        set {}
    }
    
    var bodyData: Data? {
        switch self {
        case .upload(_, let file, _, _, let boundary):
            return UploadManager.instance.getBodyData(parameters: parameters ?? [:], file: file, boundary: boundary)
        case .delete(let parameters):
            if parameters.file.type.isFolder {
                let folderVO = FolderVOPayload(folderLinkId: parameters.file.folderLinkId)
                let requestVO = APIPayload.make(fromData: [folderVO], csrf: parameters.csrf)
                
                return try? APIPayload<FolderVOPayload>.encoder.encode(requestVO)
                
            } else {
                let recordVO = RecordVOPayload(folderLinkId: parameters.file.folderLinkId, parentFolderLinkId: parameters.file.parentFolderLinkId)
                let requestVO = APIPayload.make(fromData: [recordVO], csrf: parameters.csrf)
                
                return try? APIPayload<RecordVOPayload>.encoder.encode(requestVO)
            }
            
        case .getRecord(let itemInfo):
            //let recordVO = RecordVOPayload(folderLinkId: itemInfo.file.folderLinkId, parentFolderLinkId: itemInfo.file.parentFolderLinkId)
            
            let recordVO = RecordVOPayload(folderLinkId: itemInfo.folderLinkId, parentFolderLinkId: itemInfo.parentFolderLinkId)
            
            let requestVO = APIPayload.make(fromData: [recordVO], csrf: itemInfo.csrf)
            
            return try? APIPayload<RecordVOPayload>.encoder.encode(requestVO)
            
        case .relocate(let parameters):
            if parameters.items.source.type.isFolder {
                let copyVO = RelocateFolderPayload(folderLinkId: parameters.items.source.folderLinkId,
                                                   folderDestLinkId: parameters.items.destination.folderLinkId)
                let requestVO = APIPayload.make(fromData: [copyVO], csrf: parameters.csrf)
                
                return try? APIPayload<RelocateFolderPayload>.encoder.encode(requestVO)
            } else {
                let relocateVO = RelocateRecordPayload(folderLinkId: parameters.items.source.folderLinkId,
                                                       folderDestLinkId: parameters.items.destination.folderLinkId,
                                                       parentFolderLinkId: parameters.items.source.parentFolderLinkId)
                let requestVO = APIPayload.make(fromData: [relocateVO], csrf: parameters.csrf)
                
                return try? APIPayload<RelocateRecordPayload>.encoder.encode(requestVO)
            }

        default:
            return nil
        }
    }

    
    var customURL: String? {
        switch self {
        case .upload(let destinationUrl, _, _, _, _):
            return destinationUrl
        case .download(let url, _, _):
            return url.absoluteString
        default:
            return nil
        }
    }
}
