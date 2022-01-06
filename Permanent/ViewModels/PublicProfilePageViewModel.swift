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
                    let model: APIResults<ProfileItemVO> = JSONHelper.decoding(from: response, with: APIResults<ProfileItemVO>.decoder),
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
    
    func modifyBlurbProfileItem(profileItemId: Int? = nil, newValue: String, operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let newBlurbItem = BlurbProfileItem()
        newBlurbItem.shortDescription = newValue
        newBlurbItem.archiveId = archiveData.archiveID
        newBlurbItem.profileItemId = profileItemId
        
        modifyPublicProfileItem(newBlurbItem, operationType, completionBlock)
    }
    
    func modifyDescriptionProfileItem(profileItemId: Int? = nil, newValue: String, operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        let newDescriptionItem = DescriptionProfileItem()
        newDescriptionItem.longDescription = newValue
        newDescriptionItem.archiveId = archiveData.archiveID
        newDescriptionItem.profileItemId = profileItemId
        
        modifyPublicProfileItem(newDescriptionItem, operationType, completionBlock)
    }
    
    func modifyPublicProfileItem(_ profileItemModel: ProfileItemModel,_ operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        
        let apiOperation: APIOperation
        
        switch operationType {
        case .update, .create:
            apiOperation = APIOperation(PublicProfileEndpoint.safeAddUpdate(profileItemVOData: profileItemModel))
        case .delete:
            apiOperation = APIOperation(PublicProfileEndpoint.deleteProfileItem(profileItemVOData: profileItemModel))
        }
        
        apiOperation.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ProfileItemVO> = JSONHelper.decoding(from: response, with: APIResults<ProfileItemVO>.decoder),
                    model.isSuccessful,
                    let newProfileItemId = model.results.first
                else {
                    completionBlock(false, APIError.invalidResponse, nil)
                    return
                }
                NotificationCenter.default.post(name: .publicProfilePageAboutUpdate, object: self)
                if operationType == .delete {
                    completionBlock(true, nil, nil)
                    return
                }
                completionBlock(true, nil, newProfileItemId.data?.first?.profileItemVO?.profileItemId)
                return
            case .error:
                completionBlock(false, APIError.invalidResponse, nil)
                return
            default:
                completionBlock(false, APIError.invalidResponse, nil)
                return
            }
        }
    }
}
