//
//  ProfilePageViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2021.
//

import UIKit

class PublicProfilePageViewModel: ViewModelInterface {
    var archiveData: ArchiveVOData!
    
    init(archiveData: ArchiveVOData) {
        self.archiveData = archiveData
    }
    
    func getAllByArchiveNbr(_ archive: ArchiveVOData, _ completionBlock: @escaping (([ProfileItemVO]?, Error?) -> Void)) {
        guard let archiveId = archive.archiveID, let archiveNbr = archive.archiveNbr else {
            completionBlock(nil, APIError.unknown)
            return
        }
        
        let getAllByArchiveNbr = APIOperation(PublicProfileEndpoint.getAllByArchiveNbr(archiveId: archiveId, archiveNbr: archiveNbr))
        getAllByArchiveNbr.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ProfileItemVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
                    model.isSuccessful
                else {
                    completionBlock(nil, APIError.invalidResponse)
                    return
                }
                
                completionBlock(model.results.first?.data, nil)
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
    
    func updatePublicProfile(_ profileItem: ProfileItemVOData, _ completionBlock: @escaping ((Bool, Error?) -> Void)) {
        
        let updatePublicProfile = APIOperation(PublicProfileEndpoint.safeAddUpdate(profileItemVO: profileItem))
        updatePublicProfile.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ProfileItemVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
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
