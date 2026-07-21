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

    /// Interim page size for `getFolderChildren`: request the whole folder in a single
    /// page (cursor pagination is deferred). Large-but-bounded so the server can't reject
    /// an absurd query value. If the server ever clamps below a folder's real size, the
    /// listing/dedupe would silently truncate — revisit with real pagination then.
    static let maxChildrenPageSize = 99_999_999
}

extension FolderV2Endpoint: RequestProtocol {
    var path: String { "" }  // Not used - we use customURL
    
    var method: RequestMethod { .get }
    
    var requestType: RequestType { .data }
    
    var responseType: ResponseType { .json }
    
    var parameters: RequestParameters? { nil }
    
    var progressHandler: ProgressHandler? {
        get { nil }
        set { }
    }
    
    var bodyData: Data? { nil }
    
    var customURL: String? {
        let baseURL = APIEnvironment.defaultEnv.apiServer
        switch self {
        case .getFolderById(let folderId, _):
            // Canonical plural route. The singular `/folder` form is a deprecated
            // backend alias that hits the same handler; we use the documented one.
            return "\(baseURL)api/v2/folders?folderIds[]=\(folderId)"
        case .getFolderChildren(let folderId, _, let pageSize):
            return "\(baseURL)api/v2/folders/\(folderId)/children?pageSize=\(pageSize)"
        }
    }
    
    var shareToken: String? {
        switch self {
        case .getFolderById(_, let token), .getFolderChildren(_, let token, _):
            return token.isEmpty ? nil : token
        }
    }
    
    var headers: RequestHeaders? {
        return ["Content-Type": "application/json", "Request-Version": "2"]
    }

    /// Both cases are reads with V1 failsafes (navigation and the upload dedupe fall back
    /// to V1 on any error), so a 401 here must not force-logout: it can be a foreign-archive
    /// rejection, while a genuine session expiry still surfaces through the non-exempt V1
    /// fallback call that immediately follows.
    var ignoreErrors: Bool { true }
}
