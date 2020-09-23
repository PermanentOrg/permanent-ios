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
    func login(with credentials: LoginCredentials, then handler: @escaping (LoginStatus) -> Void)
}

extension LoginViewModel: LoginViewModelDelegate {
    func login(with credentials: LoginCredentials, then handler: @escaping (LoginStatus) -> Void) {
        let requestDispatcher = APIRequestDispatcher()
        let loginOperation = APIOperation(LoginEndpoint.login(credentials: credentials))

        loginOperation.execute(in: requestDispatcher) { result in
            switch result {
            case .json(let response, _):

                let status = self.extractLoginStatus(response)
                handler(status)

            case .error:
                handler(.error)

            default:
                break
            }
        }
    }

    fileprivate func extractLoginStatus(_ jsonObject: Any?) -> LoginStatus {
        guard let json = jsonObject else { return .error }

        let decoder = JSONDecoder()

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            let loginResponse = try decoder.decode(LoginResponse.self, from: data)

            if let message = loginResponse.results?.first?.message?.first, message == "warning.auth.mfaToken" {
                return .mfaToken
            } else {
                return .success
            }

        } catch {
            return .error
        }
    }
}

enum LoginStatus {
    case success
    case error
    case mfaToken
}
