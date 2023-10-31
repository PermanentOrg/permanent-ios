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
    case manageMembers
    case manageTags
    case archiveSettings
    case manageArchives
    case publicGallery
    case addStorage
    case giftStorage
    case accountInfo
    case security
    case activityFeed
    case invitations
    case logOut
    case contactSupport
    case legacyPlanning
    case none
    
    var icon: UIImage? {
        switch self {
        case .files: return UIImage(named: "folderBookmark")!
        case .publicFiles: return UIImage(named: "folderBookmark")!
        case .shares: return UIImage(named: "folderBookmark")!
        case .archiveSettings: return UIImage(named: "gearContour")!
        case .manageArchives: return UIImage(named: "manageArchivesIcon")!
        case .publicGallery: return UIImage(named: "publicGalleryIcon")!
        case .addStorage: return .storage
        case .giftStorage: return nil
        case .security: return .security
        case .accountInfo: return .accountInfo
        case .invitations: return .mail
        case .activityFeed: return .alert
        case .archives: return nil
        case .manageMembers: return UIImage(named: "groupBorder")
        case .manageTags: return UIImage(named: "tagsBorder")
        case .logOut: return UIImage.logOut.templated
        case .contactSupport: return nil
        case .legacyPlanning: return UIImage(named: "legacyPlanning")
        case .none: return nil
        }
    }
    
    var title: String {
        switch self {
        case .files: return "Private Files".localized()
        case .publicFiles: return "Public Files".localized()
        case .shares: return "Shared Files".localized()
        case .archiveSettings: return "Archive Settings".localized()
        case .manageMembers: return "Manage Members".localized()
        case .manageTags: return "Manage Tags".localized()
        case .manageArchives: return "Archives".localized()
        case .publicGallery: return "Public Gallery".localized()
        case .invitations: return .invitations
        case .activityFeed: return .activityFeed
        case .addStorage: return String.addStorage
        case .giftStorage: return "Gift Storage"
        case .accountInfo: return String.accountInfo
        case .security: return String.security
        case .logOut: return .logOut
        case .archives: return ""
        case .contactSupport: return .contactSupport
        case .legacyPlanning: return "Legacy Planning".localized()
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
