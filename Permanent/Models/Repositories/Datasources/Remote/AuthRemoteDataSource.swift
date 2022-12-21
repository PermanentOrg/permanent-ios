//
//  AuthRemoteDataSource.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.12.2022
//

import Foundation

protocol AuthRemoteDataSourceInterface {
    func login(with credentials: LoginCredentials, then handler: @escaping (Result<LoginResponse, Error>) -> Void)
    func loginWithTwoFactor(withTwoFactorId twoFactorId: String, code: String, then handler: @escaping (Result<FusionLoginResponse, Error>) -> Void)
}

class AuthRemoteDataSource: AuthRemoteDataSourceInterface {
    func login(with credentials: LoginCredentials, then handler: @escaping (Result<LoginResponse, Error>) -> Void) {
        let loginOperation = APIOperation(AuthenticationEndpoint.login(credentials: credentials))
        
        let dispatcher = APIRequestDispatcher()
        dispatcher.ignoresMFAWarning = true
        
        loginOperation.execute(in: dispatcher) { result in
            switch result {
            case .json(let response, _):
                guard let model: LoginResponse = JSONHelper.convertToModel(from: response) else {
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
    
    func loginWithTwoFactor(withTwoFactorId twoFactorId: String, code: String, then handler: @escaping (Result<FusionLoginResponse, Error>) -> Void) {

    }
}
