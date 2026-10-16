//
//  EDTFDateParts.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.10.2026.
//

import Foundation

/// The fields the date editor holds. There is no time component on purpose: a zone-less datetime is
/// rewritten to UTC per device, and the server keeps whatever arrives, so only date precision is safe.
struct EDTFDateParts: Codable, Equatable {
    /// Which components a `?` or `~` applies to. `all` is the usual case.
    enum Scope: String, Codable {
        case all, year, month, day
    }

    /// Which trailing components render as `XX`.
    enum Unspecified: String, Codable {
        case none, day, monthDay
    }

    /// 1 to 12. The bridge converts to the 0-based month edtf.js expects.
    var month: Int?
    var day: Int?
    var year: Int
    var uncertain: Bool
    var approximate: Bool
    var scope: Scope
    var unspecified: Unspecified

    init(
        year: Int,
        month: Int? = nil,
        day: Int? = nil,
        uncertain: Bool = false,
        approximate: Bool = false,
        scope: Scope = .all,
        unspecified: Unspecified = .none
    ) {
        self.year = year
        self.month = month
        self.day = day
        self.uncertain = uncertain
        self.approximate = approximate
        self.scope = scope
        self.unspecified = unspecified
    }
}
