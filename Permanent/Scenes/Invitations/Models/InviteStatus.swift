//  
//  InviteStatus.swift
//  Permanent
//
//  Created by Adrian Creteanu on 27.01.2021.
//

import Foundation

enum InviteStatus: String {
    
    /// Invite has been accepted.
    case accepted
    
    /// Invite has been revoked.
    case revoked
    
    /// Invite is pending confirmation.
    case pending
    
    /// Invite has been rejected.
    case rejected
    
    /// Invite status is unknown.
    case unknown
    
    static func status(forValue value: String?) -> InviteStatus {
        switch value {
        case Constants.API.InviteStatus.STATUS_INVITE_ACCEPTED: return .accepted
        case Constants.API.InviteStatus.STATUS_INVITE_REVOKED: return .revoked
        case Constants.API.InviteStatus.STATUS_INVITE_PENDING: return .pending
        case Constants.API.InviteStatus.STATUS_INVITE_REJECTED: return .rejected
        default: return .unknown
        }
    }
    
}
