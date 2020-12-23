//  
//  AccountVM.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.12.2020.
//

import Foundation

struct AccountVM: Account {
    var name: String
    var email: String
    var accessRole: AccessRole = .viewer
        
    init(accountVO: AccountVO) {
        self.name = accountVO.accountVO?.fullName ?? ""
        self.email = accountVO.accountVO?.primaryEmail ?? ""
        self.accessRole = AccessRole.roleForValue(accountVO.accountVO?.accessRole)
    }
    
    init(name: String, email: String, role: AccessRole) {
        self.name = name
        self.email = email
        self.accessRole = role
    }
    
}
