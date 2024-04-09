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
    
    case person, individual = "type.archive.person"
    case family, familyHistory = "type.archive.family"
    case community, organization = "type.archive.organization"
    case nonProfit = "type.archive.nonprofit"
    
    var archiveName: String {
        switch self {
        case .person, .individual: return "Person".localized()
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
    
    var aboutPublicPageTitle: String {
        return "About This Archive".localized()
    }
    var personalInformationPublicPageTitle: String {
        switch self {
        case .person, .individual:
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
        return "What is this Archive for?".localized()
    }
    var shortDescriptionHint: String {
        return "Add a short description about the purpose of this Archive".localized()
    }
    
    var longDescriptionTitle: String {
        switch self {
        case .person, .individual:
            return "Tell us about this Person".localized()
            
        case .family, .familyHistory:
            return "Tell us about this Family".localized()
            
        case .organization, .community:
            return "Tell us about this Organization".localized()
            
        case .nonProfit:
            return "Tell us about this nonprofit Organization".localized()
        }
    }
    var longDescriptionHint: String {
        switch self {
        case .person, .individual:
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
        }
    }
    
    var onboardingDescription: String {
        switch self {
        case .person:
            return "Create an archive that captures my life journey."
        case .family:
            return "Create an archive that captures my family life."
        case .organization:
            return "Create an archive that captures an organization life."
        case .individual:
            return "Create an archive that captures a person’s life."
        case .familyHistory:
            return "Create an archive that captures my family history."
        case .community:
            return "Create an archive that captures a community life."
        case .nonProfit:
            return "Create an archive that captures an nonprofit organization life."
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
        }
    }
}
