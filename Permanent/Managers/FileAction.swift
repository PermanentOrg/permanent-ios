//  
//  FileAction.swift
//  Permanent
//
//  Created by Adrian Creteanu on 18.11.2020.
//

import Foundation

enum FileAction {
    
    case copy
    
    case move
    
    case none
    
    var title: String {
        return .paste
    }
    
    var action: String {
        switch self {
        case .copy: return .fileCopied
        case .move: return .fileMoved
        default: return ""
        }
    }
    
    var endpointValue: String {
        switch self {
        case .copy: return "copy"
        case .move: return "move"
        default: return ""
        }
    }
}
