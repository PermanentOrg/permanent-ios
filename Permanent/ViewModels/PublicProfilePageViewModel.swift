//
//  ProfilePageViewModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 09.11.2021.
//

import UIKit

class PublicProfilePageViewModel: ViewModelInterface {
    var archiveData: ArchiveVOData!
    var archiveType: ArchiveType!
    
    var profileItems = [ProfileItemModel]()
    
    var blurbProfileItem: BlurbProfileItem? {
        return profileItems.first(where: {$0 is BlurbProfileItem}) as? BlurbProfileItem
    }
    var descriptionProfileItem: DescriptionProfileItem? {
        return profileItems.first(where: {$0 is DescriptionProfileItem}) as? DescriptionProfileItem
    }
    
    init(_ archiveData: ArchiveVOData) {
        self.archiveData = archiveData
        guard let archiveType = archiveData.type else { return }
        self.archiveType = ArchiveType(rawValue: archiveType)
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
                self.profileItems = model.results.first?.data?.compactMap({ $0.profileItemVO }) ?? []
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
    
    func modifyPublicProfileItem(_ profileItemModel: ProfileItemModel, _ operationType: ProfileItemOperation, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
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
