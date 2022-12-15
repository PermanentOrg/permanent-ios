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
    /// Send a message with a code to finish a Multi-Factor flow
    case sendTwoFactorCode(twoFactorId: String, methodId: String)
    /// The Multi-Factor Login API is used to complete the authentication process when a 242 status code is returned by the Login API.
    case loginWithTwoFactor(twoFactorId: String, code: String)
}

extension FusionAuthEndpoint: RequestProtocol {
    var path: String {
        switch self {
        case .login:
            return "/login"
            
        case .sendTwoFactorCode(twoFactorId: let twoFactorId, methodId: _):
            return "/two-factor/send/\(twoFactorId)"
            
        case .loginWithTwoFactor:
            return "/two-factor/login"
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
            
        case .sendTwoFactorCode(twoFactorId: let twoFactorId, methodId: let methodId):
            return Payloads.sendTwoFactorCode(for: twoFactorId, methodId: methodId)
            
        case .loginWithTwoFactor(twoFactorId: let twoFactorId, code: let code):
            return Payloads.loginWithTwoFactor(with: twoFactorId, code: code)
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
        return "\(APIEnvironment.defaultEnv.fusionBaseURL)" + path
    }
}
