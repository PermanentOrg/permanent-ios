//
//  ComplexDateText.swift
//  Permanent
//
//  Created by Lucian Cerbu on 18.11.2026.
//

import Foundation

/// How a complex `displayTime` reads on screen: a range, an open end, or an approximate, uncertain or partly
/// unknown date. A value it cannot read shows "Unknown", never a wrong date.
struct ComplexDateText: Equatable {
    /// A piece of the list line; muted pieces are the lighter words such as "After", "AM" and "?".
    struct Segment: Equatable {
        let text: String
        let isMuted: Bool
    }

    /// One line of the Info Date box; a range labels its lines "From" and "To".
    struct InfoLine: Equatable {
        let label: String?
        let text: String
    }

    let listSegments: [Segment]
    let qualifiers: [String]
    let infoLines: [InfoLine]
    /// The list line without "c." and "?", which VoiceOver reads as symbols.
    let spokenText: String

    var listText: String { listSegments.map(\.text).joined() }
    /// "Approximate, Uncertain, 1985": the marks as words, then the date.
    var voiceOverText: String {
        (qualifiers + [spokenText]).joined(separator: ", ").replacingOccurrences(of: Self.separator, with: ", ")
    }
    var infoText: String { infoLines.map { [$0.label, $0.text].compactMap { $0 }.joined(separator: " ") }.joined(separator: ", ") }

    static let separator = "  •  "
    static let rangeDash = " — "

    /// - Parameters:
    ///   - zoneSuffix: the zone label for one end as written, marks removed; shown after its clock time in Info,
    ///     so each end follows the same rule as one exact date.
    init(_ raw: String, timeZone: TimeZone = .current, zoneSuffix: (String) -> String? = { _ in nil }) {
        let ends = raw.components(separatedBy: "/")
        guard ends.count <= 2 else {
            self = .unknown
            return
        }
        let suffixes = ends.map { zoneSuffix($0.filter { !"?~%".contains($0) }) }
        let points = ends.map { Point.isOpen($0) && ends.count == 2 ? nil : Point($0, timeZone: timeZone) }
        let readsEveryEnd = zip(ends, points).allSatisfy { (Point.isOpen($0) && ends.count == 2) || $1 != nil }
        guard readsEveryEnd, points.contains(where: { $0 != nil }) || ends.count == 2 else {
            self = .unknown
            return
        }

        var qualifiers: [String] = []
        if points.contains(where: { $0?.approximate == true }) { qualifiers.append("ComplexDateApproximate".localized()) }
        if points.contains(where: { $0?.uncertain == true }) { qualifiers.append("ComplexDateUncertain".localized()) }
        if points.contains(where: { $0?.unspecified == true }) { qualifiers.append("ComplexDateUnspecified".localized()) }
        let unknown = "ComplexDateUnknown".localized()

        let after = "ComplexDateAfter".localized() + " "
        let before = "ComplexDateBefore".localized() + " "
        let info: [InfoLine]
        // The list line, with or without the "c." and "?" marks.
        let line: (Bool) -> [Segment]
        if ends.count == 1, let point = points.first.flatMap({ $0 }) {
            line = { point.qualified(point.shortSegments(), marks: $0) }
            info = [InfoLine(label: nil, text: point.longText(zoneSuffix: suffixes[0]))]
        } else {
            switch (points[0], points[1]) {
            case let (start?, end?):
                line = { Self.range(start, end, marks: $0) }
                info = [
                    InfoLine(label: "ComplexDateFrom".localized(), text: start.longText(zoneSuffix: suffixes[0])),
                    InfoLine(label: "ComplexDateTo".localized(), text: end.longText(zoneSuffix: suffixes[1]))
                ]

            case let (start?, nil):
                line = { [Segment(text: after, isMuted: true)] + start.qualified(start.shortSegments(), marks: $0) }
                info = [InfoLine(label: nil, text: after + start.longText(zoneSuffix: suffixes[0]))]

            case let (nil, end?):
                line = { [Segment(text: before, isMuted: true)] + end.qualified(end.shortSegments(), marks: $0) }
                info = [InfoLine(label: nil, text: before + end.longText(zoneSuffix: suffixes[1]))]

            case (nil, nil):
                line = { _ in [Segment(text: unknown, isMuted: false)] }
                info = [InfoLine(label: nil, text: unknown)]
            }
        }
        self.init(listSegments: line(true), qualifiers: qualifiers, infoLines: info, spokenText: line(false).map(\.text).joined())
    }

    private init(listSegments: [Segment], qualifiers: [String], infoLines: [InfoLine], spokenText: String) {
        self.listSegments = listSegments
        self.qualifiers = qualifiers
        self.infoLines = infoLines
        self.spokenText = spokenText
    }

