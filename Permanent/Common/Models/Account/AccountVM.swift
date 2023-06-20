//  
//  AccountVM.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.12.2020.
//

import Foundation

struct AccountVM: Account {
    var accountId: Int
    var name: String
    var email: String
    var accessRole: AccessRole = .viewer
    var status: AccountStatus
        
    init(accountVO: AccountVO) {
        self.accountId = accountVO.accountVO?.accountID ?? -1
        self.name = accountVO.accountVO?.fullName ?? ""
        self.email = accountVO.accountVO?.primaryEmail ?? ""
        self.accessRole = AccessRole.roleForValue(accountVO.accountVO?.accessRole)
        self.status = AccountStatus.status(forValue: accountVO.accountVO?.status)
    }
}
