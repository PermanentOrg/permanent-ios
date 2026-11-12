//
//  DateTimeEntry.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import Foundation

/// What the date and time sheet holds: six typed fields, the time format and the chosen zone. The digits stay as
/// typed; the EDTF string and the preview line are built from them when asked.
struct DateTimeEntry: Hashable {
    /// The pill's state. A switch changes nothing the member typed; only the built hour reads differently.
    enum TimeFormat: CaseIterable, Equatable {
        case am, pm, h24

        var next: Self {
            switch self {
            case .am: return .pm
            case .pm: return .h24
            case .h24: return .am
            }
        }

        var label: String {
            switch self {
            case .am: return "TimeFormatAM".localized()
            case .pm: return "TimeFormatPM".localized()
            case .h24: return "TimeFormat24H".localized()
            }
        }
    }

    /// One typed field: its width, the field the focus moves to when it fills, and its names for the screen.
    enum Field: CaseIterable, Hashable {
        case year, month, day, hour, minute, second

        var limit: Int {
            self == .year ? 4 : 2
        }

        /// The field after this one in its box; the last field of a box keeps the focus.
        var next: Self? {
            switch self {
            case .year: return .month
            case .month: return .day
            case .hour: return .minute
            case .minute: return .second
            case .day, .second: return nil
            }
        }

        var placeholder: String {
            switch self {
            case .year: return "DatePlaceholderYear".localized()
            case .month: return "DatePlaceholderMonth".localized()
            case .day: return "DatePlaceholderDay".localized()
            case .hour: return "TimePlaceholderHour".localized()
            case .minute: return "TimePlaceholderMinute".localized()
            case .second: return "TimePlaceholderSecond".localized()
            }
        }

        var label: String {
            switch self {
            case .year: return "DateFieldYear".localized()
            case .month: return "DateFieldMonth".localized()
            case .day: return "DateFieldDay".localized()
            case .hour: return "TimeFieldHour".localized()
            case .minute: return "TimeFieldMinute".localized()
            case .second: return "TimeFieldSecond".localized()
            }
        }
    }

    var year = ""
    var month = ""
    var day = ""
    var hour = ""
    var minute = ""
    var second = ""
    var format: TimeFormat = .am
    /// The chosen zone's IANA id; nil until the member picks one or the record carries one.
    var timeZoneIdentifier: String?
    /// The offset the record's string carried ("+01:00"), kept for the preview and the repeated-hour rule.
    var storedOffset: String?
    /// Approximate, uncertain or unknown. EDTF has no symbol for a clock, so a side with a symbol writes its date only.
    var qualifiers: DateQualifiers = []

    init() {}

    /// One side of a stored value: its fields and qualifiers when written, Unknown switched on when unknown.
    init(side: DisplayTimeValue.Side, timeZoneIdentifier: String? = nil, timeZone: TimeZone = .current) {
        switch side {
        case .written(let text, _, let qualifiers):
            self.init(displayTime: text, legacy: nil, timeZoneIdentifier: timeZoneIdentifier, timeZone: timeZone)
            self.qualifiers = qualifiers

        case .empty, .unknown:
            self.init()
            self.timeZoneIdentifier = timeZoneIdentifier
            qualifiers = side == .unknown ? .unknown : []
        }
    }

    /// The fields from a record: `displayTime` as written, else the old field as a moment on the phone's clock
    /// while the screens still show it. The record's zone, when known, comes in as its id.
    init(
        displayTime: String?, legacy: String?, timeZoneIdentifier: String? = nil, timeZone: TimeZone = .current,
        onlyEDTF: Bool = FeatureFlags.shared.showsOnlyEDTFDate
    ) {
        self.timeZoneIdentifier = timeZoneIdentifier
        storedOffset = DateUtils.displayTimeOffset(displayTime)
        if let parts = DateUtils.displayTimeParts(displayTime) {
            if parts.timeZone != nil, let moment = DateUtils.date(fromDisplayTime: displayTime, timeZone: timeZone) {
                // A `Z` time is a moment in UTC, shown on the phone's clock as the Info row shows it.
                set(moment: moment, timeZone: timeZone)
            } else {
                set(written: parts)
            }
        } else if let moment = DateUtils.date(fromISO: DateUtils.shownLegacy(legacy, onlyEDTF: onlyEDTF)) {
            set(moment: moment, timeZone: timeZone)
        }
    }

