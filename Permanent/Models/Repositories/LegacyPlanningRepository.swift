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
    
    func getArchiveSteward(archiveId: Int, completion: @escaping (Result<[ArchiveSteward]?, Error>) -> Void) {
        remoteDataSource.getArchiveSteward(archiveId: archiveId, completion: completion)
    }
    
    func setArchiveSteward(archiveId: Int, stewardEmail: String, note: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        remoteDataSource.setArchiveSteward(archiveId: archiveId, stewardEmail: stewardEmail, note: note, completion: completion)
    }
}
