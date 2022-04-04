//
//  PublicGalleryViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.03.2022.
//

import Foundation

class PublicGalleryViewModel: ViewModelInterface {
    
    var account: AccountVOData?
    var defaultArchiveId: Int? { account?.defaultArchiveID }
    
    var allArchives: [ArchiveVOData] = []
    var availableArchives: [ArchiveVOData] {
        return allArchives.filter({ $0.archiveNbr != currentArchive()?.archiveNbr })
    }
    var userPublicArchives: [ArchiveVOData] {
        return allArchives.filter({ $0.archiveVOPublic == 1 })
    }
    var publicArchives: [ArchiveVOData] = []
    
    var selectableArchives: [ArchiveVOData] {
        return availableArchives.filter({ $0.status == ArchiveVOData.Status.ok })
    }
    var publicLocalArchives: [ArchiveVOData] {
        return allArchives.filter({ $0.status == ArchiveVOData.Status.pending })
    }
    
    func currentArchive() -> ArchiveVOData? {
        return try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive)
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
    
    func getAccountArchives(_ completionBlock: @escaping (([ArchiveVO]?, Error?) -> Void) ) {
        guard let accountId: Int = PreferencesManager.shared.getValue(forKey: Constants.Keys.StorageKeys.accountIdStorageKey) else {
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
                accountArchives?.forEach { archive in
                    if let archiveVOData = archive.archiveVO, archiveVOData.status != .pending || archiveVOData.status != .unknown {
                        self.allArchives.append(archiveVOData)
                    }
                }
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
    
    func getPopularArchives(_ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        let getJson = RCValues.getPublicArchives()
        completionBlock(true, nil)
    }
}
