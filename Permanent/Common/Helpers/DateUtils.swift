//
//  DateUtils.swift
//  Permanent
//
//  Created by Adrian Creteanu on 27/10/2020.
//

import Foundation

open class DateUtils {
    class var currentDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter.string(from: Date())
    }

    class var fileTimestamp: String {
        return fileTimestampString(for: Date())
    }

    /// Testable core of `fileTimestamp`. 24-hour `HH` (not 12-hour `hh`): a 12-hour timestamp
    /// with no AM/PM marker collides (1:30 PM and 1:30 AM both render "013000"), silently
    /// overwriting an earlier capture. en_US_POSIX keeps it Gregorian on non-Gregorian-calendar
    /// devices.
    static func fileTimestampString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }

    /// Single source of truth for a record's user-facing date — "Sept. 16, 2023" per the
    /// Figma spec (abbreviated month + period + non-padded day + year). Accepts either a
    /// full ISO timestamp ("2018-03-30T19:14:18.000Z") or an already-truncated
    /// "yyyy-MM-dd": both are normalized with `String.dateOnly` first, so the milliseconds
    /// and timezone that broke the old per-view-model formatters (which parsed with
    /// "yyyy-MM-dd'T'HH:mm:ss" and fell through to showing the raw ISO string) no longer
    /// matter. Parsing uses en_US_POSIX for stability; display uses en_US so the month
    /// abbreviation ("Sept.") and separators stay consistent regardless of device locale.
    /// Returns "" for nil / empty / the "-" placeholder.
    static func displayDate(from raw: String?) -> String {
        guard let raw = raw, raw != "-" else { return "" }
        let dateOnly = raw.dateOnly
        guard !dateOnly.isEmpty else { return "" }

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = "yyyy-MM-dd"
        guard let date = parser.date(from: dateOnly) else { return "" }

        let display = DateFormatter()
        display.locale = Locale(identifier: "en_US")
        display.dateFormat = "MMM. d, yyyy"
        return display.string(from: date)
    }

    /// Parses the backend's ISO timestamps (e.g. "2018-03-30T19:14:18.000Z") into a `Date`,
    /// tolerating the presence or absence of fractional seconds and a timezone. The old
    /// per-cell `"yyyy-MM-dd'T'HH:mm:ss"` parser silently failed on the ".000Z" suffix,
    /// which left the metadata Date field blank. Interprets zone-less input as GMT (matching
    /// the previous cell behavior). Returns nil for empty / "-" / unparseable input.
    static func date(fromISO raw: String?) -> Date? {
        guard let raw = raw, !raw.isEmpty, raw != "-" else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        // Stela emits several shapes across endpoints (mirrors FilesViewModel.parseSortDate):
        // ISO with/without fractional seconds, the Postgres timestamptz form with a space
        // separator and hour-only "+00" offset (lowercase `x`), and zone-less/date-only.
        for pattern in ["yyyy-MM-dd'T'HH:mm:ss.SSSZ",
                        "yyyy-MM-dd'T'HH:mm:ssZ",
                        "yyyy-MM-dd HH:mm:ss.SSSx",
                        "yyyy-MM-dd HH:mm:ssx",
                        "yyyy-MM-dd'T'HH:mm:ss",
                        "yyyy-MM-dd"] {
            formatter.dateFormat = pattern
            if let date = formatter.date(from: raw) { return date }
        }
        return nil
    }
}
