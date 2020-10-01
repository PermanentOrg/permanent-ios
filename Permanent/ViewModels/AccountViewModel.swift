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
    func update(for accountId: String, data: UpdateData, csrf: String, then handler: @escaping (RequestStatus) -> Void)
}

extension AccountViewModel: AccountViewModelDelegate {
    func update(for accountId: String, data: UpdateData, csrf: String, then handler: @escaping (RequestStatus) -> Void) {
        let updateOperation = APIOperation(AccountEndpoint.update(accountId: accountId, updateData: data, csrf: csrf))
               
        updateOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                // let status = self.extractLoginStatus(response)
                // handler(status)
                handler(.success)

            case .error:
                handler(.error)

            default:
                break
            }
        }
    }
}