    subscript(field: Field) -> String {
        get {
            switch field {
            case .year: return year
            case .month: return month
            case .day: return day
            case .hour: return hour
            case .minute: return minute
            case .second: return second
            }
        }
        set {
            switch field {
            case .year: year = newValue
            case .month: month = newValue
            case .day: day = newValue
            case .hour: hour = newValue
            case .minute: minute = newValue
            case .second: second = newValue
            }
        }
    }

    var isEmpty: Bool {
        [year, month, day, hour, minute, second].allSatisfy(\.isEmpty)
    }

    var hasTime: Bool {
        ![hour, minute, second].allSatisfy(\.isEmpty)
    }

    /// The chosen zone, built from its id; nil while none is chosen or this iOS does not know it.
    var zone: TimeZoneOption? {
        timeZoneIdentifier.flatMap(TimeZoneCatalog.option(for:))
    }

    /// The EDTF Level 0 string Stela gets: "1985", "1985-10", "1985-10-23" or "1985-10-23T17:00:00", then the
    /// zone's offset at that clock time when a zone is chosen. Fields pad to their width; an empty one stays empty.
    var edtfString: String? {
        level0String(offset: offsetSuffix)
    }

    /// This side of a saved value: the Level 0 string, or the date alone with its symbol after it.
    var sideString: String? {
        guard let symbol = qualifiers.symbol else { return edtfString }
        return dateString.map { $0 + symbol }
    }

    /// The side as edtf.js checks it before a save: the clock's offset, or its absence, reads as `Z`, as on web.
    var gateSideString: String? {
        qualifiers.symbol == nil ? level0String(offset: "Z") : sideString
    }

    /// "1985", "1985-10" or "1985-10-23"; nil with no date field typed.
    private var dateString: String? {
        var dateFields = [(year, 4), (month, 2), (day, 2)]
        while let last = dateFields.last, last.0.isEmpty {
            dateFields.removeLast()
        }
        guard !dateFields.isEmpty else { return nil }
        return dateFields.map { field, width in field.isEmpty ? "" : padded(field, width) }.joined(separator: "-")
    }

    /// The zone's offset at the typed clock time ("+01:00"); empty while no zone is chosen.
    private var offsetSuffix: String {
        guard let zone, let wallClock else { return "" }
        return TimeZoneOption.offsetSuffix(minutes: zone.offsetMinutes(at: wallClock, storedOffset: storedOffset))
    }

    private func level0String(offset: String) -> String? {
        guard !isEmpty else { return nil }
        var text = dateString ?? ""
        if hasTime {
            text += "T" + [String(format: "%02d", hour24), padded(minute, 2), padded(second, 2)].joined(separator: ":") + offset
        }
        return text
    }

    /// The hour the string carries: a 12-hour hour converts here only, so the typed digits never change.
    var hour24: Int {
        guard let typed = Int(hour) else { return 0 }
        switch format {
        case .am: return typed == 12 ? 0 : typed
        case .pm: return typed < 12 ? typed + 12 : typed
        case .h24: return typed
        }
    }

    /// The line under the title: what the Info row will show after the save; nil until the fields make a date. The
    /// suffix follows the string that will be saved, which carries an offset only with a zone.
    var preview: String? {
        previewText(shortMonth: false)
    }

    /// The preview with the month in full, or as "Oct." for one side of a range.
    func previewText(shortMonth: Bool) -> String? {
        DateUtils.infoRowDate(
            displayTime: edtfString, legacy: nil, zoneAbbreviation: zone == nil ? nil : timeSuffix, shortMonth: shortMonth
        )
    }

    /// After the time: the zone's short name at the clock time, else the stored offset as the tz database writes
    /// it ("+03"); nil without a time.
    var timeSuffix: String? {
        guard hasTime, let wallClock else { return nil }
        if let zone { return zone.shortName(at: wallClock, storedOffset: storedOffset) }
        return storedOffset.flatMap(TimeZoneOption.minutes(inOffset:)).map(TimeZoneOption.tzdataOffset(minutes:))
    }

