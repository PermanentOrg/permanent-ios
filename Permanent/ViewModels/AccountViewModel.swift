//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//

import UIKit

typealias UpdateData = (email: String, phone: String)

class AccountViewModel: ViewModelInterface {
    weak var delegate: AccountViewModelDelegate?
}

protocol AccountViewModelDelegate: ViewModelDelegateInterface {
    func update(for accountId: String, data: UpdateData, csrf: String, then handler: @escaping ServerResponse)
    func sendVerificationCodeSMS(accountId: String, email: String, then handler: @escaping ServerResponse)
}

extension AccountViewModel: AccountViewModelDelegate {
    func update(for accountId: String, data: UpdateData, csrf: String, then handler: @escaping ServerResponse) {
        let updateOperation = APIOperation(AccountEndpoint.update(accountId: accountId, updateData: data, csrf: csrf))

        updateOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                let model: AccountUpdateResponse? = JSONHelper.convertToModel(from: response)

                if model?.isSuccessful == true {
                    handler(.success)
                } else {
                    guard
                        let message = model?.results?.first?.message?.first,
                        let updateError = AccountUpdateError(rawValue: message)
                    else {
                        handler(.error(message: .errorMessage))
                        return
                    }

                    handler(.error(message: updateError.description))
                }

            case .error:
                handler(.error(message: .errorMessage))

            default:
                break
            }
        }
    }
    
    func sendVerificationCodeSMS(accountId: String, email: String, then handler: @escaping ServerResponse) {
        let sendSMSOperation = APIOperation(AccountEndpoint.sendVerificationCodeSMS(accountId: accountId, email: email))

        sendSMSOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                let model: AccountUpdateResponse? = JSONHelper.convertToModel(from: response)

                if model?.isSuccessful == true {
                    handler(.success)
                } else {
                    handler(.error(message: .errorMessage))
                }

            case .error(let error):
                print("error ", error.0)
                handler(.error(message: .errorMessage))

            default:
                break
            }
        }
    }
}
