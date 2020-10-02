//
//  LoginViewModel.swift
//  Permanent
//
//  Created by Gabi Tiplea on 14/08/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import UIKit

typealias UpdateData = (email: String, phone: String)

class AccountViewModel: ViewModelInterface {
    weak var delegate: AccountViewModelDelegate?
}

protocol AccountViewModelDelegate: ViewModelDelegateInterface {
    func update(for accountId: String, data: UpdateData, csrf: String, then handler: @escaping ServerResponse)
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
                        handler(.error(message: Translations.errorMessage))
                        return
                    }

                    handler(.error(message: updateError.description))
                }

            case .error:
                handler(.error(message: Translations.errorMessage))

            default:
                break
            }
        }
    }
}
