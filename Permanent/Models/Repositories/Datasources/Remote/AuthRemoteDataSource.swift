//
//  AuthRemoteDataSource.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.12.2022
//

import Foundation

protocol AuthRemoteDataSourceInterface {
    func login(with credentials: LoginCredentials, then handler: @escaping (Result<LoginResponse, Error>) -> Void)
    func loginWithTwoFactor(withEmail email: String, code: String, type: CodeVerificationType, then handler: @escaping (Result<VerifyResponse, Error>) -> Void)
    func forgotPassword(withEmail email: String, then handler: @escaping (Result<ForgotPasswordResponse, Error>) -> Void)
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
    
    func loginWithTwoFactor(withEmail email: String, code: String, type: CodeVerificationType, then handler: @escaping (Result<VerifyResponse, Error>) -> Void) {
        let credentials = VerifyCodeCredentials(email, code, type)
        let verifyOperation = APIOperation(AuthenticationEndpoint.verify(credentials: credentials))
        
        verifyOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: VerifyResponse = JSONHelper.convertToModel(from: response) else {
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
    
    func forgotPassword(withEmail email: String, then handler: @escaping (Result<ForgotPasswordResponse, Error>) -> Void) {
        let forgotPassword = APIOperation(AuthenticationEndpoint.forgotPassword(email: email))
        
        forgotPassword.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: ForgotPasswordResponse = JSONHelper.convertToModel(from: response), model.isSuccessful ?? false else {
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

    func createCredentials(withFullName fullName: String, password: String, email: String, phone: String?, then handler: @escaping (Result<Data, Error>) -> Void) {
        let credentials = CreateCredentials(fullName, password, email, phone)
        let operation = APIOperation(AuthenticationEndpoint.createCredentials(credentials: credentials))
        
        operation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
//                guard let model: VerifyResponse = JSONHelper.convertToModel(from: response) else {
//                    handler(.failure(APIError.parseError))
//                    return
//                }
                handler(.success(response as! Data))
                
            case .error(let e, _):
                handler(.failure(e ?? APIError.clientError))
                
            default:
                handler(.failure(APIError.clientError))
            }
        }
    }
}
