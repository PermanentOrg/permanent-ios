//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation

class LoginViewModel: ViewModelInterface {
    weak var delegate: LoginViewModelDelegate?
}

protocol LoginViewModelDelegate: ViewModelDelegateInterface {
    func login(with credentials: LoginCredentials, then handler: @escaping (Bool) -> Void)
}

extension LoginViewModel: LoginViewModelDelegate {
    func login(with credentials: LoginCredentials, then handler: @escaping (Bool) -> Void) {
        let requestDispatcher = APIRequestDispatcher()
        let loginOperation = APIOperation(LoginEndpoint.login(credentials: credentials))

        loginOperation.execute(in: requestDispatcher) { result in
            switch result {
            case .json(let response, _):
                print("Response", response)
                handler(true)

            case .error(let error, _):
                print("Error", error?.localizedDescription)
                handler(false)

            default:
                break
            }
        }
    }
}
