//
//  OnboardingPendingArchives.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20.06.2024.

import Foundation

class OnboardingArchive: Identifiable, Decodable {
    var id = UUID()
    
    var fullname: String
    var accessType: String
    var status: ArchiveVOData.Status
    var archiveID: Int
    var thumbnailURL: String
    var isThumbnailGenerated: Bool
    
    init(id: UUID = UUID(), fullname: String, accessType: String, status: ArchiveVOData.Status, archiveID: Int, thumbnailURL: String, isThumbnailGenerated: Bool) {
        self.id = id
        self.fullname = fullname
        self.accessType = accessType
        self.status = status
        self.archiveID = archiveID
        self.thumbnailURL = thumbnailURL
        self.isThumbnailGenerated = isThumbnailGenerated
    }
}
