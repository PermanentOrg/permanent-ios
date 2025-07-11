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
    
    func createAccount(fullName: String, primaryEmail: String, password: String, optIn: Bool = false, inviteCode: String? = nil, then handler: @escaping (Result<(SignUpResponse, AccountVOData), Error>) -> Void) {
        remoteDataSource.createAccount(fullName: fullName, primaryEmail: primaryEmail, password: password, optIn: optIn, inviteCode: inviteCode) { result in
            handler(result)
        }
    }
}
