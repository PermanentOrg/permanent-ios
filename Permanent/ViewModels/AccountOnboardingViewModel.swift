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
                self.updateAccount(withDefaultArchiveId: archiveID) { [self] accountVO, error in
                    if accountVO != nil {
                        changeArchive(archiveVO) { success, error in
                            if success {
                                completionBlock(.success)
                            } else {
                                completionBlock(.error(message: .errorMessage))
                            }
                        }
                    } else {
                        completionBlock(.error(message: .errorMessage))
                    }
                }
            } else {
                completionBlock(.error(message: .errorMessage))
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
                    let model: APIResults<AccountVO> = JSONHelper.decoding(from: response, with: APIResults<AccountVO>.decoder),
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
    
    func changeArchive(_ archive: ArchiveVOData, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        guard let archiveId = archive.archiveID, let archiveNbr = archive.archiveNbr else {
            completionBlock(false, APIError.unknown)
            return
        }
        
        let changeArchiveOperation = APIOperation(ArchivesEndpoint.change(archiveId: archiveId, archiveNbr: archiveNbr))
        changeArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(false, APIError.invalidResponse)
                    return
                }
                self.setCurrentArchive(archive)
                completionBlock(true, nil)
                return
                
            case .error:
                completionBlock(false, APIError.invalidResponse)
                return
                
            default:
                completionBlock(false, APIError.invalidResponse)
                return
            }
        }
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