    /// A value that does not read.
    static var unknown: Self {
        let text = "ComplexDateUnknown".localized()
        return Self(listSegments: [Segment(text: text, isMuted: false)], qualifiers: [], infoLines: [InfoLine(label: nil, text: text)], spokenText: text)
    }

    /// Two dates on one line. Plain days in the same year drop the first year, and in the same month the
    /// second month too; one day with two clock times shows the day once.
    private static func range(_ start: Point, _ end: Point, marks: Bool) -> [Segment] {
        let dash = Segment(text: rangeDash, isMuted: false)
        if start.isPlainDay, end.isPlainDay, let year = start.year, year == end.year, let month = start.month, let day = start.day,
           let endMonth = end.month, let endDay = end.day {
            let first = Point.formatted(year: year, month: month, day: day, pattern: "MMM. d")
            let second = month == endMonth
                ? "\(endDay), \(year)"
                : Point.formatted(year: year, month: endMonth, day: endDay, pattern: "MMM. d, yyyy")
            return [Segment(text: first, isMuted: false), dash, Segment(text: second, isMuted: false)]
        }
        if start.isSameDay(as: end), !start.isQualified, !end.isQualified, start.hasClock, end.hasClock {
            return start.shortSegments() + [dash] + end.clockSegments(leading: "")
        }
        return start.qualified(start.shortSegments(), marks: marks) + [dash] + end.qualified(end.shortSegments(), marks: marks)
    }
}

private extension ComplexDateText {
    /// One end of a value: its known fields, a clock time as written or on the phone's clock, and its marks.
    struct Point: Equatable {
        var year: Int?
        var decade: String?
        var month: Int?
        var day: Int?
        var hour: Int?
        var minute: Int?
        var approximate = false
        var uncertain = false
        /// The month or day is written as `XX`, so the date shown is less exact than the value.
        var unspecified = false

        /// An empty end or `..` leaves that side of a range open.
        static func isOpen(_ text: String) -> Bool { text.isEmpty || text == ".." }

        init?(_ raw: String, timeZone: TimeZone) {
            approximate = raw.contains("~") || raw.contains("%")
            uncertain = raw.contains("?") || raw.contains("%")
            let text = raw.filter { !"?~%".contains($0) }
            let halves = text.components(separatedBy: "T")
            guard halves.count <= 2, readDate(halves[0]) else { return nil }
            if halves.count == 2 {
                guard day != nil, readClock(halves[1], timeZone: timeZone) else { return nil }
            }
        }

        var isQualified: Bool { approximate || uncertain }
        var hasClock: Bool { hour != nil }
        var isPlainDay: Bool { day != nil && !hasClock && !isQualified }

        func isSameDay(as other: Self) -> Bool {
            year != nil && year == other.year && month == other.month && day != nil && day == other.day
        }

        /// "c. " before and " ?" after, both muted; left out when `marks` is false.
        func qualified(_ segments: [Segment], marks: Bool = true) -> [Segment] {
            guard marks else { return segments }
            return (approximate ? [Segment(text: "ComplexDateCirca".localized() + " ", isMuted: true)] : [])
                + segments
                + (uncertain ? [Segment(text: " ?", isMuted: true)] : [])
        }

        /// The list form: "1985", "1980s", "March 1980", "Sep. 30, 1980", then the clock when written.
        func shortSegments() -> [Segment] {
            [Segment(text: dateText(dayPattern: "MMM. d, yyyy"), isMuted: false)] + clockSegments()
        }

        /// "  •  12:56" then a muted " AM"; empty without a clock.
        func clockSegments(leading: String = ComplexDateText.separator) -> [Segment] {
            guard let clock = clockParts() else { return [] }
            return [Segment(text: leading + clock.time, isMuted: false), Segment(text: " " + clock.period, isMuted: true)]
        }

        /// The Info form: "October 23, 1985  •  4:16 PM" and the zone when given.
        func longText(zoneSuffix: String?) -> String {
            var text = dateText(dayPattern: "MMMM d, yyyy")
            if let clock = clockParts() {
                text += ComplexDateText.separator + clock.time + " " + clock.period
                if let zoneSuffix, !zoneSuffix.isEmpty { text += " " + zoneSuffix }
            }
            return text
        }

        private func dateText(dayPattern: String) -> String {
            guard let year else { return decade ?? "ComplexDateUnknown".localized() }
            guard let month else { return String(year) }
            guard let day else { return Self.formatted(year: year, month: month, day: 1, pattern: "MMMM yyyy") }
            return Self.formatted(year: year, month: month, day: day, pattern: dayPattern)
        }

