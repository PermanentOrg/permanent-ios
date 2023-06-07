//
//  LegacyPlanningArchiveDetails.swift
//  Permanent
//
//  Created by Lucian Cerbu on 22.05.2023.
//

import Foundation

struct LegacyPlanningArchiveDetails {
    let archiveId: Int?
    let stewardEmail: String
    let type = "transfer"
    let note: String
    let triggerType = "admin"
}
