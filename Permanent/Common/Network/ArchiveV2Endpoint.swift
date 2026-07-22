//
//  ArchiveV2Endpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 21.07.2026.
//

import Foundation

enum ArchiveV2Endpoint {
    /// Lists the caller's archives (filtered by membership role). Each returned archive
    /// carries a `rootFolderId`, which bootstraps V2 folder navigation WITHOUT a V1
    /// `/folder/getRoot` call — the keystone dependency VSP-1787 removes.
    case searchArchives(callerMembershipRoles: [String], pageSize: Int)

    /// The full set of archive-membership roles. The archives search requires at least one
    /// of `searchQuery` / `callerMembershipRole`; passing every role returns every archive
    /// the caller belongs to, so the currently-selected archive resolves regardless of the
    /// caller's role on it (owner / manager / curator / editor / contributor / viewer).
    static let allMembershipRoles = ["owner", "manager", "curator", "editor", "contributor", "viewer"]

    /// Single-page size, large enough to hold any realistic membership count (cursor
    /// pagination is deferred). A caller with more archives than this simply won't find the
    /// target on page one and falls back to the V1 `getRoot` bootstrap.
    static let defaultPageSize = 100
}

extension ArchiveV2Endpoint: RequestProtocol {
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
        case .searchArchives(let roles, let pageSize):
            // Repeated `callerMembershipRole=<role>` params — the same form the server's
            // own paginated `nextPage` emits, and what URLComponents produces from
            // multiple same-named query items. URLComponents percent-encodes the values.
            var components = URLComponents(string: "\(baseURL)api/v2/archives")
            var items = roles.map { URLQueryItem(name: "callerMembershipRole", value: $0) }
            items.append(URLQueryItem(name: "pageSize", value: "\(pageSize)"))
            components?.queryItems = items
            return components?.url?.absoluteString
        }
    }

    var headers: RequestHeaders? {
        return ["Content-Type": "application/json", "Request-Version": "2"]
    }

    /// Root discovery has an automatic V1 `getRoot` failsafe, so a 401 here must not
    /// force-logout (mirrors `FolderV2Endpoint`): it can be a foreign-archive rejection,
    /// while a genuine session expiry still surfaces through the non-exempt V1 fallback
    /// call that immediately follows.
    var ignoreErrors: Bool { true }
}
