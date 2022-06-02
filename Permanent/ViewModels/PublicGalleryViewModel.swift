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
    var userHasPublicArchives: Bool {
        return !allArchives.filter({ $0.archiveVOPublic == 1 }).isEmpty
    }
    
    var publicArchives: [ArchiveVOData] = []
    var searchPublicArchives: [ArchiveVOData] = []
    
    var searchTimer: Timer?
    var searchQuery: String = ""
    var searchOperation: APIOperation?
    
    var sessionProtocol: NetworkSessionProtocol = APINetworkSession()
    
    func currentArchive() -> ArchiveVOData? {
        return try? PreferencesManager.shared.getCodableObject(forKey: Constants.Keys.StorageKeys.archive)
    }
    
    func getArchives(_ completionBlock: @escaping ((Error?) -> Void)) {
        let group = DispatchGroup()
        var storedError: Error?
        
        group.enter()
        getAccountArchives { _, error in
            if error != nil {
                storedError = error
            }
            group.leave()
        }
        
        group.enter()
        getPopularArchives { error in
            if error != nil {
                storedError = error
            }
            group.leave()
        }
        
        group.notify(queue: DispatchQueue.main) {
            completionBlock(nil)
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
    
    func getPopularArchives(_ completionBlock: @escaping ((Error?) -> Void)) {
        let getJson = RCValues.getPublicArchives()
        let archivesNbr: [String] = getJson.compactMap({$0.archiveNbr})
        
        let getArchivesDataOperation = APIOperation(ArchivesEndpoint.getArchivesByArchivesNbr(archivesNbr: archivesNbr))
        getArchivesDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(APIError.invalidResponse)
                    return
                }
                
                let archives = model.results
                
                self.publicArchives.removeAll()
                for archive in archives {
                    if let archiveVOData = archive.data?.first,
                        let archiveVO = archiveVOData.archiveVO,
                        archiveVO.status != .pending || archiveVO.status != .unknown {
                        self.publicArchives.append(archiveVO)
                    }
                }
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
    
    func publicProfileURL(archiveNbr: String?) -> URL? {
        let baseURLString = APIEnvironment.defaultEnv.publicURL
        let url: URL
        
        guard let archiveNbr = archiveNbr, archiveNbr.isNotEmpty else { return nil }
        
        url = URL(string: "\(baseURLString)/archive/\(archiveNbr)/profile")!
        
        return url
    }
    
    func searchArchives(byQuery query: String, handler: @escaping ServerResponse) {
        searchTimer?.invalidate()
        searchQuery = query

        searchTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { timer in
            self.reallySearchArchives(handler: handler)
            
            self.searchTimer?.invalidate()
            self.searchTimer = nil
        })
    }
    
    func reallySearchArchives(handler: @escaping ServerResponse) {
        searchOperation?.cancel()
        searchOperation = nil
        guard searchQuery.count > 0 else {
            self.searchPublicArchives.removeAll()
            
            handler(.success)
            return
        }
        let apiDispatch = APIRequestDispatcher(networkSession: sessionProtocol)
        
        let searchArchivesDataOperation = APIOperation(ArchivesEndpoint.searchArchive(searchAfter: searchQuery))
        searchArchivesDataOperation.execute(in: apiDispatch) { result in
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
                
                self.searchPublicArchives.removeAll()
                accountArchives?.forEach { archive in
                    if let archiveVOData = archive.archiveVO, archiveVOData.status != .pending || archiveVOData.status != .unknown {
                        self.searchPublicArchives.append(archiveVOData)
                    }
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
}
