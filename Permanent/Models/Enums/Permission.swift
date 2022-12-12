//
//  Permission.swift
//  Permanent
//
//  Created by Vlad Alexandru Rusu on 09.09.2021.
//

import Foundation

enum Permission: Codable {
    case read
    case create
    case upload
    case edit
    case delete
    case move
    case publish
    case share
    case archiveShare
    case ownership
    
    func prettyPermission() -> String? {
        switch self {
        case .read: return "view".localized()
        
        case .create: return "create".localized()
            
        case .upload: return "upload".localized()
            
        case .edit: return "edit".localized()
            
        case .delete: return "delete".localized()
            
        case .move: return "move".localized()
            
        case .publish: return "publish".localized()
            
        case .share: return "share".localized()
            
        case .archiveShare, .ownership: return nil
        }
    }
}
