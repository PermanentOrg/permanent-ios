//  
//  AccountStatus.swift
//  Permanent
//
//  Created by Adrian Creteanu on 08.01.2021.
//

import Foundation

enum AccountStatus: String {
    // Account has been approved.
    case ok
    
    /// Account is pending approval.
    case pending
    
    /// Unknown status.
    case unknown
    
    static func status(forValue value: String?) -> AccountStatus {
        switch value {
        case Constants.API.AccountStatus.ok: return .ok
        case Constants.API.AccountStatus.pending: return .pending
        default: return .unknown
        }
    }
    
    var value: String {
        switch self {
        case .pending: return String.pending.lowercased()
        default: return ""
        }
    }
}
