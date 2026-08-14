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

    /// Testable core of `fileTimestamp`. 24-hour `HH`, because a 12-hour stamp with no AM/PM marker
    /// collides and overwrites an earlier capture. `en_US_POSIX` keeps it Gregorian everywhere.
    static func fileTimestampString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: date)
    }

    /// The one source of a record's user-facing date, e.g. "Sept. 16, 2023". Takes a full ISO stamp or
    /// a bare date; parses with `en_US_POSIX` and displays with `en_US`, so device locale can't shift it.
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

    /// Parses the backend's ISO timestamps, with or without fractional seconds and a timezone; a
    /// fixed-format parser silently fails on the ".000Z" suffix. Zone-less input is read as GMT.
    static func date(fromISO raw: String?) -> Date? {
        guard let raw = raw, !raw.isEmpty, raw != "-" else { return nil }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        // Stela emits several shapes: ISO with and without fractional seconds, Postgres timestamptz with
        // a space separator and hour-only offset, and zone-less or date-only.
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
