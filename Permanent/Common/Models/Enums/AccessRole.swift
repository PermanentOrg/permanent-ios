//  
//  AccessRole.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.12.2020.
//

import Foundation
import SwiftUI

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
    
    var apiValue: String {
        switch self {
        case .owner: return "access.role.owner"
        case .manager: return "access.role.manager"
        case .curator: return "access.role.curator"
        case .editor: return "access.role.editor"
        case .contributor: return "access.role.contributor"
        case .viewer: return "access.role.viewer"
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

extension AccessRole: SelectableOption {
    var title: String {
        switch self {
        case .owner: return "Owner"
        case .manager: return "Manager"
        case .curator: return "Curator"
        case .editor: return "Editor"
        case .contributor: return "Contributor"
        case .viewer: return "Viewer"
        }
    }
    
    var description: String {
        switch self {
        case .viewer:
            return "A member with permission to view records only."
        case .contributor:
            return "A member with permission to view and create file and folder records (upload only)."
        case .editor:
            return "A member with permission to view and create file and folder records."
        case .curator:
            return "A member with permission to view and create file and folder records."
        case .manager: //will not be included in the role selector for share
            return "A member with permission to view and create file and folder records."
        case .owner:
            return "A member with permission to view and create file and folder records."
        }
    }
    
    var icon: Image {
        switch self {
        case .viewer: return Image(.publishAccessViewer)
        case .contributor: return Image(.publishAccessContributor)
        case .editor: return Image(.publishAccessEditor)
        case .curator: return Image(.publishAccessCurator)
        case .manager: return Image(.publishAccessCurator)
        case .owner: return Image(.publishAccessOwner)
        }
    }
    
    var iconColor: Color {
        return Color.success500
    }
}
