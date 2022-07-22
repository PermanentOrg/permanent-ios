//
//  AccountOnboardingViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 03.05.2022.
//

import Foundation

class AccountOnboardingViewModel: ViewModelInterface {
    enum Page {
        case getStarted
        case nameArchive
        case createArchive
        case pendingInvitation
        case acceptedInvitation
        
        var rightButtonTitle: String {
            switch self {
            case .getStarted:
                return "Get Started".localized()
                
            case .createArchive:
                return "Next: Name Archive".localized()
                
            case .nameArchive:
                return "Create Archive".localized()
                
            case .pendingInvitation:
                return "Accept All".localized()
                
            case .acceptedInvitation:
                return ""
            }
        }
        
        var leftButtonTitle: String {
            switch self {
            case .getStarted:
                return ""
                
            case .nameArchive:
                return "Back".localized()
                
            case .createArchive:
                return "Back".localized()
                
            case .pendingInvitation:
                return "Create New Archive".localized()
                
            case .acceptedInvitation:
                return "Create New Archive".localized()
            }
        }
        
        var nextButtonHidden: Bool {
            return self == .acceptedInvitation
        }
    }
    
    static let archiveTypeChanged = NSNotification.Name("AccountOnboardingViewModel.archiveTypeChanged")
    static let archiveNameChanged = NSNotification.Name("AccountOnboardingViewModel.archiveNameChanged")
    
    var account: AccountVOData?
    var accountArchives: [ArchiveVO]? = [] 
    var acceptedArchives: [ArchiveVO]? = []
    
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
    
    var currentPage: Page = .getStarted
    
    var hasBackButton: Bool {
        currentPage != .getStarted
    }
    var nextButtonTitle: String {
        return currentPage.rightButtonTitle
    }
    var backButtonTitle: String {
        return currentPage.leftButtonTitle
    }
    var nextButtonEnabled: Bool {
        switch currentPage {
        case .getStarted: return true
        case .createArchive: return archiveType != nil
        case .nameArchive: return archiveName != nil
        default: return true
        }
    }
    var nextButtonHidden: Bool {
        return currentPage.nextButtonHidden
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
                                UserDefaults.standard.set(-1, forKey: Constants.Keys.StorageKeys.signUpInvitationsAccepted)
                                
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
        guard let accountId: Int = AuthenticationManager.shared.session?.account.accountID else {
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
        AuthenticationManager.shared.session?.selectedArchive = archive
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
                
                if let account = model.results[0].data?[0].accountVO {
                    AuthenticationManager.shared.session?.account = account
                    self.account = account
                    completionBlock(self.account, nil)
                } else {
                    completionBlock(nil, APIError.invalidResponse)
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
    
    func getAccountArchives(_ completionBlock: @escaping ((Error?) -> Void) ) {
        guard let accountId: Int = AuthenticationManager.shared.session?.account.accountID else {
            completionBlock(APIError.unknown)
            return
        }
        
        let getAccountArchivesDataOperation = APIOperation(ArchivesEndpoint.getArchivesByAccountId(accountId: Int(accountId)))
        getAccountArchivesDataOperation.execute(in: APIRequestDispatcher()) { [self] result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(APIError.invalidResponse)
                    return
                }
                
                accountArchives = model.results.first?.data
                
                completionBlock(nil)
                return
                
            case .error:
                completionBlock(APIError.invalidResponse)
                return
                
            default:
                completionBlock(APIError.invalidResponse)
                return
            }
        }
    }
    
    func acceptArchiveOperation(archive: ArchiveVOData, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        let acceptArchiveOperation = APIOperation(ArchivesEndpoint.accept(archiveVO: archive))

        acceptArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(false, APIError.invalidResponse)
                    return
                }

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
    
    func acceptAllPendingArchives(_ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        let dispatchGroup = DispatchGroup()
        var acceptArchivesResult: [Bool] = []
        
        guard let pendingArchives = accountArchives else {
            completionBlock(false, APIError.noData)
            return
        }
        
        for archive in pendingArchives {
            if let pendingArchive = archive.archiveVO, pendingArchive.status == .pending, let pendingArchiveId = pendingArchive.archiveID {
                dispatchGroup.enter()
                acceptArchiveOperation(archive: pendingArchive) { result, error in
                    if result {
                        self.acceptedArchives?.append(ArchiveVO(archiveVO: pendingArchive))
                        acceptArchivesResult.append(true)
                    } else {
                        acceptArchivesResult.append(false)
                    }
                    dispatchGroup.leave()
                }
            }
        }
        
        dispatchGroup.notify(queue: .main) {
            if acceptArchivesResult.contains(false) {
                completionBlock(false, APIError.invalidResponse)
                return
            } else {
                UserDefaults.standard.set(2, forKey: Constants.Keys.StorageKeys.signUpInvitationsAccepted)
                completionBlock(true, nil)
                return
            }
        }
    }
}
