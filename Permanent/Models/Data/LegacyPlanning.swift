//
//  LegacyPlanning.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.05.2023.
//

import Foundation

struct ArchiveSteward {
    var name: String
    var email: String
    var status: StewardStatus

    enum StewardStatus: String {
        case pending
        case accepted
        case declined
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
