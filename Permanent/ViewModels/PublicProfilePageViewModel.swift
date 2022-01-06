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
    
    func modifyPublicProfileItem(_ fieldType: FieldNameUI,_ newValue: String,_ operationType: ProfileItemOperation,_ profileItemId: Int? = nil, _ completionBlock: @escaping ((Bool, Error?, Int?) -> Void)) {
        
        guard let profileItemData = createProfileItem(fieldname: fieldType, itemValue: newValue, archiveId: archiveData.archiveID, profileItemId: profileItemId) else {
            completionBlock(false, APIError.parseError(.errorMessage), nil)
            return
        }
        var updatePublicProfile = APIOperation(PublicProfileEndpoint.safeAddUpdate(profileItemVOData: profileItemData))
        
        switch operationType {
        case .update, .create:
             updatePublicProfile = APIOperation(PublicProfileEndpoint.safeAddUpdate(profileItemVOData: profileItemData))
        case .delete:
             updatePublicProfile = APIOperation(PublicProfileEndpoint.deleteProfileItem(profileItemVOData: profileItemData))
        }
        
        updatePublicProfile.execute(in: APIRequestDispatcher()) { result in
            switch result {
            case .json(let response, _):
                guard
                    let model: APIResults<ProfileItemVO> = JSONHelper.decoding(from: response, with: APIResults<NoDataModel>.decoder),
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
    
    func createProfileItem(fieldname: FieldNameUI, itemValue: String, archiveId: Int?, profileItemId: Int?) -> ProfileItemVOData? {

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZZZZZ"
        
        let publicDT = dateFormatter.string(from: Date())
        
        switch fieldname {
        
        case .shortDescription, .archiveName, .emailAddress, .profileGender:
            let profileItemVOData = ProfileItemVOData(profileItemId: profileItemId, archiveId: archiveId, fieldNameUI: fieldname.rawValue, string1: itemValue, string2: nil, string3: nil, int1: nil, int2: nil, int3: nil, datetime1: nil, datetime2: nil, day1: nil, day2: nil, locnId1: nil, locnId2: nil, textDataId1: nil, textDataId2: nil, otherId1: nil, otherId2: nil, archiveArchiveNbr: nil, recordArchiveNbr: nil, folderArchiveNbr: nil, isVisible: nil, isPendingAction: true, publicDT: publicDT, status: nil, type: "type.widget.string", locnVOs: nil, timezoneVO: nil, textData1: nil, textData2: nil, archiveNbr: nil, createdDT: nil, updatedDT: nil)
            
            return profileItemVOData
            
        case .longDescription:
            let profileItemVOData = ProfileItemVOData(profileItemId: profileItemId, archiveId: archiveId, fieldNameUI: fieldname.rawValue, string1: nil, string2: nil, string3: nil, int1: nil, int2: nil, int3: nil, datetime1: nil, datetime2: nil, day1: nil, day2: nil, locnId1: nil, locnId2: nil, textDataId1: nil, textDataId2: nil, otherId1: nil, otherId2: nil, archiveArchiveNbr: nil, recordArchiveNbr: nil, folderArchiveNbr: nil, isVisible: nil, isPendingAction: true, publicDT: publicDT, status: nil, type: "type.widget.string", locnVOs: nil, timezoneVO: nil, textData1: itemValue, textData2: nil, archiveNbr: nil, createdDT: nil, updatedDT: nil)
            
            return profileItemVOData
        }
    }
}

enum ProfileItemOperation {
    case update
    case create
    case delete
}
