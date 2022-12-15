//
//  FusionAuthRemoteDataSource.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.12.2022
//

import Foundation

protocol FusionAuthRemoteDataSourceInterface {
    func login(with credentials: LoginCredentials, then handler: @escaping (Result<FusionLoginResponse, Error>) -> Void)
    func sendTwoFactor(withTwoFactorId twoFactorId: String, methodId: String, then handler: @escaping (RequestStatus) -> Void)
    func loginWithTwoFactor(withTwoFactorId twoFactorId: String, code: String, then handler: @escaping (Result<FusionLoginResponse, Error>) -> Void)
}

class FusionAuthRemoteDataSource: FusionAuthRemoteDataSourceInterface {
      func login(with credentials: LoginCredentials, then handler: @escaping (Result<FusionLoginResponse, Error>) -> Void) {
        let loginOperation = APIOperation(FusionAuthEndpoint.login(credentials: credentials))
        
        loginOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: FusionLoginResponse = JSONHelper.decoding(from: response, with: FusionLoginResponse.decoder) else {
                    handler(.failure(APIError.parseError))
                    return
                }
                handler(.success(model))
                
            case .error(let e, _):
                handler(.failure(e ?? APIError.clientError))
                
            default:
                handler(.failure(APIError.clientError))
            }
        }
    }

    func sendTwoFactor(withTwoFactorId twoFactorId: String, methodId: String, then handler: @escaping (RequestStatus) -> Void) {
        let sendTwoFactorCodeOperation = APIOperation(FusionAuthEndpoint.sendTwoFactorCode(twoFactorId: twoFactorId, methodId: methodId))
        
        sendTwoFactorCodeOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(_, _):
                handler(.success)
                
            case .error(_, _):
                handler(.error(message: APIError.clientError.message))
                
            default:
                handler(.error(message: APIError.clientError.message))
            }
        }
    }
    
    func loginWithTwoFactor(withTwoFactorId twoFactorId: String, code: String, then handler: @escaping (Result<FusionLoginResponse, Error>) -> Void) {
        let loginWithTwoFactorOperation = APIOperation(FusionAuthEndpoint.loginWithTwoFactor(twoFactorId: twoFactorId, code: code))
        
        loginWithTwoFactorOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: FusionLoginResponse = JSONHelper.decoding(from: response, with: FusionLoginResponse.decoder) else {
                    handler(.failure(APIError.parseError))
                    return
                }
                handler(.success(model))
                
            case .error(let e, _):
                handler(.failure(e ?? APIError.clientError))
                
            default:
                handler(.failure(APIError.clientError))
            }
        }
    }
}
