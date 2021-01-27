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
    
    func apiOperation(csrf: String) -> InviteEndpoint {
        switch self {
        case .send(let name, let email):
            return .sendInvite(name: name, email: email, csrf: csrf)
        case .resend(let id):
            return .resendInvite(id: id, csrf: csrf)
        case .revoke(let id):
            return .revokeInvite(id: id, csrf: csrf)
        }
    }
    
}
