//  
//  InviteVM.swift
//  Permanent
//
//  Created by Adrian Creteanu on 26.01.2021.
//

import Foundation

struct InviteVM: Invite {
    var id: Int
    var name: String
    var email: String
    var status: InviteStatus
    
    init(invite: InviteVOData) {
        self.id = invite.inviteID ?? -1
        self.name = invite.fullName ?? ""
        self.email = invite.email ?? ""
        self.status = InviteStatus.status(forValue: invite.status)
    }
    
}
