//  
//  AccessRole.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.12.2020.
//

import Foundation

enum AccessRole: Int, CaseIterable, Codable {
 
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
    
    static func apiRoleForValue(_ stringValue: String) -> String? {
        switch stringValue {
        case .owner: return "access.role.owner"
        case .manager: return "access.role.manager"
        case .curator: return "access.role.curator"
        case .editor: return "access.role.editor"
        case .contributor: return "access.role.contributor"
        case .viewer: return "access.role.viewer"
        default: return nil
        }
    }
}
