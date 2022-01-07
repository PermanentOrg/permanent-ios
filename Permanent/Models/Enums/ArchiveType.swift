//
//  ArchiveType.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.08.2021.
//

import Foundation

enum ArchiveType: String, CaseIterable {
 
    case person = "type.archive.person"
    case family = "type.archive.family"
    case organization = "type.archive.organization"
    
    var archiveName: String {
        switch self {
        case .person: return "Person".localized()
        case .family: return "Family".localized()
        case .organization: return "Organization".localized()
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
        default:
            return nil
        }
    }
    
    var aboutPublicPageTitle: String {
        return "About This Archive".localized()
    }
    var personalInformationPublicPageTitle: String {
        switch self {
        case .person:
            return "Personal Information".localized()
            
        case .family:
            return "Personal Information".localized()
            
        case .organization:
            return "Personal Information".localized()
        }
    }
    
    var shortDescriptionTitle: String {
        switch self {
        case .person:
            return "What is this Archive for?".localized()
            
        case .family:
            return ""
            
        case .organization:
            return ""
        }
    }
    var shortDescriptionHint: String {
        switch self {
        case .person:
            return "Add a short description about the purpose of this Archive".localized()
            
        case .family:
            return ""
            
        case .organization:
            return ""
        }
    }
    
    var longDescriptionTitle: String {
        switch self {
        case .person:
            return "Tell us about this Person".localized()
            
        case .family:
            return "Tell us about this Family".localized()
            
        case .organization:
            return "Tell us about this Organization".localized()
        }
    }
    var longDescriptionHint: String {
        switch self {
        case .person:
            return "Tell the story of the Person this Archive is for".localized()
            
        case .family:
            return "Tell the story of the Family this Archive is for".localized()
            
        case .organization:
            return "Tell the story of the Organization this Archive is for".localized()
        }
    }
}
