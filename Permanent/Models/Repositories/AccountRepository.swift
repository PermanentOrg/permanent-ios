//
//  AccountRepository.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 19.01.2023.
//

import Foundation

class AccountRepository {
    let remoteDataSource: AccountRemoteDataSourceInterface
    
    init(remoteDataSource: AccountRemoteDataSourceInterface = AccountRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }
    
    func createAccount(fullName: String, primaryEmail: String, password: String, then handler: @escaping (Result<(SignUpResponse, AccountVOData), Error>) -> Void) {
        remoteDataSource.createAccount(fullName: fullName, primaryEmail: primaryEmail, password: password) { result in
            handler(result)
        }
    }
}
