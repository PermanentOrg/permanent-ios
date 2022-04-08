//
//  PublicGalleryViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.03.2022.
//

import Foundation

class PublicGalleryViewModel: ViewModelInterface {
    var allArchives: [ArchiveVOData] = []
    var availableArchives: [ArchiveVOData] {
        return allArchives.filter({ $0.archiveNbr != currentArchive()?.archiveNbr })
    }
    var userPublicArchives: [ArchiveVOData] {
        return allArchives.filter({ $0.archiveVOPublic == 1 })
    }
    var publicArchives: [ArchiveVOData] = []
    
    func currentArchive() -> ArchiveVOData? {
        return try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive)
    }
    
    func getArchives(_ completionBlock: @escaping ((Error?) -> Void)) {
        getAccountArchives { _, error in
            completionBlock(error)
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
    
    func getPopularArchives(_ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        let getJson = RCValues.getPublicArchives()
        completionBlock(true, nil)
    }
    
    func publicProfileURL(archiveNbr: String?) -> URL? {
        let baseURLString = APIEnvironment.defaultEnv.publicURL
        let url: URL
        
        guard let archiveNbr = archiveNbr else { return nil }
        
        url = URL(string: "\(baseURLString)/archive/\(archiveNbr)/profile")!
        
        return url
    }
}
