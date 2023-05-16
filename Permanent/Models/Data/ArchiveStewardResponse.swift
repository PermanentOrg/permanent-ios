//
//  ArchiveStewardResponse.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.05.2023.
//

import Foundation
struct ArchiveStewardResponse: Model {
    let directiveId: String?
    let archiveId: Int?
    let type: String?
    let createdDT: String?
    let updatedDT: String?
    let triggerType: ArchiveStewardResponseTriggerType?
    let stewardAccountId: String?
    let note: String?
    let executionDT: String?
}

struct ArchiveStewardResponseTriggerType: Model {
    let directiveTriggerId: String?
    let directiveId: String?
    let type: String?
    let createdDT: String?
    let updatedDT: String?
}
