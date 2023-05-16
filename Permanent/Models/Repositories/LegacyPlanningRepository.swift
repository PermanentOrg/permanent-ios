//
//  LegacyPlanningRepository.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.05.2023.
//

import Foundation

class LegacyPlanningRepository {
    let remoteDataSource: LegacyPlanningDataSourceInterface
    
    init(remoteDataSource: LegacyPlanningDataSourceInterface = LegacyPlanningDataSource()) {
        self.remoteDataSource = remoteDataSource
    }
    
    func getArchiveSteward(archiveId: Int, completion: @escaping ((ArchiveStewardResponse?, Error?) -> Void)) {
        remoteDataSource.getArchiveSteward(archiveId: archiveId) { result in
            switch result {
            case .success(let response):
                completion(response, nil)
            case .failure(let error):
                completion(nil, error)
            }
        }
    }
    
    func setArchiveSteward(archiveId: Int, stewardEmail: String, note: String, completion: @escaping ((Bool, Error?) -> Void)) {
        remoteDataSource.setArchiveSteward(archiveId: archiveId, stewardEmail: stewardEmail, note: note) { result in
            switch result {
            case .success(let response):
                completion(response, nil)
            case .failure(let error):
                completion(false, error)
            }
        }
    }
}