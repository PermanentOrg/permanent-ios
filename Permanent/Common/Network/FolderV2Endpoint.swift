//
//  FolderV2Endpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 23.01.2026.
//

import Foundation

enum FolderV2Endpoint {
    case getFolderById(folderId: String, shareToken: String)
    case getFolderChildren(folderId: String, shareToken: String, pageSize: Int)
    /// A flat body of only the edited fields, such as `["sort": option.stelaValue]`. The server
    /// rejects unknown keys.
    case patchFolder(folderId: String, fields: [String: Any])

    /// Requests the whole folder in one page while cursor pagination is deferred. Large but bounded,
    /// so the query isn't rejected; a server-side clamp would silently truncate the listing.
    static let maxChildrenPageSize = 99_999_999
}

extension FolderV2Endpoint: RequestProtocol {
    var path: String { "" }  // Not used - we use customURL
    
    var method: RequestMethod {
        switch self {
        case .getFolderById, .getFolderChildren: return .get
        case .patchFolder: return .patch
        }
    }
    
    var requestType: RequestType { .data }
    
    var responseType: ResponseType { .json }
    
    var parameters: RequestParameters? { nil }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        set { }
    }
    
    var bodyData: Data? {
        switch self {
        case .getFolderById, .getFolderChildren:
            return nil
        case .patchFolder(_, let fields):
            return try? JSONSerialization.data(withJSONObject: fields)
        }
    }
    
    var customURL: String? {
        let baseURL = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .getFolderById(let folderId, _):
            // Canonical plural route; the singular `/folder` alias is deprecated. `pageSize` is required even for
            // one id (400 without it); 9999 also covers a future multi-id call without paging.
            return "\(baseURL)api/v2/folders?folderIds[]=\(folderId)&pageSize=9999"
        case .getFolderChildren(let folderId, _, let pageSize):
            return "\(baseURL)api/v2/folders/\(folderId)/children?pageSize=\(pageSize)"
        case .patchFolder(let folderId, _):
            return "\(baseURL)api/v2/folders/\(folderId)"
        }
    }
    
    var shareToken: String? {
        switch self {
        case .getFolderById(_, let token), .getFolderChildren(_, let token, _):
            return token.isEmpty ? nil : token
        case .patchFolder:
            return nil
        }
    }
    
    var headers: RequestHeaders? {
        return ["Content-Type": "application/json", "Request-Version": "2"]
    }

    /// The reads have V1 failsafes, so a 401 there must not force-logout: it can be a foreign-archive
    /// rejection. The PATCH runs on the session's own archive only, so its 401 really is an expired session.
    var ignoreErrors: Bool {
        switch self {
        case .getFolderById, .getFolderChildren: return true
        case .patchFolder: return false
        }
    }
}
