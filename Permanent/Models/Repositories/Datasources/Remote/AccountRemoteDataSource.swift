//
//  AccountRemoteDataSource.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 19.01.2023.
//  Copyright © 2023 Victory Square Partners. All rights reserved.
//

import Foundation

protocol AccountRemoteDataSourceInterface {
    func post(agreed: Bool, fullName: String, optIn: Bool, primaryEmail: String, subject: String)
}

class AccountRemoteDataSource: AccountRemoteDataSourceInterface {
    func post(agreed: Bool, fullName: String, optIn: Bool, primaryEmail: String, subject: String) {
//        let credentials = CreateCredentials(fullName, password, email, phone)
//        let operation = APIOperation(AuthenticationEndpoint.createCredentials(credentials: credentials))
//
//        operation.execute(in: APIRequestDispatcher()) { result in
//            switch result {
//            case .json(let response, _):
////                guard let model: VerifyResponse = JSONHelper.convertToModel(from: response) else {
////                    handler(.failure(APIError.parseError))
////                    return
////                }
//                handler(.success(response as! Data))
//
//            case .error(let e, _):
//                handler(.failure(e ?? APIError.clientError))
//
//            default:
//                handler(.failure(APIError.clientError))
//            }
//        }
        
    }
}
