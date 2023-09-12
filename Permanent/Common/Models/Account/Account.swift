//  
//  Account.swift
//  Permanent
//
//  Created by Adrian Creteanu on 23.12.2020.
//

import Foundation

protocol Account {
    var accountId: Int { get }
    
    var name: String { get }
    
    var email: String { get }
    
    var accessRole: AccessRole { get }
    
    var status: AccountStatus { get }
}
