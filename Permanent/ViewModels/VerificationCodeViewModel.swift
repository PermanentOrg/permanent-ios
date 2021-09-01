//
//  VerificationCodeViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/09/2020.
//

import Foundation

class VerificationCodeViewModel: ViewModelInterface {
    weak var delegate: VerificationCodeViewModelDelegate?
    
    var sessionProtocol: NetworkSessionProtocol = APINetworkSession()
}

protocol VerificationCodeViewModelDelegate: ViewModelDelegateInterface {
    func verify(for credentials: VerifyCodeCredentials, then handler: @escaping ServerResponse)
}

extension VerificationCodeViewModel: VerificationCodeViewModelDelegate {
    func verify(for credentials: VerifyCodeCredentials, then handler: @escaping ServerResponse) {
        
        let requestDispatcher = APIRequestDispatcher(networkSession: sessionProtocol)
        let verifyOperation = APIOperation(AuthenticationEndpoint.verify(credentials: credentials))

        verifyOperation.execute(in: requestDispatcher) { result in
            switch result {
            case .json(let response, _):
                guard let model: VerifyResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
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
                        handler(.error(message: .errorMessage))
                        return
                    }
                    
                    handler(.error(message: verifyError.description))
                }
                
            case .error:
                handler(.error(message: .errorMessage))
                
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
        
        if let archiveId = response.results?.first?.data?.first?.accountVO?.defaultArchiveID {
            PreferencesManager.shared.set(archiveId, forKey: Constants.Keys.StorageKeys.defaultArchiveId)
        }
    }
}

enum CodeVerificationType {
    case phone
    case mfa
    
    var value: String {
        switch self {
        case .mfa:
            return Constants.API.TYPE_AUTH_MFAVALIDATION
        case .phone:
            return Constants.API.TYPE_AUTH_PHONE
        }
    }
}
