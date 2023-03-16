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
    
    enum Status: String, Codable {
        case ok = "status.generic.ok"
        case pending = "status.generic.pending"
        case orphaned = "status.generic.orphaned"
        case genAvatar = "status.archive.gen_avatar"
        
        case unknown = "N/A"
        
        public init(from decoder: Decoder) throws {
            self = try Status(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
        }
    }
    
    let childFolderVOS, folderSizeVOS, recordVOS: [JSONAny]?
    let accessRole, fullName: String?
    let spaceTotal, spaceLeft, fileTotal, fileLeft: JSONAny?
    let relationType, homeCity, homeState, homeCountry: JSONAny?
    let itemVOS: [ItemVO]?
    let birthDay, company, archiveVODescription: JSONAny?
    let archiveID: Int?
    let publicDT, archiveNbr: String?
    let view, viewProperty: JSONAny?
    let archiveVOPublic: Int?
    let vaultKey: String?
    let thumbArchiveNbr: String?
    let type: String?
    let thumbStatus: Status?
    let imageRatio: JSONAny?
    let thumbURL200: String?
    let thumbURL500: String?
    let thumbURL1000: String?
    let thumbURL2000: String?
    let thumbDT, createdDT, updatedDT: String?
    let status: Status?

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

extension ArchiveVOData {
    static func mock() -> ArchiveVOData {
        return ArchiveVOData(
            childFolderVOS: nil,
            folderSizeVOS: nil,
            recordVOS: nil,
            accessRole: "user",
            fullName: "Mock User",
            spaceTotal: nil,
            spaceLeft: nil,
            fileTotal: nil,
            fileLeft: nil,
            relationType: nil,
            homeCity: nil,
            homeState: nil,
            homeCountry: nil,
            itemVOS: nil,
            birthDay: nil,
            company: nil,
            archiveVODescription: nil,
            archiveID: 1,
            publicDT: "2022-01-01T00:00:00Z",
            archiveNbr: "1001",
            view: nil,
            viewProperty: nil,
            archiveVOPublic: 0,
            vaultKey: "mockVaultKey",
            thumbArchiveNbr: "1001",
            type: "archive",
            thumbStatus: .ok,
            imageRatio: nil,
            thumbURL200: "https://example.com/thumb200.jpg",
            thumbURL500: "https://example.com/thumb500.jpg",
            thumbURL1000: "https://example.com/thumb1000.jpg",
            thumbURL2000: "https://example.com/thumb2000.jpg",
            thumbDT: "2022-01-01T00:00:00Z",
            createdDT: "2022-01-01T00:00:00Z",
            updatedDT: "2022-01-01T00:00:00Z",
            status: .ok
        )
    }
}

// MARK: - Permissions
extension ArchiveVOData {
    func permissions() -> [Permission] {
        guard let rawAccessRole = accessRole else { return [.read] }
        
        return Self.permissions(forAccessRole: rawAccessRole)
    }
    
    static func permissions(forAccessRole accessRoleRaw: String) -> [Permission] {
        let accessRole = AccessRole.roleForValue(accessRoleRaw)
        
        switch accessRole {
        case .owner:
            return [.read, .create, .upload, .edit, .delete, .move, .publish, .share, .archiveShare, .ownership]
            
        case .manager:
            return [.read, .create, .upload, .edit, .delete, .move, .publish, .share, .archiveShare]
            
        case .curator:
            return [.read, .create, .upload, .edit, .delete, .move, .publish, .share]
            
        case .editor:
            return [.read, .create, .upload, .edit]
            
        case .contributor:
            return [.read, .create, .upload]
            
        case .viewer:
            return [.read]
        }
    }
}
