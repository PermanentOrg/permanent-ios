//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

class AccountViewModel: ViewModelInterface {
    weak var delegate: SignUpViewModelDelegate?
}

protocol SignUpViewModelDelegate: ViewModelDelegateInterface {
    func signUp(with credentials: SignUpCredentials, then handler: @escaping (RequestStatus) -> Void)
}

extension AccountViewModel: SignUpViewModelDelegate {
    func signUp(with credentials: SignUpCredentials, then handler: @escaping (RequestStatus) -> Void) {
        let signUpOperation = APIOperation(AccountEndpoint.signUp(credentials: credentials))

        signUpOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                let modelTuple: (model: SignUpResponse?, status: RequestStatus) = JSONHelper.convertToModel(from: response)

                if modelTuple.model?.isSuccessful == true {
                    handler(.success)
                } else {
                    handler(.error)
                }

            case .error:
                handler(.error)

            default:
                break
            }
        }
    }
}
