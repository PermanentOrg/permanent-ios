//  
//  InviteOperation.swift
//  Permanent
//
//  Created by Adrian Creteanu on 27.01.2021.
//

import Foundation

enum InviteOperation {
    
    case send(name: String, email: String)
    
    case resend(id: Int)
    
    case revoke(id: Int)
    
    func apiOperation() -> InviteEndpoint {
        switch self {
        case .send(let name, let email):
            return .sendInvite(name: name, email: email)
        case .resend(let id):
            return .resendInvite(id: id)
        case .revoke(let id):
            return .revokeInvite(id: id)
        }
    }
    
    var infoText: String {
        switch self {
        case .revoke: return .inviteRevoked
        default: return .inviteSent
        }
    }
    
}
