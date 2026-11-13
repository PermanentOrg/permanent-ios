//
//  TimeZoneOption.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import Foundation

/// One zone the picker can show: its id split into a region and a city, its country and generic name read from
/// Foundation in English, and its offset and short name at a clock time, since both move with the date.
struct TimeZoneOption: Hashable, Identifiable {
    let identifier: String
    let timeZone: TimeZone
    /// The id's first part ("Europe"); an id with no slash, such as "UTC", is its own region.
    let region: String
    /// The id's last part, underscores as spaces ("New York").
    let city: String
    /// Foundation's English name for the table's country code; nil for an id the table does not list.
    let countryName: String?
    /// Foundation's English generic name ("Central European Time").
    let genericName: String?

    static let english = Locale(identifier: "en_US")

    var id: String { identifier }

    /// "Romania, Bucharest", or the city alone for an id the table does not list.
    var placeName: String {
        countryName.map { "\($0), \(city)" } ?? city
    }

    /// Nil when this iOS does not know the id.
    init?(identifier: String) {
        guard let timeZone = TimeZone(identifier: identifier) else { return nil }
        self.identifier = identifier
        self.timeZone = timeZone
        let parts = identifier.components(separatedBy: "/")
        region = parts.first ?? identifier
        city = (parts.last ?? identifier).replacingOccurrences(of: "_", with: " ")
        countryName = TimeZoneCountryCodes.codes[identifier].flatMap { Self.english.localizedString(forRegionCode: $0) }
        genericName = timeZone.localizedName(for: .generic, locale: Self.english)
    }

    // MARK: - At a clock time

    /// The offset in minutes at a clock time typed for this zone. In a repeated hour the record's stored offset
    /// ("+02:00") is kept when it fits, else the earlier occurrence; a skipped hour moves forward, as Foundation does.
    func offsetMinutes(at wallClock: DateComponents, storedOffset: String? = nil) -> Int {
        guard let asUTC = Self.utcCalendar.date(from: wallClock) else {
            return timeZone.secondsFromGMT() / 60
        }
        let nearby = [-1.0, 0, 1].map { timeZone.secondsFromGMT(for: asUTC.addingTimeInterval($0 * 86_400)) }
        let fitting = Set(nearby).filter { timeZone.secondsFromGMT(for: asUTC.addingTimeInterval(-Double($0))) == $0 }
        if let stored = storedOffset.flatMap(Self.minutes(inOffset:)), fitting.contains(stored * 60) {
            return stored
        }
        if let earlier = fitting.max() {
            return earlier / 60
        }
        var local = Calendar(identifier: .gregorian)
        local.timeZone = timeZone
        return timeZone.secondsFromGMT(for: local.date(from: wallClock) ?? asUTC) / 60
    }

    /// "GMT+01:00", zero as "GMT+00:00", a minus west of Greenwich: the label on a list row and on the sheet's zone row.
    func offsetLabel(at wallClock: DateComponents) -> String {
        Self.offsetLabel(minutes: offsetMinutes(at: wallClock))
    }

    /// After the time: the English short name when it is letters ("EDT", "HST", "GMT"), else the offset as the
    /// tz database writes it ("+02", "+0530").
    func shortName(at wallClock: DateComponents, storedOffset: String? = nil) -> String {
        let minutes = offsetMinutes(at: wallClock, storedOffset: storedOffset)
        if let asUTC = Self.utcCalendar.date(from: wallClock) {
            let moment = asUTC.addingTimeInterval(-Double(minutes * 60))
            let style: TimeZone.NameStyle = timeZone.isDaylightSavingTime(for: moment) ? .shortDaylightSaving : .shortStandard
            if let name = timeZone.localizedName(for: style, locale: Self.english).flatMap(Self.lettersName) {
                return name
            }
        }
        return Self.tzdataOffset(minutes: minutes)
    }

    /// A Foundation short name when it is letters. A zero offset comes as "GMT" or as "GMT+0", depending on the
    /// system, and reads as "GMT" either way; any other offset form gives nil.
    static func lettersName(_ name: String) -> String? {
        if name == "GMT+0" { return "GMT" }
        return name.allSatisfy(\.isLetter) ? name : nil
    }

