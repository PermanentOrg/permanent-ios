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
    func verify(for credentials: VerifyCodeCredentials, then handler: @escaping (CodeVerificationStatus) -> Void)
}

extension VerificationCodeViewModel: VerificationCodeViewModelDelegate {
    func verify(for credentials: VerifyCodeCredentials, then handler: @escaping (CodeVerificationStatus) -> Void) {
        let requestDispatcher = APIRequestDispatcher()
        let verifyOperation = APIOperation(AuthenticationEndpoint.verify(credentials: credentials))

        verifyOperation.execute(in: requestDispatcher) { result in
            switch result {
            case .json(let response, _):
                let status = self.extractVerificationStatus(response)
                handler(status)
                
            case .error:
                handler(.error)
                
            default:
                break
            }
        }
    }
    
    fileprivate func extractVerificationStatus(_ jsonObject: Any?) -> CodeVerificationStatus {
        guard let json = jsonObject else { return .error }

        let decoder = JSONDecoder()

        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .prettyPrinted)
            let verifyResponse = try decoder.decode(VerifyResponse.self, from: data)

            if let message = verifyResponse.results?.first?.message?.first, message.starts(with: "warning.auth") {
                return .error
            } else {
                return .success
            }

        } catch {
            return .error
        }
    }
}

enum CodeVerificationStatus {
    case success
    case error
}


//warning.auth.token_expired
//warning.auth.token_does_not_match
