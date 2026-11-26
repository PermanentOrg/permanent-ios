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
    /// a bare date; parses with `en_US_POSIX` and writes fixed English names, so neither locale nor iOS shifts it.
    static func displayDate(from raw: String?) -> String {
        guard let raw = raw, raw != "-" else { return "" }
        let dateOnly = raw.dateOnly
        guard !dateOnly.isEmpty else { return "" }

        // A year or a month alone comes from `displayTime`, and shows only what is known: "1985", "October 1985".
        let patterns = ["yyyy", "yyyy-MM", "yyyy-MM-dd"]
        let fieldCount = dateOnly.components(separatedBy: "-").count
        guard fieldCount <= patterns.count else { return "" }

        let parser = DateFormatter()
        parser.locale = Locale(identifier: "en_US_POSIX")
        parser.calendar = Calendar(identifier: .gregorian)
        parser.timeZone = .gmt
        parser.dateFormat = patterns[fieldCount - 1]
        guard let date = parser.date(from: dateOnly) else { return "" }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        let fields = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = fields.year else { return "" }
        return shortDateText(year: year, month: fieldCount > 1 ? fields.month : nil, day: fieldCount > 2 ? fields.day : nil)
    }

    /// "Sept. 16, 2023", "October 1985" or "1985": the list's form of a date, as Android and web write it.
    static func shortDateText(year: Int, month: Int?, day: Int?) -> String {
        let yearText = String(format: "%04d", year)
        guard let month, (1...12).contains(month) else { return yearText }
        guard let day else { return monthName(month) + " " + yearText }
        return "\(shortMonthName(month)) \(day), \(yearText)"
    }

    /// "Jan.", "May", "Sept.": fixed text, because the iOS short names differ between versions.
    static func shortMonthName(_ month: Int) -> String {
        let names = ["Jan.", "Feb.", "Mar.", "Apr.", "May", "Jun.", "Jul.", "Aug.", "Sept.", "Oct.", "Nov.", "Dec."]
        return names.indices.contains(month - 1) ? names[month - 1] : ""
    }

    /// "January" to "December"; empty for a month outside 1-12.
    static func monthName(_ month: Int) -> String {
        let names = [
            "January", "February", "March", "April", "May", "June",
            "July", "August", "September", "October", "November", "December"
        ]
        return names.indices.contains(month - 1) ? names[month - 1] : ""
    }

    /// The list's text: an exact date with a clock reads "Jun. 24, 2026 • 12:56 AM CT", anything else the day of
    /// `listDate`. A `Z` time shows on the phone's clock.
    /// - Parameters:
    ///   - zoneSuffix: the zone label for `displayTime`, asked only when it has a clock.
    static func listDateText(
        displayTime: String?, listDate: String?, timeZone: TimeZone = .current, zoneSuffix: (String) -> String? = { _ in nil }
    ) -> String {
        guard let displayTime, let parts = level0Start(displayTime)?.parts, parts.hour != nil,
              let date = date(fromDisplayTime: displayTime, timeZone: timeZone) else { return displayDate(from: listDate) }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let shown = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = shown.year else { return displayDate(from: listDate) }
        let text = shortDateText(year: year, month: shown.month, day: shown.day) + " • " + formatted(date, pattern: "h:mm a", timeZone: timeZone)
        guard let zone = zoneSuffix(displayTime), !zone.isEmpty else { return text }
        return text + " " + zone
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

    // MARK: - displayTime (EDTF Level 0)

    /// True for a `displayTime` that is set but is not one exact Level 0 date: a range, an open end, or an
    /// approximate, uncertain or unknown date. The app never overwrites it.
    static func isComplexDate(_ raw: String?) -> Bool {
        guard let raw = raw, !raw.isEmpty else { return false }
        return level0DateTime(raw) == nil
    }

    /// True for a complex date the app may only show: every one but a year with an unknown month or day.
    static func isWebOnlyDate(_ raw: String?) -> Bool {
        isComplexDate(raw) && yearOfUnknownMonth(raw) == nil
    }

    /// True when the date sheet must send the member to web. Every web-only date does, but one: the full sheet,
    /// which holds qualifiers and ranges, opens a complex date it can read side by side.
    static func blocksDateEdit(_ raw: String?, fullSheet: Bool) -> Bool {
        guard isWebOnlyDate(raw) else { return false }
        return !fullSheet || DisplayTimeValue(raw) == nil
    }

    /// "1985" for `1985-XX` and `1985-XX-XX`, which say no more than the year; nil for anything else.
    static func yearOfUnknownMonth(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let fields = raw.components(separatedBy: "-")
        guard (2...3).contains(fields.count), fields.dropFirst().allSatisfy({ $0 == "XX" }),
              level0Date(fields[0]) != nil else { return nil }
        return fields[0]
    }

    /// The value the screens read and the date sheet edits: a year with an unknown month or day as the year alone.
    private static func editableDisplayTime(_ raw: String?) -> String? {
        yearOfUnknownMonth(raw) ?? raw
    }

    /// A list's date: `displayTime` as written ("1985-10-23"), a `Z` time as the phone's day, else the old field
    /// while shown, else "-". A web-only date gives "", as the row shows it through `ComplexDateText`.
    static func listDate(
        displayTime: String?, legacy: String?, timeZone: TimeZone = .current,
        onlyEDTF: Bool = FeatureFlags.shared.showsOnlyEDTFDate
    ) -> String {
        guard !isWebOnlyDate(displayTime) else { return "" }
        if let start = level0Start(displayTime) {
            guard start.parts.timeZone != nil, let date = date(fromDisplayTime: displayTime, timeZone: timeZone) else {
                return start.text.dateOnly
            }
            return formatted(date, pattern: "yyyy-MM-dd", timeZone: timeZone)
        }
        return shownLegacy(legacy, onlyEDTF: onlyEDTF)?.dateOnly ?? "-"
    }

    /// The old field as a screen may show it: nil while the server's `edtf-date` switch is on, as on web.
    static func shownLegacy(_ legacy: String?, onlyEDTF: Bool = FeatureFlags.shared.showsOnlyEDTFDate) -> String? {
        onlyEDTF ? nil : legacy
    }

    /// `displayTime` as a `Date`: the clock time as written on the phone's clock, with any offset left out.
    /// A `Z` time is a moment in UTC, as the old web editor writes it. Nil when not EDTF Level 0.
    static func date(fromDisplayTime raw: String?, timeZone: TimeZone = .current) -> Date? {
        guard let parts = level0Start(raw)?.parts else { return nil }
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

    /// The Info Date row: "October 23, 1985 • 5PM", "October 1985" or "1985", then the zone. `displayTime` first,
    /// else the old field while shown; nil when neither reads and for a complex date. "Oct." with a short month.
    static func infoRowDate(
        displayTime: String?, legacy: String?, zoneAbbreviation: String? = nil, timeZone: TimeZone = .current,
        onlyEDTF: Bool = FeatureFlags.shared.showsOnlyEDTFDate, shortMonth: Bool = false
    ) -> String? {
        guard !isWebOnlyDate(displayTime) else { return nil }
        let text: String
        if let parts = level0Start(displayTime)?.parts, let date = date(fromDisplayTime: displayTime, timeZone: timeZone) {
            let month = shortMonth ? "MMM." : "MMMM"
            let dayPattern = parts.day != nil ? "\(month) d, yyyy" : parts.month != nil ? "\(month) yyyy" : "yyyy"
            text = formatted(date, pattern: dayPattern, timeZone: timeZone) + (parts.hour != nil ? clockText(date, timeZone: timeZone) : "")
        } else if let date = date(fromISO: shownLegacy(legacy, onlyEDTF: onlyEDTF)) {
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

    /// The fields of a Level 0 `displayTime` as written: the year, then the month, day and clock when given.
    /// Nil when not one exact Level 0 date.
    static func displayTimeParts(_ raw: String?) -> DateComponents? {
        level0Start(raw)?.parts
    }

    /// The offset a Level 0 date-time carries, as written ("+01:00"); nil without one. A `Z` time is shown on
    /// the phone's clock, so it keeps none.
    static func displayTimeOffset(_ raw: String?) -> String? {
        guard let text = level0Start(raw)?.text, let clock = text.components(separatedBy: "T").dropFirst().first,
              let sign = clock.firstIndex(where: { $0 == "+" || $0 == "-" }) else { return nil }
        return String(clock[sign...])
    }

    /// True when every `displayTime` is empty, so the old field is the date the app shows and a V1
    /// `displayDT` write would be seen. A complex date counts as set.
    static func showsLegacyDate(displayTimes: [String?]) -> Bool {
        displayTimes.allSatisfy { $0?.isEmpty ?? true }
    }

    /// One exact EDTF Level 0 date and its fields, a year with an unknown month or day as the year; nil for
    /// anything else, a range included.
    private static func level0Start(_ raw: String?) -> (text: String, parts: DateComponents)? {
        guard let raw = editableDisplayTime(raw) else { return nil }
        return level0DateTime(raw).map { (text: raw, parts: $0) }
    }

    /// The fields of one exact Level 0 date, with its clock when written; `DisplayTimeValue` reads each side with it.
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
