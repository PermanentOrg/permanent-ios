//
//  DisplayTimeValue.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import Foundation

/// A stored `displayTime` as its shape: one side, or the two sides of a range. Nil for a string the app cannot
/// read, so callers fall back to the old field.
struct DisplayTimeValue: Equatable {
    enum Side: Equatable {
        /// A date, with a clock when written: the text without its symbol, its fields and its qualifiers.
        case written(text: String, parts: DateComponents, qualifiers: DateQualifiers)
        /// ".." in a range: this end is left open.
        case empty
        /// "XXXX-XX-XX", or nothing beside the "/" of a range.
        case unknown
    }

    static let unknownString = "XXXX-XX-XX"

    let start: Side
    /// Nil for a single value.
    let end: Side?

    /// The first side that holds a date: the start, else the end of a range with no start.
    var firstWritten: (text: String, parts: DateComponents)? {
        for case .written(let text, let parts, _)? in [start, end] {
            return (text, parts)
        }
        return nil
    }

    init?(_ raw: String?) {
        guard let raw else { return nil }
        let sides = raw.components(separatedBy: "/")
        switch sides.count {
        case 1:
            guard let start = Self.side(raw, inRange: false) else { return nil }
            self.start = start
            end = nil

        case 2:
            guard let start = Self.side(sides[0], inRange: true), let end = Self.side(sides[1], inRange: true) else { return nil }
            self.start = start
            self.end = end

        default:
            return nil
        }
    }

    /// One side as written. A symbol after a clock is refused: EDTF cannot qualify a time.
    private static func side(_ text: String, inRange: Bool) -> Side? {
        if text.uppercased() == unknownString { return .unknown }
        if inRange, text.isEmpty { return .unknown }
        if inRange, text == ".." { return .empty }

        var body = text
        var qualifiers: DateQualifiers = []
        if let last = body.last, let read = DateQualifiers(symbol: last) {
            qualifiers = read
            body.removeLast()
        }
        guard let parts = DateUtils.level0DateTime(body), qualifiers.isEmpty || parts.hour == nil else { return nil }
        return .written(text: body, parts: parts, qualifiers: qualifiers)
    }
}
