//
//  VerificationCodeViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/09/2020.
//  Copyright © 2020 Lucian Cerbu. All rights reserved.
//

import Foundation

class VerificationCodeViewModel: ViewModelInterface {
    weak var delegate: VerificationCodeViewModelDelegate?
}

protocol VerificationCodeViewModelDelegate: ViewModelDelegateInterface {
    func verify(for credentials: VerifyCodeCredentials, then handler: @escaping (Bool) -> Void)
}

extension VerificationCodeViewModel: VerificationCodeViewModelDelegate {
    func verify(for credentials: VerifyCodeCredentials, then handler: @escaping (Bool) -> Void) {
        let requestDispatcher = APIRequestDispatcher()
        let verifyOperation = APIOperation(LoginEndpoint.verify(credentials: credentials))

        verifyOperation.execute(in: requestDispatcher) { result in
            switch result {
            case .json(let response, _):
                break
                
            default:
                break
            }
        }
    }
}
