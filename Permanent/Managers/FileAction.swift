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
        switch self {
        case .copy: return .copy
        case .move: return .move
        default: return ""
        }
    }
    
}
