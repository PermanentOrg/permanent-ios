//
//  ChecklistItem.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.04.2025.

import SwiftUI

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
            return "Assign a legacy Contact"
        case .archiveSteward:
            return "Assign an archive steward"
        case .archiveProfile:
            return "Update Archive Profile"
        case .firstUpload:
            return "Upload first file"
        case .publishContent:
            return "Publish a file"
        }
    }
    
    var imageName: String {
        switch self {
        case .archiveCreated:
            return "memberchecklistCreateArchive"
        case .storageRedeemed:
            return "memberchecklistRedeemStorage"
        case .legacyContact:
            return "memberchecklistAssignLegacyContact"
        case .archiveSteward:
            return "memberchecklistAssignSteward"
        case .archiveProfile:
            return "memberchecklistUpdateArchiveProfile"
        case .firstUpload:
            return "memberchecklistUploadFile"
        case .publishContent:
            return "memberchecklistPublishFile"
        }
    }
}

struct ChecklistItem: Codable {
    let id: String
    let title: String
    let completed: Bool
    let imageName: String?
    
    var type: ChecklistItemType? {
        return ChecklistItemType(rawValue: id)
    }
    
    init(type: ChecklistItemType, completed: Bool = false) {
        self.id = type.rawValue
        self.title = type.title
        self.imageName = type.imageName
        self.completed = completed
    }
    
    init(id: String, title: String, completed: Bool, imageName: String? = nil) {
        self.id = id
        self.title = title
        self.completed = completed
        self.imageName = imageName ?? ChecklistItemType(rawValue: id)?.imageName
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(String.self, forKey: .id)
        title = try container.decode(String.self, forKey: .title)
        completed = try container.decode(Bool.self, forKey: .completed)
        imageName = try container.decodeIfPresent(String.self, forKey: .imageName) ?? ChecklistItemType(rawValue: id)?.imageName
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, completed, imageName
    }
}
