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
}
