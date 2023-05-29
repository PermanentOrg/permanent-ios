//
//  LegacyPlanning.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.05.2023.
//

import Foundation

struct LegacyPlanningSteward {
    var name: String
    var email: String
    var legacyContactId: String = ""
    var status: StewardStatus
    var type: StewardType

    enum StewardStatus: String {
        case pending
        case accepted
        case declined
    }
    
    enum StewardType: String {
        case account
        case archive
    }

    func currentStatus() -> String {
        switch status {
        case .pending:
            return "Pending invitation"
        case .accepted:
            return "Accepted"
        case .declined:
            return "Declined"
        }
    }
}