    /// The fields as a clock time in no zone: a missing month or day reads as 1, a missing clock as midnight.
    /// Nil without a year.
    var wallClock: DateComponents? {
        guard let year = Int(year) else { return nil }
        return DateComponents(
            year: year, month: Int(month) ?? 1, day: Int(day) ?? 1,
            hour: hour24, minute: Int(minute) ?? 0, second: Int(second) ?? 0
        )
    }

    /// The clock time the zone list takes its offsets at: the fields, else now, so an empty sheet lists today's offsets.
    func offsetClock(now: Date = Date()) -> DateComponents {
        wallClock ?? Calendar(identifier: .gregorian).dateComponents([.year, .month, .day, .hour, .minute, .second], from: now)
    }

    /// The Info row's suffix for a record: its zone's short name at the written clock, else the string's offset.
    static func timeSuffix(displayTime: String?, timeZoneIdentifier: String?) -> String? {
        Self(displayTime: displayTime, legacy: nil, timeZoneIdentifier: timeZoneIdentifier).timeSuffix
    }

    /// The fields as a moment for the calendar in the given zone; `now` when the fields make no date.
    func pickerDate(timeZone: TimeZone = .current, now: Date = Date()) -> Date {
        guard let wallClock else { return now }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        return calendar.date(from: wallClock) ?? now
    }

    /// Writes the picked day into the date fields; the clock fields stay.
    mutating func set(date: Date, timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        year = parts.year.map { String(format: "%04d", $0) } ?? ""
        month = parts.month.map(twoDigits) ?? ""
        day = parts.day.map(twoDigits) ?? ""
    }

    /// Writes the wheels' values, each in the pill's format, as two digits.
    mutating func set(hour: Int, minute: Int, second: Int) {
        self.hour = twoDigits(hour)
        self.minute = twoDigits(minute)
        self.second = twoDigits(second)
    }

    mutating func clear() {
        self = Self()
    }

    // MARK: - Bounds

    /// Pulls a typed field back inside its bounds, padded to its width: a month past 12 reads 12, a day past its
    /// month's end reads that end, a zero reads the first value. A year or month also re-checks the day.
    mutating func clamp(_ field: Field, now: Date = Date()) {
        if let typed = Int(self[field]) {
            let bounds = bounds(of: field, now: now)
            let value = min(max(typed, bounds.lowerBound), bounds.upperBound)
            if value != typed {
                self[field] = String(format: "%0\(field.limit)d", value)
            }
        }
        if field == .year || field == .month {
            clamp(.day, now: now)
        }
    }

    /// What a field may hold: a year from 1 to this year, the day's end by the month and year typed so far, the
    /// hour by the pill, the clock fields to 59.
    func bounds(of field: Field, now: Date = Date()) -> ClosedRange<Int> {
        switch field {
        case .year: return 1...Calendar(identifier: .gregorian).component(.year, from: now)
        case .month: return 1...12
        case .day: return 1...lastDay
        case .hour: return format == .h24 ? 0...23 : 1...12
        case .minute, .second: return 0...59
        }
    }

    /// The month's last day for the year typed so far. A year still short reads as a leap year, so a 29 stays until
    /// the year says otherwise.
    private var lastDay: Int {
        guard let month = Int(month), (1...12).contains(month) else { return 31 }
        let calendar = Calendar(identifier: .gregorian)
        let year = self.year.count == 4 ? Int(self.year) ?? 2000 : 2000
        guard let start = calendar.date(from: DateComponents(year: year, month: month)),
              let days = calendar.range(of: .day, in: .month, for: start) else { return 31 }
        return days.count
    }

    // MARK: - Filling

    private mutating func set(moment: Date, timeZone: TimeZone) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        set(written: calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: moment))
    }

    private mutating func set(written parts: DateComponents) {
        year = parts.year.map { String(format: "%04d", $0) } ?? ""
        month = parts.month.map(twoDigits) ?? ""
        day = parts.day.map(twoDigits) ?? ""
        guard let hour24 = parts.hour else { return }
        format = hour24 < 12 ? .am : .pm
        hour = twoDigits(hour24 % 12 == 0 ? 12 : hour24 % 12)
        minute = twoDigits(parts.minute ?? 0)
        second = twoDigits(parts.second ?? 0)
    }

    private func twoDigits(_ number: Int) -> String {
        String(format: "%02d", number)
    }

    private func padded(_ field: String, _ width: Int) -> String {
        String(repeating: "0", count: max(0, width - field.count)) + field
    }
}