    /// What a search matches: the id's words, the generic name, the country and the offset label.
    func searchText(at wallClock: DateComponents) -> String {
        let idWords = identifier.replacingOccurrences(of: "_", with: " ").replacingOccurrences(of: "/", with: " ")
        return [idWords, genericName, countryName, offsetLabel(at: wallClock)].compactMap { $0 }.joined(separator: " ")
    }

    /// True when the text is somewhere in the search text, case and accents aside. An offset typed short, "+5" or
    /// "GMT-3", is read as the label writes it, "+05" or "-03".
    func matches(_ text: String, at wallClock: DateComponents) -> Bool {
        let needle = Self.offsetNeedle(in: text) ?? text
        return searchText(at: wallClock).range(of: needle, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }

    /// "+5", "GMT-3", "utc +5:30" or "+0530" as the label writes it: "+05", "-03", "+05:30"; nil for any other text.
    static func offsetNeedle(in text: String) -> String? {
        var rest = text.trimmingCharacters(in: .whitespaces).lowercased()
        for prefix in ["gmt", "utc"] where rest.hasPrefix(prefix) {
            rest = String(rest.dropFirst(prefix.count)).trimmingCharacters(in: .whitespaces)
        }
        guard let sign = rest.first, sign == "+" || sign == "-" else { return nil }
        let digits = rest.dropFirst().replacingOccurrences(of: ":", with: "")
        guard !digits.isEmpty, digits.count <= 4, digits.allSatisfy(\.isNumber) else { return nil }
        let hours = digits.count <= 2 ? digits : String(digits.dropLast(2))
        let minutes = digits.count <= 2 ? nil : String(digits.suffix(2))
        guard let hourValue = Int(hours), hourValue < 24 else { return nil }
        return String(format: "%@%02d", String(sign), hourValue) + (minutes.map { ":" + $0 } ?? "")
    }

    /// The row as VoiceOver reads it: "GMT plus 2, Romania, Bucharest".
    func spokenName(at wallClock: DateComponents) -> String {
        "\(Self.spokenOffset(minutes: offsetMinutes(at: wallClock))), \(placeName)"
    }

    // MARK: - Offsets as text

    /// "+01:00" or "-03:30" as minutes; nil for anything else.
    static func minutes(inOffset text: String) -> Int? {
        guard let sign = text.first, sign == "+" || sign == "-" else { return nil }
        let fields = text.dropFirst().components(separatedBy: ":")
        guard fields.count == 2, fields.allSatisfy({ $0.count == 2 }),
              let hours = Int(fields[0]), let minutes = Int(fields[1]), hours < 24, minutes < 60 else { return nil }
        return (sign == "-" ? -1 : 1) * (hours * 60 + minutes)
    }

    /// "+01:00", as the EDTF string writes it.
    static func offsetSuffix(minutes: Int) -> String {
        String(format: "%@%02d:%02d", minutes < 0 ? "-" : "+", abs(minutes) / 60, abs(minutes) % 60)
    }

    /// "GMT+01:00"; zero reads "GMT+00:00".
    static func offsetLabel(minutes: Int) -> String {
        "GMT" + offsetSuffix(minutes: minutes)
    }

    /// "GMT plus 2", "GMT minus 3:30", "GMT plus 0": the offset label as VoiceOver should read it.
    static func spokenOffset(minutes: Int) -> String {
        let hours = abs(minutes) / 60
        let rest = abs(minutes) % 60
        return "GMT \(minutes < 0 ? "minus" : "plus") " + (rest == 0 ? "\(hours)" : String(format: "%d:%02d", hours, rest))
    }

    /// "+02", "-0330", "+0530": an offset with no name, as the tz database abbreviates it.
    static func tzdataOffset(minutes: Int) -> String {
        let sign = minutes < 0 ? "-" : "+"
        guard abs(minutes) % 60 != 0 else { return String(format: "%@%02d", sign, abs(minutes) / 60) }
        return String(format: "%@%02d%02d", sign, abs(minutes) / 60, abs(minutes) % 60)
    }

    private static var utcCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .gmt
        return calendar
    }
}
