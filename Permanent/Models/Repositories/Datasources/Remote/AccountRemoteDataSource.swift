//
//  AccountRemoteDataSource.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 19.01.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import Foundation

protocol AccountRemoteDataSourceInterface {
    func createAccount(fullName: String, primaryEmail: String, password: String, then handler: @escaping (Result<(SignUpResponse, AccountVOData), Error>) -> Void)
}

class AccountRemoteDataSource: AccountRemoteDataSourceInterface {
    func createAccount(fullName: String, primaryEmail: String, password: String, then handler: @escaping (Result<(SignUpResponse, AccountVOData), Error>) -> Void) {
        let credentials = SignUpV2Credentials(fullName, primaryEmail, password)
        let operation = APIOperation(AccountEndpoint.signUpV2(credentials: credentials))
        
        operation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let signupResponse: SignUpResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.failure(APIError.parseError))
                    return
                }
                
                guard let account: AccountVOData = JSONHelper.convertToModel(from: response) else {
                    handler(.failure(APIError.parseError))
                    return
                }
                
                handler(.success((signupResponse, account)))

            case .error(let e, _):
                handler(.failure(e ?? APIError.clientError))

            default:
                handler(.failure(APIError.clientError))
            }
        }
    }
}

class MockAccountRemoteDataSource: AccountRemoteDataSourceInterface {
    var createAccountResponse: Result<(SignUpResponse, AccountVOData), Error>?

    func createAccount(fullName: String, primaryEmail: String, password: String, then handler: @escaping (Result<(SignUpResponse, AccountVOData), Error>) -> Void) {
        if let response = createAccountResponse {
            handler(response)
        } else {
            handler(.failure(NSError(domain: "MockAccountRemoteDataSource", code: -1, userInfo: nil)))
        }
    }
}
