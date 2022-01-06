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
    var profileItemId: Int? = nil
    var archiveId: Int? = nil
    var fieldNameUI: String? = nil
    var string1: String? = nil
    var string2: String? = nil
    var string3: String? = nil
    var int1: Int? = nil
    var int2: Int? = nil
    var int3: Int? = nil
    var datetime1: String? = nil
    var datetime2: String? = nil
    var day1: String? = nil
    var day2: String? = nil
    var locnId1: Int? = nil
    var locnId2: Int? = nil
    var textDataId1: Int? = nil
    var textDataId2: Int? = nil
    var otherId1: Int? = nil
    var otherId2: Int? = nil
    var archiveArchiveNbr: Int? = nil
    var recordArchiveNbr: Int? = nil
    var folderArchiveNbr: Int? = nil
    var isVisible: Bool? = nil
    var isPendingAction: Bool? = nil
    var publicDT: String? = nil
    var status: String? = nil
    var type: String? = nil
    var locnVOs: [LocnVO]? = nil
    var timezoneVO: TimezoneVO? = nil
    var textData1: String? = nil
    var textData2: String? = nil
    var archiveNbr: String? = nil
    var createdDT: String? = nil
    var updatedDT: String? = nil
    var locationValue: LocnVO? = nil

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
        case textDataId1 = "text_dataId1"
        case textDataId2 = "text_dataId2"
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
    
    init(fieldNameUI: String) {
        self.fieldNameUI = fieldNameUI
    }
}
