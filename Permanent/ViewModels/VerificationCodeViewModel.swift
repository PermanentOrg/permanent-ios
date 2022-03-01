//
//  VerificationCodeViewModel.swift
//  Permanent
//
//  Created by Adrian Creteanu on 22/09/2020.
//

import Foundation

enum CodeVerificationType {
    case phone
    case mfa
    
    var value: String {
        switch self {
        case .mfa:
            return Constants.API.typeAuthMFAValidation
            
        case .phone:
            return Constants.API.typeAuthPhone
        }
    }
}

protocol VerificationCodeViewModelDelegate: ViewModelDelegateInterface {
    func verify(for credentials: VerifyCodeCredentials, then handler: @escaping ServerResponse)
}

class VerificationCodeViewModel: ViewModelInterface {
    weak var delegate: VerificationCodeViewModelDelegate?
    
    var sessionProtocol: NetworkSessionProtocol = APINetworkSession()
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
                    
                    self.getAccountArchives(then: handler)
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
    
    func getAccountArchives(then handler: @escaping ServerResponse) {
        guard let accountId: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey) else {
            handler(.error(message: .errorMessage))
            return
        }
        
        let getAccountArchivesDataOperation = APIOperation(ArchivesEndpoint.getArchivesByAccountId(accountId: Int(accountId)))
        getAccountArchivesDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    handler(.error(message: .errorMessage))
                    return
                }
                
                let accountArchives = model.results.first?.data
                if let defaultArchive = accountArchives?.first(where: { $0.archiveVO?.archiveID == PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.defaultArchiveId) })?.archiveVO {
                    self.setCurrentArchive(defaultArchive)
                }
                
                handler(.success)
                return
                
            case .error:
                handler(.error(message: .errorMessage))
                return
                
            default:
                handler(.error(message: .errorMessage))
                return
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
        
        if let fullName = response.results?.first?.data?.first?.accountVO?.fullName {
            PreferencesManager.shared.set(fullName, forKey: Constants.Keys.StorageKeys.nameStorageKey)
        }
    }
    
    func setCurrentArchive(_ archive: ArchiveVOData) {
        do {
            try PreferencesManager.shared.setCodableObject(archive, forKey: Constants.Keys.StorageKeys.archive)
        } catch {
            print(error)
        }
    }
}
