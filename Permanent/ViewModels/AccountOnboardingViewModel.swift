//
//  AccountOnboardingViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 03.05.2022.
//

import Foundation

class AccountOnboardingViewModel: ViewModelInterface {
    static let archiveTypeChanged = NSNotification.Name("AccountOnboardingViewModel.archiveTypeChanged")
    static let archiveNameChanged = NSNotification.Name("AccountOnboardingViewModel.archiveNameChanged")
    
    var account: AccountVOData?
    
    var archiveType: ArchiveType? {
        didSet {
            NotificationCenter.default.post(name: Self.archiveTypeChanged, object: self, userInfo: nil)
        }
    }
    var archiveName: String? {
        didSet {
            NotificationCenter.default.post(name: Self.archiveNameChanged, object: self, userInfo: nil)
        }
    }
    
    var currentPage = 0
    
    var hasBackButton: Bool {
        currentPage != 0
    }
    var nextButtonTitle: String {
        switch currentPage {
        case 0: return "Get Started".localized()
        case 1: return "Next: Name Archive".localized()
        case 2: return "Create Archive".localized()
        default: return ""
        }
    }
    var nextButtonEnabled: Bool {
        switch currentPage {
        case 0: return true
        case 1: return archiveType != nil
        case 2: return archiveName != nil
        default: return true
        }
    }
    
    func finishOnboard(_ completionBlock: @escaping ServerResponse) {
        guard let archiveName = archiveName, let archiveType = archiveType else {
            completionBlock(.error(message: .errorMessage))
            return
        }

        createArchive(name: archiveName, type: archiveType.rawValue) { archiveVO, error in
            if let archiveVO = archiveVO, let archiveID = archiveVO.archiveID {
                self.getSessionAccount { status in
                    print(error)
                }
//                self.updateAccount(withDefaultArchiveId: archiveID) { accountVO, error in
//                    if accountVO != nil {
//                        self.setCurrentArchive(archiveVO)
//
                        completionBlock(.success)
//                    } else {
//                        completionBlock(.error(message: .errorMessage))
//                    }
//                }
            } else {
                completionBlock(.error(message: .errorMessage))
            }
        }
    }
    
    func getSessionAccount(then handler: @escaping ServerResponse) {
        let op = APIOperation(AccountEndpoint.getSessionAccount)
        
        let apiDispatch = APIRequestDispatcher()
        op.execute(in: apiDispatch) { result in
            switch result {
            case .json(let response, _):
                guard let model: APIResults<AccountVO> = JSONHelper.convertToModel(from: response) else {
                    handler(.error(message: .errorMessage))
                    return
                }

                if model.isSuccessful == true {
                    PreferencesManager.shared.set(1, forKey: Constants.Keys.StorageKeys.modelVersion)
                    
                    if let email = model.results.first?.data?.first?.accountVO?.primaryEmail {
                        PreferencesManager.shared.set(email, forKey: Constants.Keys.StorageKeys.emailStorageKey)
                    }

                    if let accountId = model.results.first?.data?.first?.accountVO?.accountID {
                        PreferencesManager.shared.set(accountId, forKey: Constants.Keys.StorageKeys.accountIdStorageKey)
                    }
                    
                    if let archiveId = model.results.first?.data?.first?.accountVO?.defaultArchiveID {
                        PreferencesManager.shared.set(archiveId, forKey: Constants.Keys.StorageKeys.defaultArchiveId)
                    }
                    
                    if let fullName = model.results.first?.data?.first?.accountVO?.fullName {
                        PreferencesManager.shared.set(fullName, forKey: Constants.Keys.StorageKeys.nameStorageKey)
                    }
                    
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
    
    func getAccountInfo(_ completionBlock: @escaping ((AccountVOData?, Error?) -> Void)) {
        guard let accountId: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey) else {
            completionBlock(nil, APIError.unknown)
            return
        }
        
        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: String(accountId)))
        getUserDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                self.account = model.results[0].data?[0].accountVO
                completionBlock(self.account, nil)
                return
                
            case .error:
                completionBlock(nil, APIError.invalidResponse)
                return
                
            default:
                completionBlock(nil, APIError.invalidResponse)
                return
            }
        }
    }
    
    func setCurrentArchive(_ archive: ArchiveVOData) {
        try? PreferencesManager.shared.setCodableObject(archive, forKey: Constants.Keys.StorageKeys.archive)
    }
    
    func createArchive(name: String, type: String, _ completionBlock: @escaping ((ArchiveVOData?, Error?) -> Void)) {
        let createArchiveOperation = APIOperation(ArchivesEndpoint.create(name: name, type: type))
        createArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<ArchiveVO>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                
                if let archiveVO = model.results[0].data?[0].archiveVO {
                    completionBlock(archiveVO, APIError.invalidResponse)
                } else {
                    completionBlock(nil, nil)
                }
                
                return
                
            case .error:
                completionBlock(nil, APIError.invalidResponse)
                return
                
            default:
                completionBlock(nil, APIError.invalidResponse)
                return
            }
        }
    }
    
    func updateAccount(withDefaultArchiveId archiveId: Int, _ completionBlock: @escaping ((AccountVOData?, Error?) -> Void)) {
        account?.defaultArchiveID = archiveId
        
        guard let accountVO = account else {
            completionBlock(nil, APIError.unknown)
            return
        }
        
        let updateAccountOperation = APIOperation(AccountEndpoint.update(accountVO: accountVO))
        updateAccountOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                
                PreferencesManager.shared.set(archiveId, forKey: Constants.Keys.StorageKeys.defaultArchiveId)
                
                self.account = model.results[0].data?[0].accountVO
                completionBlock(self.account, nil)
                return
                
            case .error:
                completionBlock(nil, APIError.invalidResponse)
                return
                
            default:
                completionBlock(nil, APIError.invalidResponse)
                return
            }
        }
    }
    
}
