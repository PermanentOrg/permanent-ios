//
//  ArchiveType.swift
//  Permanent
//
//  Created by Lucian Cerbu on 24.08.2021.
//

import Foundation

enum ArchiveType: Int, CaseIterable {
 
    case person = 0
    
    case family
    
    case organization
    
    var archiveName: String {
        switch self {
        case .person: return "Person".localized()
        case .family: return "Family".localized()
        case .organization: return "Organization".localized()
        }
    }
}
