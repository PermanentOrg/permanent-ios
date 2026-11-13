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

        // A year or a month alone comes from `displayTime`, and shows only what is known: "1985", "Oct. 1985".
        let formats = [("yyyy", "yyyy"), ("yyyy-MM", "MMM. yyyy"), ("yyyy-MM-dd", "MMM. d, yyyy")]
        let fieldCount = dateOnly.components(separatedBy: "-").count
        guard fieldCount <= formats.count else { return "" }
        let (pattern, shownPattern) = formats[fieldCount - 1]

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.dateFormat = pattern
        guard let date = parser.date(from: dateOnly) else { return "" }

        let display = DateFormatter()
        display.locale = Locale(identifier: "en_US")
        display.dateFormat = shownPattern
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

    // MARK: - displayTime

    /// The date a file list shows: the first written side's date as written ("1985", "1985-10", "1985-10-23"),
    /// "-" when no side is written. A string that does not read shows the old field's date while the screens do.
    static func listDate(displayTime: String?, legacy: String?, onlyEDTF: Bool = FeatureFlags.shared.showsOnlyEDTFDate) -> String {
        guard let value = DisplayTimeValue(displayTime) else {
            return shownLegacy(legacy, onlyEDTF: onlyEDTF)?.dateOnly ?? "-"
        }
        return value.firstWritten?.text.dateOnly ?? "-"
    }

    /// The old field as a screen may show it: nil while the server's `edtf-date` switch is on, as on web.
    static func shownLegacy(_ legacy: String?, onlyEDTF: Bool = FeatureFlags.shared.showsOnlyEDTFDate) -> String? {
        onlyEDTF ? nil : legacy
    }

    /// `displayTime` as a `Date`: the clock time as written on the phone's clock, with any offset left out.
    /// A `Z` time is a moment in UTC, as the old web editor writes it. Nil when no side holds a date.
    static func date(fromDisplayTime raw: String?, timeZone: TimeZone = .current) -> Date? {
        guard let parts = firstWrittenSide(raw)?.parts else { return nil }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = parts.timeZone ?? timeZone
        let start = DateComponents(
            year: parts.year,
            month: parts.month ?? 1,
            day: parts.day ?? 1,
            hour: parts.hour ?? 0,
            minute: parts.minute ?? 0,
            second: parts.second ?? 0
        )
        return calendar.date(from: start)
    }

    /// The `displayTime` web writes for a picked date: its clock time on the phone, plus the phone's UTC
    /// offset today rather than on that date ("2001-02-03T09:30:00+03:00").
    static func displayTime(from date: Date, timeZone: TimeZone = .current, now: Date = Date()) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        let offsetMinutes = timeZone.secondsFromGMT(for: now) / 60
        let sign = offsetMinutes < 0 ? "-" : "+"
        return formatter.string(from: date) + String(format: "%@%02d:%02d", sign, abs(offsetMinutes) / 60, abs(offsetMinutes) % 60)
    }

    /// The Stela V2 PATCH fields that save a picked date: `displayTime` only, as web sends them.
    static func displayTimeFields(for date: Date) -> [String: Any] {
        ["displayTime": displayTime(from: date)]
    }

    /// One date as the Info row words it: "October 23, 1985 • 5PM", "October 1985" or "1985", then the zone when
    /// given; "Oct." with a short month. The first written side, else the old field while shown, else nil.
    static func infoRowDate(
        displayTime: String?, legacy: String?, zoneAbbreviation: String? = nil, timeZone: TimeZone = .current,
        onlyEDTF: Bool = FeatureFlags.shared.showsOnlyEDTFDate, shortMonth: Bool = false
    ) -> String? {
        let text: String
        if let parts = firstWrittenSide(displayTime)?.parts, let date = date(fromDisplayTime: displayTime, timeZone: timeZone) {
            let month = shortMonth ? "MMM." : "MMMM"
            let dayPattern = parts.day != nil ? "\(month) d, yyyy" : parts.month != nil ? "\(month) yyyy" : "yyyy"
            text = formatted(date, pattern: dayPattern, timeZone: timeZone) + (parts.hour != nil ? clockText(date, timeZone: timeZone) : "")
        } else if DisplayTimeValue(displayTime) == nil, let date = date(fromISO: shownLegacy(legacy, onlyEDTF: onlyEDTF)) {
            text = formatted(date, pattern: "MMMM d, yyyy", timeZone: timeZone) + clockText(date, timeZone: timeZone)
        } else {
            return nil
        }
        guard let zone = zoneAbbreviation, !zone.isEmpty else { return text }
        return text + " " + zone
    }

    /// " • 5PM" on the hour, " • 4:16 PM" otherwise.
    private static func clockText(_ date: Date, timeZone: TimeZone) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let pattern = calendar.component(.minute, from: date) == 0 ? "ha" : "h:mm a"
        return " • " + formatted(date, pattern: pattern, timeZone: timeZone)
    }

    /// English month and AM/PM names in the given zone, with a plain space before AM or PM on every iOS.
    private static func formatted(_ date: Date, pattern: String, timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = timeZone
        formatter.dateFormat = pattern
        return formatter.string(from: date)
    }

    /// The fields of a `displayTime`'s first written side: the year, then the month, day and clock when given.
    /// Nil when no side holds a date.
    static func displayTimeParts(_ raw: String?) -> DateComponents? {
        firstWrittenSide(raw)?.parts
    }

    /// The offset the first written side's clock carries, as written ("+01:00"); nil without one. A `Z` time
    /// is shown on the phone's clock, so it keeps none.
    static func displayTimeOffset(_ raw: String?) -> String? {
        guard let text = firstWrittenSide(raw)?.text, let clock = text.components(separatedBy: "T").dropFirst().first,
              let sign = clock.firstIndex(where: { $0 == "+" || $0 == "-" }) else { return nil }
        return String(clock[sign...])
    }

    /// True when none of these `displayTime` values reads, so the old field is the date the app shows
    /// and a V1 `displayDT` write would be seen.
    static func showsLegacyDate(displayTimes: [String?]) -> Bool {
        displayTimes.allSatisfy { DisplayTimeValue($0) == nil }
    }

    /// The side every date reader starts from: the start, else the end of a range with no start, without its
    /// symbol. Nil when the string does not read or no side holds a date.
    private static func firstWrittenSide(_ raw: String?) -> (text: String, parts: DateComponents)? {
        DisplayTimeValue(raw)?.firstWritten
    }

    /// A Level 0 date, or date and clock: the body of one side, without its symbol.
    static func level0DateTime(_ text: String) -> DateComponents? {
        let halves = text.components(separatedBy: "T")
        guard halves.count <= 2, var parts = level0Date(halves[0]) else { return nil }
        guard halves.count == 2 else { return parts }
        guard parts.day != nil, let clock = level0Clock(halves[1]) else { return nil }
        parts.hour = clock.hour
        parts.minute = clock.minute
        parts.second = clock.second
        parts.timeZone = clock.timeZone
        return parts
    }

    /// `YYYY`, `YYYY-MM` or `YYYY-MM-DD`, and a real calendar day.
    private static func level0Date(_ text: String) -> DateComponents? {
        guard let numbers = digitFields(text.components(separatedBy: "-"), widths: [4, 2, 2]) else { return nil }
        let year = numbers[0]
        let month = numbers.count > 1 ? numbers[1] : nil
        let day = numbers.count > 2 ? numbers[2] : nil

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        guard let date = calendar.date(from: DateComponents(year: year, month: month ?? 1, day: day ?? 1)) else { return nil }
        let check = calendar.dateComponents([.year, .month, .day], from: date)
        guard check.year == year, check.month == (month ?? 1), check.day == (day ?? 1) else { return nil }
        return DateComponents(year: year, month: month, day: day)
    }

    /// `hh:mm:ss` with or without a fraction of a second, then nothing, `Z` or `±hh:mm`. A `Z` time keeps
    /// UTC as its zone; an offset is checked here and read back by `displayTimeOffset`.
    private static func level0Clock(_ text: String) -> DateComponents? {
        var clock = text
        var zone: TimeZone?
        if clock.hasSuffix("Z") {
            clock.removeLast()
            zone = .gmt
        } else if let sign = clock.firstIndex(where: { $0 == "+" || $0 == "-" }) {
            let offset = String(clock[clock.index(after: sign)...]).components(separatedBy: ":")
            guard let numbers = digitFields(offset, widths: [2, 2]), numbers.count == 2,
                  numbers[0] < 24, numbers[1] < 60 else { return nil }
            clock = String(clock[..<sign])
        }
        let wholeAndFraction = clock.components(separatedBy: ".")
        guard wholeAndFraction.count <= 2 else { return nil }
        if let fraction = wholeAndFraction.dropFirst().first {
            guard !fraction.isEmpty, fraction.allSatisfy({ $0.isASCII && $0.isNumber }) else { return nil }
        }
        guard let time = digitFields(wholeAndFraction[0].components(separatedBy: ":"), widths: [2, 2, 2]), time.count == 3,
              time[0] < 24, time[1] < 60, time[2] < 60 else { return nil }
        return DateComponents(timeZone: zone, hour: time[0], minute: time[1], second: time[2])
    }

    /// Each field as a number, when it has exactly its width in ASCII digits.
    private static func digitFields(_ fields: [String], widths: [Int]) -> [Int]? {
        guard fields.count <= widths.count else { return nil }
        var numbers: [Int] = []
        for (field, width) in zip(fields, widths) {
            guard field.count == width, field.allSatisfy({ $0.isASCII && $0.isNumber }), let number = Int(field) else { return nil }
            numbers.append(number)
        }
        return numbers
    }
}
