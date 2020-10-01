//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 17/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation
import UIKit.UIAlertController

class LoginViewModel: ViewModelInterface {
    weak var delegate: LoginViewModelDelegate?
}

protocol LoginViewModelDelegate: ViewModelDelegateInterface {
    func login(with credentials: LoginCredentials, then handler: @escaping (LoginStatus) -> Void)
    func forgotPassword(email: String, then handler: @escaping (String?, RequestStatus) -> Void)
    func signUp(with credentials: SignUpCredentials, then handler: @escaping (RequestStatus) -> Void)
}

extension LoginViewModel: LoginViewModelDelegate {
    func login(with credentials: LoginCredentials, then handler: @escaping (LoginStatus) -> Void) {
        let loginOperation = APIOperation(AuthenticationEndpoint.login(credentials: credentials))

        loginOperation.execute(in: APIRequestDispatcher()) { result in
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

    func forgotPassword(email: String, then handler: @escaping (String?, RequestStatus) -> Void) {
        let forgotPasswordOperation = APIOperation(AuthenticationEndpoint.forgotPassword(email: email))

        forgotPasswordOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                let modelTuple: (model: LoginResponse?, status: RequestStatus) = self.convertToModel(from: response)
                if modelTuple.model?.isSuccessful == true {
                    handler(email, .success)
                } else {
                    handler(nil, .error)
                }

            case .error:
                handler(nil, .error)

            default:
                break
            }
        }
    }
    
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

    func createEmailInputAlert(then handler: @escaping (String?, RequestStatus) -> Void) -> UIAlertController {
        let alert = UIAlertController(title: Translations.resetPassword, message: nil, preferredStyle: .alert)

        alert.addTextField(configurationHandler: { textField in
            textField.placeholder = "Enter your email here"
        })

        alert.addAction(UIAlertAction(title: Translations.cancel, style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: Translations.ok, style: .default, handler: { _ in
            guard let email: String = alert.textFields?.first?.text else { return }
            self.forgotPassword(email: email, then: handler)
        }))

        return alert
    }

    // TODO: Convert to typealias
    func convertToModel<T: Decodable>(from object: Any?) -> (model: T?, status: RequestStatus) {
        guard let json = object else { return (nil, .error) }

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            let decodedModel = try JSONDecoder().decode(T.self, from: data)
            return (decodedModel, .success)
        } catch {
            return (nil, .error)
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

enum RequestStatus {
    case success
    case error
}
