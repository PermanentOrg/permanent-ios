//
//  ProfilePageData.swift
//  Permanent
//
//  Created by Lucian Cerbu on 26.01.2022.
//

import Foundation

struct ProfilePageData {
    static func nameTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Full Name".localized()
            
        case .family:
            return "This Family's Nickname".localized()
            
        case .organization:
            return "This Organization's Legal Name".localized()
        }
    }
    
    static func nickNameTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Nickname".localized()
            
        case .family:
            return "Previous Name".localized()
            
        case .organization:
            return "DBA Name".localized()
        }
    }
    
    static func genderTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Gender".localized()
            
        case .family:
            return ""
            
        case .organization:
            return ""
        }
    }
    
    static func birthDateTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Birth Date".localized()
            
        case .family, .organization:
            return "Date Established".localized()
        }
    }
    
    static func birthLocationTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Birth Location".localized()
            
        case .family, .organization:
            return "Location Established".localized()
        }
    }
    
    static func nameHint(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Full Name".localized()
            
        case .family:
            return "Family's Nickname".localized()
            
        case .organization:
            return "Organization's Legal Name".localized()
        }
    }
    
    static func nickNameHint(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Nickname".localized()
            
        case .family:
            return "Previous Name".localized()
            
        case .organization:
            return "DBA Name".localized()
        }
    }
    
    static func genderHint(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person:
            return "Gender".localized()
            
        case .family:
            return ""
            
        case .organization:
            return ""
        }
    }
    
    static func birthDateHint(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .family, .organization:
            return "YYYY-MM-DD"
        }
    }
    
    static func birthLocationHint(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .family, .organization:
            return "Choose a location".localized()
        }
    }
}
