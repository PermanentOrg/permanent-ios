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
    
    case uploadFileMeta(params: FileMetaParams)
    
    case upload(file: FileInfo, usingBoundary: String, recordId: Int, progressHandler: ProgressHandler?) // TODO: Remove boundary from here
    
    case newFolder(params: NewFolderParams)
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
        case .uploadFileMeta:
            return "/record/postMetaBatch"
        case .newFolder:
            return "/folder/post"
            
        default:
            return ""
        }
    }
    
    var method: RequestMethod {
        .post
    }
    
    var headers: RequestHeaders? {
        switch self {
        case .upload(_, let boundary, _, _):
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
        case .upload(_, _, let recordId, _):
            return ["recordid": recordId]
        case .uploadFileMeta(let params):
            return Payloads.uploadFileMetaPayload(for: params)
        case .newFolder(let params):
            return Payloads.newFolderPayload(for: params)
            
        default:
            return nil
        }
    }
    
    var requestType: RequestType {
        switch self {
        case .upload:
            return .upload
            
        default:
            return .data
        }
    }
    
    var responseType: ResponseType {
        .json
    }
    
    var progressHandler: ProgressHandler? {
        get {
            switch self {
            case .upload(_, _, _, let handler): return handler
            default: return nil
            }
        }
        set {}
    }
    
    var bodyData: Data? {
        switch self {
        case .upload(let file, let boundary, _, _):
            return UploadManager.instance.getBodyData(parameters: parameters ?? [:],
                                                      file: file,
                                                      boundary: boundary)
        default:
            return nil
        }
    }
    
    var customURL: String? {
        switch self {
        case .upload:
            return "https://staging.permanent.org:9000"
        default:
            return nil
        }
    }
}
