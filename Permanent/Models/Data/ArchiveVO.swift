//
//  ArchiveVO.swift
//  Permanent
//
//  Created by Adrian Creteanu on 24/09/2020.
//

import Foundation

struct ArchiveVO: Model {
    let archiveVO: ArchiveVOData?

    enum CodingKeys: String, CodingKey {
        case archiveVO = "ArchiveVO"
    }
}

struct ArchiveVOData: Model {
    let childFolderVOS, folderSizeVOS, recordVOS: [JSONAny]?
    let accessRole, fullName: String?
    let spaceTotal, spaceLeft, fileTotal, fileLeft: JSONAny?
    let relationType, homeCity, homeState, homeCountry: JSONAny?
    let itemVOS: [ItemVO]?
    let birthDay, company, archiveVODescription: JSONAny?
    let archiveID: Int?
    let publicDT, archiveNbr: String?
    let archiveVOPublic, view, viewProperty: JSONAny?
    let vaultKey: String?
    let thumbArchiveNbr: JSONAny?
    let type, thumbStatus: String?
    let imageRatio: JSONAny?
    let thumbURL200: String?
    let thumbURL500: String?
    let thumbURL1000: String?
    let thumbURL2000: String?
    let thumbDT, status, createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case childFolderVOS = "ChildFolderVOs"
        case folderSizeVOS = "FolderSizeVOs"
        case recordVOS = "RecordVOs"
        case accessRole, fullName, spaceTotal, spaceLeft, fileTotal, fileLeft, relationType, homeCity, homeState, homeCountry
        case itemVOS = "ItemVOs"
        case birthDay, company
        case archiveVODescription = "description"
        case archiveID = "archiveId"
        case publicDT, archiveNbr
        case archiveVOPublic = "public"
        case view, viewProperty, vaultKey, thumbArchiveNbr, imageRatio, type, thumbStatus, thumbURL200, thumbURL500, thumbURL1000, thumbURL2000, thumbDT, status, createdDT, updatedDT
    }
}
