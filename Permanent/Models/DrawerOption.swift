//  
//  DrawerOption.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25.11.2020.
//

import UIKit

enum DrawerOption {
    case files
    case shares
    case logOut
    
    var icon: UIImage? {
        switch self {
        case .files: return .folder
        case .shares: return .share
        case .logOut: return UIImage.logOut.templated
        }
    }
    
    var title: String {
        switch self {
        case .files: return .myFiles
        case .shares: return .shares
        case .logOut: return .logOut
        }
    }
    
    var isActive: Bool {
        switch self {
        case .files: return true
        default: return false
        }
    }
}
