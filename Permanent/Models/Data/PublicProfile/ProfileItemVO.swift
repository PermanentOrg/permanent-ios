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
    let publicDT: String?
    let status: String?
    let type: String?
    let LocnVOs: String?
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
