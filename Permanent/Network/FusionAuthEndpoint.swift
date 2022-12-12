//
//  FusionAuthEndpoint.swift
//  Permanent
//
//  Created by Lucian Cerbu on 08.12.2022.
//

import Foundation

enum FusionAuthEndpoint {
    /// Performs a login with an email & password credentials.
    case login(credentials: LoginCredentials)
}

extension FusionAuthEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .login:
            return "/login"
        }
    }
    
    var method: RequestMethod {
        return .post
    }
    
    var headers: RequestHeaders? {
        return [
            "Authorization": authServiceInfo.authFusionAuthorization,
            "X-FusionAuth-TenantId": authServiceInfo.authTenantId,
            "content-type": "application/json",
        ]
    }
    
    var requestType: RequestType {
        return .data
    }
    
    var responseType: ResponseType {
        return .json
    }
    
    var parameters: RequestParameters? {
        switch self {
        case .login(let credentials):
            return Payloads.loginPayload(for: credentials)
        }
    }
    
    var progressHandler: ProgressHandler? {
        get {
            nil
        }
        set {}
    }
    
    var bodyData: Data? {
        nil
    }
    
    var customURL: String? {
        switch self {
        case .login(_):
            return "\(APIEnvironment.defaultEnv.fusionBaseURL)" + path
        }
    }
}
