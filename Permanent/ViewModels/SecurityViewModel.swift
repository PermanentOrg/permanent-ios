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

            switch result {
            case .json(let response, _):
                guard let model: ChangePasswordResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }
                if model.isSuccessful == true {
                    handler(.success(message: .passwordChangedSuccessfully))
                } else {
                    guard
                        let message = model.Results?.first?.message?.first,
                        let passwordChangeError = PasswordChangeError(rawValue: message)
                    else {
                        handler(.error(message: .errorMessage))
                        return
                    }
                        handler(.error(message: passwordChangeError.description))
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
    case success(message: String?)
    case error(message: String?)
}
