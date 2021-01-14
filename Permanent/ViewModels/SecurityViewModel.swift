//
//  SecurityViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 13.01.2021.
//  Copyright © 2021 Victory Square Partners. All rights reserved.
//

import Foundation
import UIKit

typealias ChangePasswordCredentials = (password: String,passwordVerify: String,passwordOld: String)

class SecurityViewModel: ViewModelInterface {
    weak var delegate: SecurityViewModelDelegate?
}

protocol SecurityViewModelDelegate: ViewModelDelegateInterface {
    func changePassword(with accountId: String, data: ChangePasswordCredentials, csrf: String, then handler: @escaping (PasswordChangeStatus)-> Void)
}

extension SecurityViewModel:SecurityViewModelDelegate {
    
    func changePassword(with accountId: String, data: ChangePasswordCredentials, csrf: String, then handler: @escaping (PasswordChangeStatus)-> Void) {
        
        let changePasswordOperation = APIOperation(AccountEndpoint.changePassword(accountId: accountId, passwordDetails: data, csrf: csrf))

        changePasswordOperation.execute(in: APIRequestDispatcher()) { result in
            print(result)
            switch result {
            case .json(let response, _):
                guard let model: LoginResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }

                if model.isSuccessful == true {
                   // self.saveStorageData(model)
                    handler(.success)
                } else {
                    guard
                        let message = model.results?.first?.message?.first,
                        let loginError = LoginError(rawValue: message)
                    else {
                        handler(.error(message: .errorMessage))
                        return
                    }

                    if loginError == .mfaToken {
                        handler(.mfaToken)
                    } else {
                        handler(.error(message: loginError.description))
                    }
                }

            case .error:
                handler(.error(message: .errorMessage))

            default:
                break
            }
        }
    }
}
enum PasswordChangeStatus {
    case success
    case mfaToken
    case error(message: String?)
}
