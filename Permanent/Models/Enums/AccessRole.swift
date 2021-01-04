//  
//  AccessRole.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.12.2020.
//

import Foundation

enum AccessRole: Int, CaseIterable {
 
    case owner = 0
    
    case manager
    
    case curator
    
    case editor
    
    case contributor
    
    case viewer
    
    var groupName: String {
        switch self {
        case .owner: return .owner
        case .manager: return .manager
        case .curator: return .curator
        case .editor: return .editor
        case .contributor: return .contributor
        case .viewer: return .viewer
        }
    }
    
    static func roleForValue(_ stringValue: String?) -> AccessRole {
        switch stringValue {
        case "access.role.owner": return .owner
        case "access.role.manager": return .manager
        case "access.role.curator": return .curator
        case "access.role.editor": return .editor
        case "access.role.contributor": return .contributor
        case "access.role.viewer": return .viewer
        default: return .viewer
            
        }
    }
}