        private func clockParts() -> (time: String, period: String)? {
            guard let hour, let minute else { return nil }
            let twelve = hour % 12 == 0 ? 12 : hour % 12
            return (String(format: "%d:%02d", twelve, minute), (hour < 12 ? "ComplexDateAM" : "ComplexDatePM").localized())
        }

        static func formatted(year: Int, month: Int, day: Int, pattern: String) -> String {
            guard let date = gmtCalendar.date(from: DateComponents(year: year, month: month, day: day)),
                  let formatter = formatters[pattern] else { return String(year) }
            let text = formatter.string(from: date)
            // The dot marks a cut name, so a month as short as "May" keeps none.
            let symbols = formatter.shortMonthSymbols ?? []
            guard pattern.hasPrefix("MMM."), symbols.indices.contains(month - 1),
                  symbols[month - 1] == formatter.monthSymbols?[month - 1] else { return text }
            return text.replacingOccurrences(of: symbols[month - 1] + ".", with: symbols[month - 1])
        }

        private static let gmtCalendar: Calendar = {
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = .gmt
            return calendar
        }()

        /// One formatter per pattern, made once; a list cell reads several dates on every scroll.
        private static let formatters: [String: DateFormatter] = Dictionary(uniqueKeysWithValues: [
            "MMM. d", "MMM. d, yyyy", "MMMM yyyy", "MMMM d, yyyy", "yyyy-MM-dd"
        ].map { pattern in
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_US")
            formatter.calendar = gmtCalendar
            formatter.timeZone = .gmt
            formatter.dateFormat = pattern
            return (pattern, formatter)
        })

        /// `YYYY`, `YYYY-MM`, `YYYY-MM-DD`, with `X` for unknown digits. A partly unknown year reads as its
        /// decade or century, and an unknown month or day is left out.
        private mutating func readDate(_ text: String) -> Bool {
            let fields = text.components(separatedBy: "-")
            guard (1...3).contains(fields.count), fields[0].count == 4 else { return false }
            let yearText = fields[0]
            guard yearText.allSatisfy({ $0.isASCII && ($0.isNumber || $0 == "X") }) else { return false }
            if yearText.contains("X") {
                let digits = yearText.prefix { $0 != "X" }
                guard !digits.isEmpty, yearText.dropFirst(digits.count).allSatisfy({ $0 == "X" }), let lead = Int(digits) else {
                    return fields.dropFirst().allSatisfy { $0 == "XX" }
                }
                let scale = Int(pow(10, Double(4 - digits.count)))
                decade = "\(lead * scale)s"
                return true
            }
            year = Int(yearText)
            guard fields.count > 1 else { return true }
            guard fields[1] != "XX" else {
                unspecified = true
                return fields.dropFirst(2).allSatisfy { $0 == "XX" }
            }
            guard fields[1].count == 2, let month = Int(fields[1]), (1...12).contains(month) else { return false }
            self.month = month
            guard fields.count > 2 else { return true }
            guard fields[2] != "XX" else {
                unspecified = true
                return true
            }
            guard fields[2].count == 2, let day = Int(fields[2]), let year,
                  Self.formatted(year: year, month: month, day: day, pattern: "yyyy-MM-dd") == String(format: "%04d-%02d-%02d", year, month, day)
            else { return false }
            self.day = day
            return true
        }

        /// `hh:mm:ss` with an optional fraction, then nothing, `Z` or an offset. A `Z` time moves to the phone's clock.
        private mutating func readClock(_ text: String, timeZone: TimeZone) -> Bool {
            var clock = text
            var isUTC = false
            if clock.hasSuffix("Z") {
                clock.removeLast()
                isUTC = true
            } else if let sign = clock.firstIndex(where: { $0 == "+" || $0 == "-" }) {
                clock = String(clock[..<sign])
            }
            let parts = (clock.components(separatedBy: ".").first ?? "").components(separatedBy: ":")
            guard parts.count == 3, parts.allSatisfy({ $0.count == 2 }), let hour = Int(parts[0]), let minute = Int(parts[1]),
                  hour < 24, minute < 60 else { return false }
            self.hour = hour
            self.minute = minute
            if isUTC { moveToPhoneClock(timeZone) }
            return true
        }

        private mutating func moveToPhoneClock(_ timeZone: TimeZone) {
            var utc = Calendar(identifier: .gregorian)
            utc.timeZone = .gmt
            guard let year, let month, let day, let hour, let minute,
                  let moment = utc.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute)) else { return }
            var local = Calendar(identifier: .gregorian)
            local.timeZone = timeZone
            let parts = local.dateComponents([.year, .month, .day, .hour, .minute], from: moment)
            self.year = parts.year
            self.month = parts.month
            self.day = parts.day
            self.hour = parts.hour
            self.minute = parts.minute
        }
    }
}
