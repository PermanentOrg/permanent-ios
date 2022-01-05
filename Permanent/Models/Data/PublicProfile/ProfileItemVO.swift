//
//  ProfileItemVO.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.11.2021.
//

import Foundation

struct ProfileItemVO: Model {
    let profileItemVO: ProfileItemModel?
    
    enum CodingKeys: String, CodingKey {
        case profileItemVO = "Profile_itemVO"
    }
    
    enum ItemCodingKeys: String, CodingKey {
        case fieldNameUI
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Self.CodingKeys)
        let profileItemContainer = try container.nestedContainer(keyedBy: Self.ItemCodingKeys, forKey: .profileItemVO)
        let fieldNameUI = try profileItemContainer.decode(String?.self, forKey: .fieldNameUI)
        
        switch fieldNameUI {
        case FieldNameUI.blurb.rawValue:
            profileItemVO = try container.decode(BlurbProfileItem?.self, forKey: .profileItemVO)
            
        case FieldNameUI.basic.rawValue:
            profileItemVO = try container.decode(BasicProfileItem?.self, forKey: .profileItemVO)
            
        case FieldNameUI.description.rawValue:
            profileItemVO = try container.decode(DescriptionProfileItem?.self, forKey: .profileItemVO)
            
        case FieldNameUI.email.rawValue:
            profileItemVO = try container.decode(EmailProfileItem?.self, forKey: .profileItemVO)
            
        case FieldNameUI.profileGender.rawValue:
            profileItemVO = try container.decode(GenderProfileItem?.self, forKey: .profileItemVO)
            
        case FieldNameUI.birthInfo.rawValue:
            profileItemVO = try container.decode(BirthInfoProfileItem?.self, forKey: .profileItemVO)
            
        default:
            profileItemVO = nil
        }
    }
}

class ProfileItemModel: Model {
    let profileItemId: Int?
    let archiveId: Int?
    let fieldNameUI: String?
    var string1: String?
    var string2: String?
    var string3: String?
    var int1: Int?
    var int2: Int?
    var int3: Int?
    let datetime1: String?
    let datetime2: String?
    var day1: String?
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
    var locnVOs: [LocnVO]?
    let timezoneVO: TimezoneVO?
    var textData1: String?
    var textData2: String?
    let archiveNbr: String?
    let createdDT, updatedDT: String?
    var locationValue: LocnVO?

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
        case locnVOs = "LocnVOs"
        case textData1
        case textData2
        case archiveNbr
        case createdDT, updatedDT
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
}
