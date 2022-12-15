//
//  FusionAuthRepository.swift
//  Permanent
//
//  Created by Lucian Cerbu on 12.12.2022
//

import Foundation

class FusionAuthRepository {
    let remoteDataSource: FusionAuthRemoteDataSourceInterface
    
    init(remoteDataSource: FusionAuthRemoteDataSourceInterface = FusionAuthRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }
    
    func login(withUsername username: String, password: String, then handler: @escaping (Result<FusionLoginResponse, Error>) -> Void) {
        let loginCredential = LoginCredentials(username, password)
        
        remoteDataSource.login(with: loginCredential) { result in
            handler(result)
        }
    }
    
    func sendTwoFactor(withId twoFactorId: String, methodId: String, then handler: @escaping (RequestStatus) -> Void) {
        remoteDataSource.sendTwoFactor(withTwoFactorId: twoFactorId, methodId: methodId) { result in
            handler(result)
        }
    }
    
    func login(withTwoFactorId twoFactorId: String, code: String, then handler: @escaping (Result<FusionLoginResponse, Error>) -> Void) {
        remoteDataSource.loginWithTwoFactor(withTwoFactorId: twoFactorId, code: code) { result in
            handler(result)
        }
    }
}
