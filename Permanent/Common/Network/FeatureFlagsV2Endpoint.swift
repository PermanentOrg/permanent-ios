//
//  FeatureFlagsV2Endpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import Foundation

/// GET /api/v2/feature-flags: the names of the server's switches that are on for everyone. No sign-in is needed.
enum FeatureFlagsV2Endpoint {
    case list
}

extension FeatureFlagsV2Endpoint: RequestProtocol {
    var path: String { "" }
    var method: RequestMethod { .get }
    var requestType: RequestType { .data }
    var responseType: ResponseType { .json }
    var parameters: RequestParameters? { nil }
    var progressHandler: ProgressHandler? {
        get { nil }
        set { }
    }
    var bodyData: Data? { nil }
    var customURL: String? { "\(APIEnvironment.defaultEnv.apiServer)api/v2/feature-flags" }
    var skipAuthentication: Bool { true }
}
