//  
//  InviteVM.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import Foundation

struct InviteVM: Invite {
    var name: String
    var email: String
    
    init(invite: InviteVOData) {
        self.name = invite.fullName ?? ""
        self.email = invite.email ?? ""
    }
    
}
