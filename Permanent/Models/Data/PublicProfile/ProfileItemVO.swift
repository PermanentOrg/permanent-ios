//
//  ProfileItemVO.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.11.2021.
//

import Foundation

struct ProfileItemVO: Model {
    let profileItemVO: ProfileItemVOData?
    
    enum CodingKeys: String, CodingKey {
        case profileItemVO = "Profile_itemVO"
    }
}

struct ProfileItemVOData: Model {
    let profileItemId: Int?
    let archiveId: Int?
    let fieldNameUI: String?
    let string1: String?
    let string2: String?
    let string3: String?
    let int1: Int?
    let int2: Int?
    let int3: Int?
    let datetime1: String?
    let datetime2: String?
    let day1: String?
    let day2: String?
    let locnId1: Int?
    let locnId2: Int?
    let text_dataId1: Int?
    let text_dataId2: Int?
    let otherId1: Int?
    let otherId2: Int?
    let archiveArchiveNbr: Int?
    let recordArchiveNbr: Int?
    let folderArchiveNbr: Int?
    let isVisible: Bool?
    let isPendingAction: Bool?
    let publicDT: String?
    let status: String?
    let type: String?
    let LocnVOs: [LocnVO]?
    let timezoneVO: TimezoneVO?
    let textData1: String?
    let textData2: String?
    let archiveNbr: String?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case profileItemId = "profile_itemId"
        case timezoneVO = "TimezoneVO"
        case archiveId
        case fieldNameUI
        case string1
        case string2
        case string3
        case int1
        case int2
        case int3
        case datetime1
        case datetime2
        case day1
        case day2
        case locnId1
        case locnId2
        case text_dataId1
        case text_dataId2
        case otherId1
        case otherId2
        case archiveArchiveNbr
        case recordArchiveNbr
        case folderArchiveNbr
        case isVisible
        case isPendingAction
        case publicDT
        case status
        case type
        case LocnVOs
        case textData1
        case textData2
        case archiveNbr
        case createdDT, updatedDT
    }
    
    func toBackendString() -> String? {
        var returnedValue: String?
        
        guard let fieldName = fieldNameUI else { return nil }

        switch fieldName {
            
        case "profile.basic":
            switch fieldName {
            case FieldNameUI.archiveName.rawValue:
                guard let string = string1 else { return nil }
                returnedValue = string
            case FieldNameUI.fullName.rawValue:
                guard let string = string2 else { return nil }
                returnedValue = string
            case FieldNameUI.nickname.rawValue:
                guard let string = string3 else { return nil }
                returnedValue = string
            default:
                return nil
        }
        case "profile.blurb":
            switch fieldName {
            case FieldNameUI.shortDescription.rawValue:
                guard let string = string1 else { return nil }
                returnedValue = string
            default:
                return nil
            }
        case "profile.description":
            switch fieldName {
                case FieldNameUI.longDescription.rawValue:
                    guard let string = textData1 else { return nil }
                    returnedValue = string
            default:
                return nil
            }
        case "profile.email":
            switch fieldName {
            case FieldNameUI.emailAddress.rawValue:
                guard let string = string1 else { return nil }
                returnedValue = string
            default:
                return nil
            }
        case "profile.gender":
            switch fieldName {
            case FieldNameUI.profileGender.rawValue:
                guard let string = string1 else { return nil }
                returnedValue = string
            default:
                return nil
            }
        case "profile.birth_info":
            switch fieldName {
            case FieldNameUI.birthDate.rawValue:
                guard let string = day1 else { return nil }
                returnedValue = string
                
            case FieldNameUI.birthLocation.rawValue:
                
                guard let locnVO = LocnVOs?.first else { return nil }
                
                let address = getAddressString([locnVO.streetNumber, locnVO.streetName, locnVO.locality, locnVO.country])

                returnedValue = address
            default:
                return nil
            }
        default:
            return nil
        }
        return returnedValue
    }
    
    func getAddressString(_ items: [String?], _ inMetadataScreen: Bool = true) -> String {
        var address = items.compactMap { $0 }.joined(separator: ", ")
        if inMetadataScreen  {
            address == "" ? (address = "Choose a location".localized()) : ()
        }
        return address
    }
}
