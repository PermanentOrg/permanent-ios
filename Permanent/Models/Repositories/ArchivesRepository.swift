//
//  ArchivesRepository.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 16.03.2023.
//

import Foundation

class ArchivesRepository {
    let remoteDataSource: ArchivesRemoteDataSourceInterface
    
    init(remoteDataSource: ArchivesRemoteDataSourceInterface = ArchivesRemoteDataSource()) {
        self.remoteDataSource = remoteDataSource
    }
    
    func getAccountArchives(accountId: Int, completion: @escaping (Result<[ArchiveVO], Error>) -> Void) {
        remoteDataSource.getAccountArchives(accountId: accountId, completion: completion)
    }
    
    func changeArchive(archiveId: Int, archiveNbr: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        remoteDataSource.changeArchive(archiveId: archiveId, archiveNbr: archiveNbr, completion: completion)
    }
}
