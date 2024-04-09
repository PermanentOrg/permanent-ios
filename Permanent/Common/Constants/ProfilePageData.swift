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
        case .person, .individual:
            return "Full Name".localized()
            
        case .family, .familyHistory:
            return "This Family's Nickname".localized()
            
        case .organization, .community:
            return "This Organization's Legal Name".localized()
            
        case .nonProfit:
            return "Legal Name".localized()
        }
    }
    
    static func nickNameTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .individual:
            return "Nickname".localized()
            
        case .family, .familyHistory:
            return "Previous Name".localized()
            
        case .organization, .nonProfit, .community:
            return "DBA Name".localized()
        }
    }
    
    static func genderTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .individual:
            return "Gender".localized()
            
        case .family, .familyHistory:
            return ""
            
        case .organization, .nonProfit, .community:
            return ""
        }
    }
    
    static func birthDateTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .individual:
            return "Birth Date".localized()
            
        case .family, .organization, .nonProfit, .familyHistory, .community:
            return "Date Established".localized()
        }
    }
    
    static func birthLocationTitle(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .individual:
            return "Birth Location".localized()
            
        case .family, .organization, .nonProfit, .community, .familyHistory:
            return "Location Established".localized()
        }
    }
    
    static func milestoneTitle() -> String {
        return "Title".localized()
    }
    
    static func milestoneStartDate() -> String {
        return "Start Date".localized()
    }
    
    static func milestoneEndDate() -> String {
        return "End Date".localized()
    }
    
    static func milestoneDescription() -> String {
        return "Description".localized()
    }
    
    static func milestoneLocation() -> String {
        return "Location".localized()
    }
    
    static func nameHint(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .individual:
            return "Full Name".localized()
            
        case .family, .familyHistory:
            return "Family's Nickname".localized()
            
        case .organization:
            return "Organization's Legal Name".localized()
            
        case .community:
            return "Community's Legal Name".localized()
            
        case .nonProfit:
            return "Legal Name".localized()
        }
    }
    
    static func nickNameHint(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .individual:
            return "Nickname".localized()
            
        case .family, .familyHistory:
            return "Previous Name".localized()
            
        case .organization, .nonProfit, .community:
            return "DBA Name".localized()
        }
    }
    
    static func genderHint(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .individual:
            return "Gender".localized()
            
        case .family, .organization, .nonProfit, .familyHistory, .community:
            return ""
        }
    }
    
    static func birthDateHint(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .family, .organization, .nonProfit, .community, .individual, .familyHistory:
            return "YYYY-MM-DD"
        }
    }
    
    static func birthLocationHint(archiveType: ArchiveType) -> String {
        switch archiveType {
        case .person, .family, .organization, .nonProfit, .community, .individual, .familyHistory:
            return "Choose a location".localized()
        }
    }
    
    static func milestoneTitleHint() -> String {
        return "What was this milestone?".localized()
    }
    
    static func milestoneStartDateHint() -> String {
        return "YYYY-MM-DD".localized()
    }
    
    static func milestoneEndDateHint() -> String {
        return "YYYY-MM-DD".localized()
    }
    
    static func milestoneDescriptionHint() -> String {
        return "More details and information about this milestone".localized()
    }
    
    static func milestoneLocationHint() -> String {
        return "Choose a location".localized()
    }
}
