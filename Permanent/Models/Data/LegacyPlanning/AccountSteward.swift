//
//  AccountSteward.swift
//  Permanent
//
//  Created by Flaviu Silaghi on 23.05.2023.

import Foundation

struct AccountSteward: Model {
    var legacyContactId: String
    var accountId: String?
    var name: String
    var email: String
    var createdDt: String?
    var updatedDt: String?
}
