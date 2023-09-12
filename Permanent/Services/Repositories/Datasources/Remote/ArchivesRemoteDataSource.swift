//
//  ArchivesRemoteDataSource.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 16.03.2023.
//

import Foundation

protocol ArchivesRemoteDataSourceInterface {
    func getAccountArchives(accountId: Int, completion: @escaping (Result<[ArchiveVO], Error>) -> Void)
    func changeArchive(archiveId: Int, archiveNbr: String, completion: @escaping (Result<Bool, Error>) -> Void)
}

class ArchivesRemoteDataSource: ArchivesRemoteDataSourceInterface {
    func getAccountArchives(accountId: Int, completion: @escaping (Result<[ArchiveVO], Error>) -> Void) {
        let getAccountArchivesDataOperation = APIOperation(ArchivesEndpoint.getArchivesByAccountId(accountId: accountId))
        
        getAccountArchivesDataOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ArchiveVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completion(.failure(APIError.parseError))
                    return
                }
                
                let accountArchives = model.results.first?.data ?? []
                
                completion(.success(accountArchives))
                
            case .error(let error, _):
                completion(.failure(error ?? APIError.invalidResponse))
                return
                
            default:
                completion(.failure(APIError.invalidResponse))
                return
            }
        }
    }
    
    func changeArchive(archiveId: Int, archiveNbr: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        let changeArchiveOperation = APIOperation(ArchivesEndpoint.change(archiveId: archiveId, archiveNbr: archiveNbr))
        
        changeArchiveOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<NoDataModel> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                
                completion(.success(true))
                return
                
            case .error(let error, _):
                completion(.failure(error ?? APIError.invalidResponse))
                return
                
            default:
                completion(.failure(APIError.invalidResponse))
                return
            }
        }
    }
}

class MockArchivesRemoteDataSource: ArchivesRemoteDataSourceInterface {
    var getAccountArchivesResult: Result<[ArchiveVO], Error>?
    var changeArchiveResult: Result<Bool, Error>?

    func getAccountArchives(accountId: Int, completion: @escaping (Result<[ArchiveVO], Error>) -> Void) {
        if let result = getAccountArchivesResult {
            completion(result)
        } else {
            completion(.failure(NSError(domain: "MockArchivesRemoteDataSource", code: -1, userInfo: nil)))
        }
    }
    
    func changeArchive(archiveId: Int, archiveNbr: String, completion: @escaping (Result<Bool, Error>) -> Void) {
        if let result = changeArchiveResult {
            completion(result)
        } else {
            completion(.failure(NSError(domain: "MockArchivesRemoteDataSource", code: -1, userInfo: nil)))
        }
    }
}
