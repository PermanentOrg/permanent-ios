//
//  AccountDeleteViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 17.06.2021.
//

import Foundation

class AccountDeleteViewModel: ViewModelInterface {
    
    func deleteAccount(completion: @escaping ((Bool) -> Void)) {
        guard let accountId: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey),
              let csrf: String = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.csrfStorageKey) else {
            completion(false)
            return
        }
        
        let deleteOperation = APIOperation(AccountEndpoint.delete(accountId: String(accountId), csrf: csrf))

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
    
}
