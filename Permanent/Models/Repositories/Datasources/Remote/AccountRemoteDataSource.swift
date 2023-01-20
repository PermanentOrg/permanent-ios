//
//  AccountRemoteDataSource.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 19.01.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import Foundation

protocol AccountRemoteDataSourceInterface {
    func createAccount(fullName: String, primaryEmail: String, subject: String, token: String, then handler: @escaping (Result<SignUpResponse, Error>) -> Void)
}

class AccountRemoteDataSource: AccountRemoteDataSourceInterface {
    func createAccount(fullName: String, primaryEmail: String, subject: String, token: String, then handler: @escaping (Result<SignUpResponse, Error>) -> Void) {
        let credentials = SignUpV2Credentials(fullName, primaryEmail, subject, token)
        let operation = APIOperation(AccountEndpoint.signUpV2(credentials: credentials))
        
        operation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
//                guard let model: SignUpResponse = JSONHelper.convertToModel(from: response) else {
//                    handler(.failure(APIError.parseError))
//                    return
//                }
                handler(.success(SignUpResponse(token: "", user: SignUpUser(id: "", fullName: "", email: ""))))

            case .error(let e, _):
                handler(.failure(e ?? APIError.clientError))

            default:
                handler(.failure(APIError.clientError))
            }
        }
    }
}
