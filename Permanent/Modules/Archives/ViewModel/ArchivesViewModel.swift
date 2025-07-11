//
//  ArchivesViewModel.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 30.08.2021.
//

import Foundation

class ArchivesViewModel: ViewModelInterface {
    static let closeArchiveSettings = Notification.Name("ArchivesViewModel.closeArchiveSettings")
    static let didChangeArchiveNotification = Notification.Name("ArchivesViewModel.didChangeArchiveNotification")
    
    var account: AccountVOData?
    var defaultArchiveId: Int? { account?.defaultArchiveID }
    
    var allArchives: [ArchiveVOData] = []
    var availableArchives: [ArchiveVOData] {
        return allArchives.filter({ $0.archiveNbr != currentArchive()?.archiveNbr })
    }
    var pendingArchives: [ArchiveVOData] {
        return allArchives.filter({ $0.status == ArchiveVOData.Status.pending })
    }
    var selectableArchives: [ArchiveVOData] {
        return availableArchives.filter({ $0.status == ArchiveVOData.Status.ok })
    }
    
    func getAccountInfo(_ completionBlock: @escaping ((AccountVOData?, Error?) -> Void)) {
        guard let accountId: Int = PermSession.currentSession?.account.accountID else {
            completionBlock(nil, APIError.unknown)
            return
        }
        
        let getUserDataOperation = APIOperation(AccountEndpoint.getUserData(accountId: accountId))
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
                    PermSession.currentSession?.account = account
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
    
    func getAccountArchives(_ completionBlock: @escaping (([ArchiveVO]?, Error?) -> Void) ) {
        guard let accountId: Int = PermSession.currentSession?.account.accountID else {
            completionBlock(nil, APIError.unknown)
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
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                
                let accountArchives = model.results.first?.data
                
                self.allArchives.removeAll()
                var archiveMap: [Int: ArchiveVOData] = [:]
                
                accountArchives?.forEach { archive in
                    if let archiveVOData = archive.archiveVO, 
                       archiveVOData.status != .pending && archiveVOData.status != .unknown,
                       let archiveID = archiveVOData.archiveID {
                        
                        // Handle server-side data corruption by preferring archives with valid names
                        if let existingArchive = archiveMap[archiveID] {
                            // Prefer the archive with a valid (non-nil) name
                            if existingArchive.fullName == nil && archiveVOData.fullName != nil {
                                archiveMap[archiveID] = archiveVOData
                            }
                        } else {
                            archiveMap[archiveID] = archiveVOData
                        }
                    }
                }
                
                // Convert map back to array
                self.allArchives = Array(archiveMap.values)
                completionBlock(accountArchives, nil)
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
    
    func currentArchive() -> ArchiveVOData? {
        return PermSession.currentSession?.selectedArchive
    }
    
    func setCurrentArchive(_ archive: ArchiveVOData) {
        PermSession.currentSession?.selectedArchive = archive
        
        // Save the session to persist the archive selection
        if let session = PermSession.currentSession {
            do {
                try SessionKeychainHandler().saveSession(session)
            } catch {
                print("Failed to save session after archive change")
            }
        }
        
        // Post notification for UI updates
        NotificationCenter.default.post(name: ArchivesViewModel.didChangeArchiveNotification, object: nil)
        
        UploadManager.shared.timer?.fire()
    }
    
    func changeArchive(_ archive: ArchiveVOData, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        NotificationCenter.default.post(name: ArchivesViewModel.closeArchiveSettings, object: self, userInfo: nil)
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
    
    func createArchive(name: String, type: String, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        let createArchiveOperation = APIOperation(ArchivesEndpoint.create(name: name, type: type))
        createArchiveOperation.execute(in: APIRequestDispatcher()) { result in
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
    
    func deleteArchive(archiveId: Int?, archiveNbr: String?, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        guard let archiveId = archiveId, let archiveNbr = archiveNbr else {
            completionBlock(false, APIError.unknown)
            return
        }
        
        let deleteArchiveOperation = APIOperation(ArchivesEndpoint.delete(archiveId: archiveId, archiveNbr: archiveNbr))
        deleteArchiveOperation.execute(in: APIRequestDispatcher()) { result in
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
    
    func pendingArchiveOperation(archive: ArchiveVOData, accept: Bool, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        let createArchiveOperation: APIOperation
        if accept {
            createArchiveOperation = APIOperation(ArchivesEndpoint.accept(archiveVO: archive))
        } else {
            createArchiveOperation = APIOperation(ArchivesEndpoint.decline(archiveVO: archive))
        }
        
        createArchiveOperation.execute(in: APIRequestDispatcher()) { result in
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
}
