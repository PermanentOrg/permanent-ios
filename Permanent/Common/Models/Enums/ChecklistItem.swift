//
//  ChecklistItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.04.2025.

enum ChecklistItemType: String, Codable {
    case archiveCreated = "archiveCreated"
    case storageRedeemed = "storageRedeemed"
    case legacyContact = "legacyContact"
    case archiveSteward = "archiveSteward"
    case archiveProfile = "archiveProfile"
    case firstUpload = "firstUpload"
    case publishContent = "publishContent"
    
    var title: String {
        switch self {
        case .archiveCreated:
            return "Create your first archive"
        case .storageRedeemed:
            return "Redeem free storage"
        case .legacyContact:
            return "Assign a Legacy Contact"
        case .archiveSteward:
            return "Assign an Archive Steward"
        case .archiveProfile:
            return "Update Archive Profile"
        case .firstUpload:
            return "Upload first file"
        case .publishContent:
            return "Publish your archive"
        }
    }
}

struct ChecklistItem: Codable {
    let id: String
    let title: String
    let completed: Bool
    
    var type: ChecklistItemType? {
        return ChecklistItemType(rawValue: id)
    }
}
