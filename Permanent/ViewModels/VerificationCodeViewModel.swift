//
//  VerificationCodeViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/09/2020.
//

import Foundation

class VerificationCodeViewModel: ViewModelInterface {
    weak var delegate: VerificationCodeViewModelDelegate?
}

protocol VerificationCodeViewModelDelegate: ViewModelDelegateInterface {
    func verify(for credentials: VerifyCodeCredentials, then handler: @escaping ServerResponse)
}

extension VerificationCodeViewModel: VerificationCodeViewModelDelegate {
    func verify(for credentials: VerifyCodeCredentials, then handler: @escaping ServerResponse) {
        let requestDispatcher = APIRequestDispatcher()
        let verifyOperation = APIOperation(AuthenticationEndpoint.verify(credentials: credentials))

        verifyOperation.execute(in: requestDispatcher) { result in
            switch result {
            case .json(let response, _):
                guard let model: VerifyResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: Translations.errorMessage))
                    return
                }
                
                if model.isSuccessful == true {
                    self.saveStorageData(model)
                    handler(.success)
                } else {
                    guard
                        let message = model.results?.first?.message?.first,
                        let verifyError = VerifyCodeError(rawValue: message)
                    else {
                        handler(.error(message: Translations.errorMessage))
                        return
                    }
                    
                    handler(.error(message: verifyError.description))
                }
                
            case .error:
                handler(.error(message: Translations.errorMessage))
                
            default:
                break
            }
        }
    }
    
    fileprivate func saveStorageData(_ response: VerifyResponse) {
        if let email = response.results?.first?.data?.first?.accountVO?.primaryEmail {
            PreferencesManager.shared.set(email, forKey: Constants.Keys.StorageKeys.emailStorageKey)
        }
        
        if let accountId = response.results?.first?.data?.first?.accountVO?.accountID {
            PreferencesManager.shared.set(accountId, forKey: Constants.Keys.StorageKeys.accountIdStorageKey)
        }
        
        if let csrf = response.csrf {
            PreferencesManager.shared.set(csrf, forKey: Constants.Keys.StorageKeys.csrfStorageKey)
        }
    }
}
