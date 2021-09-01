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
}
