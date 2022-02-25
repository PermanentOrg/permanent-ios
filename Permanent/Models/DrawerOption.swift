//  
//  DrawerOption.swift
//  Permanent
//
//  Created by Adrian Creteanu on 25.11.2020.
//

import UIKit

enum DrawerOption {
    case archives
    case files
    case shares
    case publicFiles
    case members
    case manageArchives
    case publicGallery
    case addStorage
    case accountInfo
    case security
    case activityFeed
    case invitations
    case logOut
    case contactSupport
    case none
    
    var icon: UIImage? {
        switch self {
        case .files: return UIImage(named: "privateFilesIcon")!
        case .publicFiles: return UIImage(named: "publicFilesIcon")!
        case .shares: return UIImage(named: "sharedFilesIcon")!
        case .members: return UIImage(named: "manageMembersIcon")!
        case .manageArchives: return UIImage(named: "manageArchivesIcon")!
        case .publicGallery: return UIImage(named: "publicGalleryIcon")!
        case .addStorage: return .storage
        case .security: return .security
        case .accountInfo: return .accountInfo
        case .invitations: return .mail
        case .activityFeed: return .alert
        case .archives: return nil
        case .logOut: return UIImage.logOut.templated
        case .contactSupport: return nil
        case .none: return nil
        }
    }
    
    var title: String {
        switch self {
        case .files: return "Private Files".localized()
        case .publicFiles: return "Public Files".localized()
        case .shares: return "Shared Files".localized()
        case .members: return "Manage Members".localized()
        case .manageArchives: return "Archives".localized()
        case .publicGallery: return "Public Gallery".localized()
        case .invitations: return .invitations
        case .activityFeed: return .activityFeed
        case .addStorage: return String.addStorage
        case .accountInfo: return String.accountInfo
        case .security: return String.security
        case .logOut: return .logOut
        case .archives: return ""
        case .contactSupport: return .contactSupport
        case .none: return ""
        }
    }
    
    var isActive: Bool {
        switch self {
        case .files: return true
        default: return false
        }
    }
}
