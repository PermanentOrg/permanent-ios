//  
//  ShareStatus.swift
//  Permanent
//
//  Created by Adrian Creteanu on 13.01.2021.
//

import Foundation

enum ShareStatus {
    
    /// Approval has not been requested.
    case needsApproval

    /// Approval has been requested.
    case pending
    
    /// Share has been given approval.
    case accepted
    
    static func status(forValue value: String?) -> ShareStatus {
        switch value {
        case Constants.API.AccountStatus.ok: return .accepted
        case Constants.API.AccountStatus.pending: return .pending
        default: return .needsApproval
        }
    }
    
    var infoText: String {
        switch self {
        case .needsApproval: return .requestApproval
        case .pending: return .requestAwaitingApproval
        case .accepted: return .viewInArchive
        }
    }
    
}
