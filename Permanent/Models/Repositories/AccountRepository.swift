//
//  AccountRepository.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 19.01.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import Foundation

class AccountRepository {
    let remoteDataSource: AccountRemoteDataSourceInterface
    
    init(remoteDataSource: AccountRemoteDataSource = AccountRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }
    
    func createAccount(fullName: String, primaryEmail: String, subject: String, token: String, then handler: @escaping (Result<SignUpResponse, Error>) -> Void) {
        remoteDataSource.createAccount(fullName: fullName, primaryEmail: primaryEmail, subject: subject, token: token) { result in
            handler(result)
        }
    }
}
