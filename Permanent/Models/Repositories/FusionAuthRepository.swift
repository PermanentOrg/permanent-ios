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
    
    func login(withTwoFactorId twoFactorId: String, code: String, then handler: @escaping (Result<FusionLoginResponse, Error>) -> Void) {
        remoteDataSource.loginWithTwoFactor(withTwoFactorId: twoFactorId, code: code) { result in
            handler(result)
        }
    }
}
