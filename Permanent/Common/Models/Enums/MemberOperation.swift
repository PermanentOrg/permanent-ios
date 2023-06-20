//  
//  MemberOperation.swift
//  Permanent
//
//  Created by Adrian Creteanu on 07.01.2021.
//

import Foundation

enum MemberOperation {
    
    case add
    
    case edit
    
    case remove
    
    case transferOwnership
    
    var endpoint: String {
        switch self {
        case .add: return "/archive/share"
        case .edit: return "/archive/updateShare"
        case .remove: return "/archive/unshare"
        case .transferOwnership: return "/archive/transferOwnership"
        }
    }
}
