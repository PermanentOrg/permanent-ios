//
//  ArchiveStewardResponse.swift
//  Permanent
//
//  Created by Lucian Cerbu on 15.05.2023.
//
import Foundation

struct ArchiveSteward: Model {
    let directiveId: String
    let archiveId: String?
    let type: String?
    let createdDT: String?
    let updatedDT: String?
    let triggerType: ArchiveStewardResponseTriggerType?
    let stewardAccountId: String?
    let note: String?
    let executionDT: String?
    let steward: StewardDetails?
}
