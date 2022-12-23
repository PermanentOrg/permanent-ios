//
//  FusionAuthRepository.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.12.2022
//

import Foundation

class AuthRepository {
    let remoteDataSource: AuthRemoteDataSourceInterface
    
    init(remoteDataSource: AuthRemoteDataSourceInterface = AuthRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }
    
    func login(withUsername username: String, password: String, then handler: @escaping (Result<LoginResponse, Error>) -> Void) {
        let loginCredential = LoginCredentials(username, password)
        
        remoteDataSource.login(with: loginCredential) { result in
            handler(result)
        }
    }
    
    func login(withEmail email: String, code: String, type: CodeVerificationType, then handler: @escaping (Result<VerifyResponse, Error>) -> Void) {
        remoteDataSource.loginWithTwoFactor(withEmail: email, code: code, type: type) { result in
            handler(result)
        }
    }
}
