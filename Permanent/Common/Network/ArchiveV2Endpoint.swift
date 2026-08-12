//
//  ArchiveV2Endpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 21.07.2026.
//

import Foundation

enum ArchiveV2Endpoint {
    /// Lists the caller's archives, filtered by membership role. Each carries a `rootFolderId`, which
    /// bootstraps V2 navigation without a V1 `getRoot` call.
    case searchArchives(callerMembershipRoles: [String], pageSize: Int)

    /// Every archive-membership role. The search requires a query or a role, so passing all of them
    /// resolves the selected archive whatever the caller's role on it.
    static let allMembershipRoles = ["owner", "manager", "curator", "editor", "contributor", "viewer"]

    /// One page, sized above any realistic membership count while cursor pagination is deferred. A
    /// caller with more archives falls back to the V1 `getRoot` bootstrap.
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
            // Repeated `callerMembershipRole` params, the same form the server's own `nextPage` emits and
            // what `URLComponents` produces from same-named items. It percent-encodes the values.
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

    /// Root discovery has a V1 failsafe, so a 401 here must not force-logout — it can be a
    /// foreign-archive rejection, and real expiry surfaces through the V1 call that follows.
    var ignoreErrors: Bool { true }
}
