//
//  AccountDeleteViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 17.06.2021.
//

import Foundation

class AccountDeleteViewModel: ViewModelInterface {
    
    static let accountDeleteSuccessNotification = Notification.Name("AccountDeleteViewModel.accountDeleteSuccessNotification")
    
    func deleteAccount(completion: @escaping ((Bool) -> Void)) {
        guard let accountId: Int = AuthenticationManager.shared.session?.account.accountID else {
            completion(false)
            return
        }
        
        let deleteOperation = APIOperation(AccountEndpoint.delete(accountId: String(accountId)))

        deleteOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(
                        from: response,
                        with: APIResults<NoDataModel>.decoder
                    ),
                    model.isSuccessful

                else {
                    completion(false)
                    return
                }
                
                if model.isSuccessful {
                    completion(true)
                } else {
                    completion(false)
                }

            case .error:
                completion(false)
                
            default:
                completion(false)
            }
        }
    }
    
    func deletePushToken(then handler: @escaping ServerResponse) {
        guard let token: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.fcmPushTokenKey)
        else {
            handler(.success)
            return
        }
        
        let deleteTokenParams = (token)
        let deleteTokenOperation = APIOperation(DeviceEndpoint.delete(params: deleteTokenParams))

        deleteTokenOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: AuthResponse = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }

                if model.isSuccessful == true {
                    handler(.success)
                } else {
                    handler(.error(message: .errorMessage))
                }

            case .error:
                handler(.error(message: .errorMessage))

            default:
                break
            }
        }
    }
}
