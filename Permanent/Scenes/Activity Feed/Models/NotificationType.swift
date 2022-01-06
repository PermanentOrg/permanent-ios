//  
//  NotificationType.swift
//  Permanent
//
//  Created by Adrian Creteanu on 28.01.2021.
//

import UIKit.UIImage

enum NotificationType: String {
    
    case share
    
    case relationship
    
    case account
    
    case unknown
    
    var icon: UIImage? {
        switch self {
        case .share: return .sharesNotification
        case .account: return .accountNotification
        case .relationship: return .relationshipsNotification
        default: return nil
        }
    }
    
    static func type(forValue value: String?) -> NotificationType {
        switch value {
        case Constants.API.NotificationType.paShare: return .share
        case Constants.API.NotificationType.relationship: return .relationship
        case Constants.API.NotificationType.account: return .account
        default: return .unknown
        }
    }
}
