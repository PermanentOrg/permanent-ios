//  
//  Invite.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import Foundation

protocol Invite {
    
    var id: Int { get }
    
    var name: String { get }
    
    var email: String { get }
    
    var status: InviteStatus { get }
    
}
