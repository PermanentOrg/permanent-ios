//
//  ArchiveType.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.08.2021.
//

import Foundation
import SwiftUI

enum ArchiveType: String, CaseIterable, Identifiable {
    var id: String { return self.rawValue }
    
    case person, individual
    case family, familyHistory
    case community, organization
    case nonProfit
    case other, unsure
    
    var rawValue: String {
        switch self {
        case .person, .individual, .other, .unsure:
            return "type.archive.person"
        case .family, .familyHistory:
            return "type.archive.family"
        case .community, .organization:
            return "type.archive.organization"
        case .nonProfit:
            return "type.archive.nonprofit"
        }
    }
    
    var archiveTypeName: String {
        switch self {
        case .person, .individual, .other, .unsure: return "Person".localized()
        case .family, .familyHistory: return "Family".localized()
        case .organization, .community: return "Organization".localized()
        case .nonProfit: return "Nonprofit".localized()
        }
    }
    
    static func create(localizedValue: String) -> ArchiveType? {
        switch localizedValue {
        case "Person".localized():
            return .person
        case "Family".localized():
            return .family
        case "Organization".localized():
            return .organization
        case "Nonprofit".localized():
            return .nonProfit
        default:
            return nil
        }
    }
    
    static func byRawValue(_ rawType: String) -> ArchiveType{
        switch rawType {
        case "type.archive.person":
            return .person
        case "type.archive.family":
            return .family
        case "type.archive.organization":
            return .organization
        default:
            return .person
        }
    }
    
    var aboutPublicPageTitle: String {
        return "Archive information".localized()
    }
    var personalInformationPublicPageTitle: String {
        switch self {
        case .person, .individual, .other, .unsure:
            return "Person Information".localized()
        case .family, .familyHistory:
            return "Family Information".localized()
        case .organization, .community:
            return "Organization Information".localized()
        case .nonProfit:
            return "Nonprofit Information".localized()
        }
    }
    
    var shortDescriptionTitle: String {
        return "About this archive:".localized()
    }
    var shortDescriptionHint: String {
        return "Add a description about this Archive".localized()
    }
    
    var longDescriptionTitle: String {
        return "Archive purpose:".localized()

    }
    var longDescriptionHint: String {
        switch self {
        case .person, .individual, .unsure, .other:
            return "Tell the story of the Person this Archive is for".localized()
            
        case .family, .familyHistory:
            return "Tell the story of the Family this Archive is for".localized()
            
        case .organization, .community:
            return "Tell the story of the Organization this Archive is for".localized()
            
        case .nonProfit:
            return "Tell the story of the nonprofit Organization this Archive is for".localized()
        }
    }
    
    var milestoneTitleHint: String {
        return "Title".localized()
    }
    
    var milestoneLocationLabelHint: String {
        return "Location not set".localized()
    }
    
    var milestoneDateLabelHint: String {
        return "Start date".localized()
    }
    
    var milestoneDescriptionTextHint: String {
        return "Description".localized()
    }
    
    var onboardingType: String {
        switch self {
        case .person:
            return "Personal"
        case .individual:
            return "Individual"
        case .family:
            return "Family"
        case .familyHistory:
            return "Family History"
        case .community:
            return "Community"
        case .organization:
            return "Organization"
        case .nonProfit:
            return "Nonprofit Organization"
        case .other:
            return "Other"
        case .unsure:
            return "Unsure"
        }
    }
    
    var onboardingDescription: String {
        switch self {
        case .person:
            return "Create an archive that captures my life journey."
        case .family:
            return "Create an archive that captures my family life."
        case .organization:
            return "Create an archive that captures an organization’s life."
        case .individual:
            return "Create an archive that captures a person’s life."
        case .familyHistory:
            return "Create an archive that captures my family history."
        case .community:
            return "Create an archive that captures a community’s life."
        case .nonProfit:
            return "Create an archive that captures an nonprofit organization life."
        case .other:
            return "Create an archive about something else."
        case .unsure:
            return "I’m not sure what type of archive I want to create."
        }
    }
    
    var onboardingDescriptionIcon: Image {
        switch self {
        case .person:
            return Image(.onbrdPersonal)
        case .family:
            return Image(.onbrdFamily)
        case .organization:
            return Image(.onbrdOrganization)
        case .nonProfit:
            return Image(.onbrdOrganization)
        case .individual:
            return Image(.onbrdIndividual)
        case .familyHistory:
            return Image(.onbrdFamilyHist)
        case .community:
            return Image(.onbrdCommunity)
        case .other:
            return Image(.onbrdOther)
        case .unsure:
            return Image(.onbrdUnsure)
        }
    }
    
    var tag: String {
        switch self {
        case .person:
            return "type:myself"
        case .individual:
            return "type:individual"
        case .family:
            return "type:family"
        case .familyHistory:
            return "type:famhist"
        case .community:
            return "type:community"
        case .organization:
            return "type:org"
        case .nonProfit:
            return "type:other"
        case .other:
            return "type:other"
        case .unsure:
            return "type:unsure"
        }
    }
}
