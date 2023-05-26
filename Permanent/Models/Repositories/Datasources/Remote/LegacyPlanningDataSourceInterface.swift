//
//  LegacyPlanningDataSourceInterface.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.05.2023.
//

import Foundation
protocol LegacyPlanningDataSourceInterface {
    func getArchiveSteward(archiveId: Int, completion: @escaping (Result<[ArchiveSteward]?, Error>) -> Void)
    func setArchiveSteward(archiveId: Int, stewardEmail: String, note: String, completion: @escaping (Result<ArchiveSteward, Error>) -> Void)
    func updateArchiveSteward(directiveId: String, stewardEmail: String, note: String, completion: @escaping (Result<ArchiveSteward, Error>) -> Void)
    func getLegacyContact(completion: @escaping (Result<[AccountSteward]?, Error>) -> Void)
}
class LegacyPlanningDataSource: LegacyPlanningDataSourceInterface {
    
    func getLegacyContact(completion: @escaping (Result<[AccountSteward]?, Error>) -> Void) {
        let operation = APIOperation(LegacyPlanningEndpoint.getLegacyContact)
        operation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: [AccountSteward] = JSONHelper.decoding(from: response, with: JSONDecoder.init())
                else {
                    completion(.failure(APIError.parseError))
                    return
                }
                completion(.success(model))
            case .error(let error, _):
                completion(.failure(error ?? APIError.invalidResponse))
                return
            default:
                completion(.failure(APIError.invalidResponse))
                return
            }
        }
    }
    
    func getArchiveSteward(archiveId: Int, completion: @escaping (Result<[ArchiveSteward]?, Error>) -> Void) {
        let getArchiveStewardOperation = APIOperation(LegacyPlanningEndpoint.getArchiveSteward(archiveId: archiveId))
        getArchiveStewardOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: [ArchiveSteward] = JSONHelper.decoding(from: response, with: JSONDecoder.init())
                 else {
                     completion(.failure(APIError.parseError))
                     return
                 }
                 if model.isEmpty {
                     completion(.failure(APIError.noData))
                 } else {
                     completion(.success(model))
                 }
                 
             case .error(let error, _):
                 completion(.failure(error ?? APIError.invalidResponse))
                 return
             default:
                 completion(.failure(APIError.invalidResponse))
                 return
             }
         }
     }

     func setArchiveSteward(archiveId: Int, stewardEmail: String, note: String, completion: @escaping (Result<ArchiveSteward, Error>) -> Void) {
         let setArchiveStewardOperation = APIOperation(LegacyPlanningEndpoint.setArchiveSteward(archiveDetails: LegacyPlanningArchiveDetails(archiveId: archiveId, stewardEmail: stewardEmail, note: note)))
         setArchiveStewardOperation.execute(in: APIRequestDispatcher()) { result in
             switch result {
             case .json(let response, _):
                 guard let model: ArchiveSteward = JSONHelper.decoding(from: response, with: JSONDecoder.init()) else {
                     completion(.failure(APIError.invalidResponse))
                     return
                 }
                 completion(.success(model))
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
    
    func updateArchiveSteward(directiveId: String, stewardEmail: String, note: String, completion: @escaping (Result<ArchiveSteward, Error>) -> Void) {
        let details = LegacyPlanningArchiveDetails(archiveId: nil, stewardEmail: stewardEmail, note: note)
        let endpoint = LegacyPlanningEndpoint.updateArchiveSteward(directiveId: directiveId, stewardDetails: details)
        let setArchiveStewardOperation = APIOperation(endpoint)
        setArchiveStewardOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard let model: ArchiveSteward = JSONHelper.decoding(from: response, with: JSONDecoder.init()) else {
                    completion(.failure(APIError.invalidResponse))
                    return
                }
                completion(.success(model))
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
