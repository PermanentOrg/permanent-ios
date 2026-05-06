//
//  RelationVO.swift
//  Permanent
//
//  Created by Lucian Cerbu on 05.05.2026.
//

import Foundation

struct RelationVO: Model {
    let relationVO: RelationVOData?

    enum CodingKeys: String, CodingKey {
        case relationVO = "RelationVO"
    }
}

struct RelationVOData: Model {
    let relationID: Int?
    let archiveID: Int?
    let relationArchiveID: Int?
    let publicDT: String?
    let relationType: String?
    let status: String?
    let archiveVO: ArchiveVOData?
    let relationArchiveVO: ArchiveVOData?
    let createdDT, updatedDT: String?

    enum CodingKeys: String, CodingKey {
        case relationID = "relationId"
        case archiveID = "archiveId"
        case relationArchiveID = "relationArchiveId"
        case publicDT
        case relationType = "type"
        case status
        case archiveVO = "ArchiveVO"
        case relationArchiveVO = "RelationArchiveVO"
        case createdDT, updatedDT
    }
}
