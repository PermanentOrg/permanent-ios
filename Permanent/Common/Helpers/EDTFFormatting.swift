//
//  EDTFFormatting.swift
//  Permanent
//
//  Created by Lucian Cerbu on 14.10.2026.
//

import Foundation

/// The EDTF surface the app codes against. A protocol so tests and previews can stand in without
/// paying for a `JSContext`.
protocol EDTFFormatting {
    func string(from parts: EDTFDateParts) throws -> String
    func string(from interval: EDTFInterval) throws -> String
    /// Returns edtf.js's canonical form, the bytes Web stores. Throws for a string the server refuses,
    /// and for a datetime with no zone, which edtf.js would shift by the device timezone.
    func validated(_ text: String) throws -> String
    /// Reads a stored string back into the fields the editor holds. Throws for a value they cannot
    /// hold, such as a season, a set or a time.
    func value(from text: String) throws -> EDTFValue
}
