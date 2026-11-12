//
//  DateQualifiers.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import Foundation

/// How sure one side of a date is: approximate, uncertain, or not known at all.
struct DateQualifiers: OptionSet, Hashable {
    static let approximate = Self(rawValue: 1 << 0)
    static let uncertain = Self(rawValue: 1 << 1)
    static let unknown = Self(rawValue: 1 << 2)

    let rawValue: Int

    /// The EDTF symbol after the date: "~" approximate, "?" uncertain, "%" both. Nil for neither and for an
    /// unknown date, which has no date to follow.
    var symbol: String? {
        guard !contains(.unknown) else { return nil }
        switch (contains(.approximate), contains(.uncertain)) {
        case (true, true): return "%"
        case (true, false): return "~"
        case (false, true): return "?"
        case (false, false): return nil
        }
    }

    /// The words after the Info row's label: "Approximate", "Uncertain" or "Approximate • Uncertain".
    var words: String? {
        guard !contains(.unknown) else { return nil }
        var names: [String] = []
        if contains(.approximate) { names.append("DateApproximate".localized()) }
        if contains(.uncertain) { names.append("DateUncertain".localized()) }
        return names.isEmpty ? nil : names.joined(separator: " • ")
    }

    init(rawValue: Int) {
        self.rawValue = rawValue
    }

    /// Reads the symbol that ends a stored side; nil for any other character.
    init?(symbol: Character) {
        switch symbol {
        case "~": self = .approximate
        case "?": self = .uncertain
        case "%": self = [.approximate, .uncertain]
        default: return nil
        }
    }
}
