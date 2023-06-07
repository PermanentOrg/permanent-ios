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
    
    func getLegacyContact(completion: @escaping (Result<[AccountSteward]?, Error>) -> Void) {
        remoteDataSource.getLegacyContact(completion: completion)
    }
    
    func getArchiveSteward(archiveId: Int, completion: @escaping (Result<[ArchiveSteward]?, Error>) -> Void) {
        remoteDataSource.getArchiveSteward(archiveId: archiveId, completion: completion)
    }
    
    func setArchiveSteward(archiveId: Int, stewardEmail: String, note: String, completion: @escaping (Result<ArchiveSteward, Error>) -> Void) {
        remoteDataSource.setArchiveSteward(archiveId: archiveId, stewardEmail: stewardEmail, note: note, completion: completion)
    }
    
    func setAccountSteward(name: String, stewardEmail: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        remoteDataSource.setAccountSteward(name: name, stewardEmail: stewardEmail, completion: completion)
    }
    
    func updateAccountSteward(legacyContactId: String, name: String?, stewardEmail: String?, completion: @escaping (Result<AccountSteward?, Error>) -> Void) {
        remoteDataSource.updateAccountSteward(legacyContactId: legacyContactId, name: name, stewardEmail: stewardEmail, completion: completion)
    }
    func updateArchiveSteward(directiveId: String, stewardEmail: String, note: String, completion: @escaping (Result<ArchiveSteward, Error>) -> Void) {
        remoteDataSource.updateArchiveSteward(directiveId: directiveId, stewardEmail: stewardEmail, note: note, completion: completion)
    }

}
