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
    case members
    case addStorage
    case accountInfo
    case security
    case activityFeed
    case invitations
    case logOut
    
    var icon: UIImage? {
        switch self {
        case .files: return .folder
        case .shares: return .share
        case .members: return .group
        case .addStorage: return .storage
        case .security: return .security
        case .accountInfo: return .accountInfo
        case .invitations: return .mail
        case .activityFeed: return .alert
        case .logOut: return UIImage.logOut.templated
        }
    }
    
    var title: String {
        switch self {
        case .files: return .myFiles
        case .shares: return .shares
        case .members: return String.member.pluralized()
        case .invitations: return .invitations
        case .activityFeed: return .activityFeed
        case .addStorage: return String.addStorage
        case .accountInfo: return String.accountInfo
        case .security: return String.security
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
