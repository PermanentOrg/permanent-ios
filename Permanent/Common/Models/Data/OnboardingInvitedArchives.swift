//
//  OnboardingPendingArchives.swift
//  Permanent
//
//  Created by Lucian Cerbu on 20.06.2024.

import Foundation

class OnboardingInvitedArchives: Identifiable, Decodable {
    var id = UUID()
    
    var fullname: String
    var accessType: String
    var status: ArchiveVOData.Status
    var archiveID: Int
    
    init(id: UUID = UUID(), fullname: String, accessType: String, status: ArchiveVOData.Status, archiveID: Int) {
        self.id = id
        self.fullname = fullname
        self.accessType = accessType
        self.status = status
        self.archiveID = archiveID
    }
}
