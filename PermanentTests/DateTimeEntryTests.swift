//
//  DateTimeEntryTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The date and time sheet's entry: the fields a record fills, the EDTF string each shape builds, the hour
/// each format sends, the zone's offset, the pickers' writes, the preview line and the bounds a typed field is pulled into.
struct DateTimeEntryTests {
    private let plusThree = TimeZone(secondsFromGMT: 3 * 3600) ?? .current
    private let utc = TimeZone(secondsFromGMT: 0) ?? .current

    // MARK: - Prefill

    @Test("A date-time with an offset fills every field as written, as a 12-hour PM clock")
    func prefillFromDateTimeWithOffset() {
        let entry = DateTimeEntry(displayTime: "1985-10-23T17:00:00+03:00", legacy: nil, timeZone: plusThree)

        #expect(fields(of: entry) == ["1985", "10", "23", "05", "00", "00"])
        #expect(entry.format == .pm)
    }

    @Test("A year alone, or a year and month, fills only those fields")
    func prefillFromPartialDates() {
        let year = DateTimeEntry(displayTime: "1985", legacy: "2023-08-15T00:00:00.000Z", timeZone: utc)
        let yearAndMonth = DateTimeEntry(displayTime: "1985-10", legacy: nil, timeZone: utc)

        #expect(fields(of: year) == ["1985", "", "", "", "", ""])
        #expect(year.format == .am)
        #expect(!year.hasTime)
        #expect(fields(of: yearAndMonth) == ["1985", "10", "", "", "", ""])
    }

    @Test("A morning clock reads as AM with its leading zero")
    func prefillMorningClock() {
        let entry = DateTimeEntry(displayTime: "2001-02-03T09:30:00", legacy: nil, timeZone: plusThree)

        #expect(fields(of: entry) == ["2001", "02", "03", "09", "30", "00"])
        #expect(entry.format == .am)
    }

    @Test("A Z time is a moment in UTC, shown on the phone's clock")
    func prefillFromUTCTime() {
        let entry = DateTimeEntry(displayTime: "1985-10-23T17:00:00Z", legacy: nil, timeZone: plusThree)

        #expect(fields(of: entry) == ["1985", "10", "23", "08", "00", "00"])
        #expect(entry.format == .pm)
    }

    @Test("Without a readable displayTime the old field fills the fields on the phone's clock")
    func prefillFromLegacy() {
        let noDisplayTime = DateTimeEntry(displayTime: nil, legacy: "2023-08-15T09:30:00.000Z", timeZone: plusThree)
        let unreadable = DateTimeEntry(displayTime: "1985~", legacy: "2023-08-15T00:00:00.000Z", timeZone: utc)

        #expect(fields(of: noDisplayTime) == ["2023", "08", "15", "12", "30", "00"])
        #expect(noDisplayTime.format == .pm)
        #expect(fields(of: unreadable) == ["2023", "08", "15", "12", "00", "00"])
        #expect(unreadable.format == .am)
    }

    @Test("With the server's edtf-date switch on, the old field fills nothing")
    func oldFieldIgnoredWhenOnlyEDTF() {
        let onlyEDTF = DateTimeEntry(displayTime: nil, legacy: "2023-08-15T00:00:00.000Z", timeZone: utc, onlyEDTF: true)
        let both = DateTimeEntry(displayTime: nil, legacy: "2023-08-15T00:00:00.000Z", timeZone: utc, onlyEDTF: false)

        #expect(onlyEDTF.isEmpty)
        #expect(both.year == "2023")
    }

    @Test("A record with no date gives an empty entry")
    func prefillEmpty() {
        let entry = DateTimeEntry(displayTime: nil, legacy: nil)

        #expect(entry.isEmpty)
        #expect(entry.edtfString == nil)
        #expect(entry.preview == nil)
        #expect(entry == DateTimeEntry())
    }

    // MARK: - Building

    @Test("Each shape builds its Level 0 string, with no offset")
    func buildsEachShape() {
        var entry = DateTimeEntry()
        entry.year = "1985"
        #expect(entry.edtfString == "1985")
        entry.month = "10"
        #expect(entry.edtfString == "1985-10")
        entry.day = "23"
        #expect(entry.edtfString == "1985-10-23")
        entry.hour = "5"
        entry.format = .pm
        #expect(entry.edtfString == "1985-10-23T17:00:00")
        entry.minute = "16"
        entry.format = .am
        #expect(entry.edtfString == "1985-10-23T05:16:00")
    }

    @Test("Short fields pad to their width; an empty field between two stays empty")
    func buildsPadded() {
        var entry = DateTimeEntry()
        entry.year = "985"
        entry.month = "5"
        entry.day = "3"
        #expect(entry.edtfString == "0985-05-03")

        entry = DateTimeEntry()
        entry.year = "1985"
        entry.day = "23"
        #expect(entry.edtfString == "1985--23", "nothing is invented for the member; the server answers")
    }

    @Test("A clock with no hour starts at the hour the format reads as zero")
    func buildsClockWithoutHour() {
        var entry = DateTimeEntry()
        entry.year = "1985"
        entry.month = "10"
        entry.day = "23"
        entry.minute = "16"
        #expect(entry.hasTime)
        #expect(entry.edtfString == "1985-10-23T00:16:00")
    }

    @Test("The hour converts at build time only", arguments: [
        ("5", DateTimeEntry.TimeFormat.am, 5),
        ("5", .pm, 17),
        ("12", .am, 0),
        ("12", .pm, 12),
        ("17", .h24, 17),
        ("0", .h24, 0)
    ])
    func hourPerFormat(hour: String, format: DateTimeEntry.TimeFormat, expected: Int) {
        var entry = DateTimeEntry()
        entry.hour = hour
        entry.format = format

        #expect(entry.hour24 == expected)
        #expect(entry.hour == hour)
    }

    @Test("A format switch keeps the digits and cycles AM, PM, 24H")
    func formatSwitchKeepsDigits() {
        var entry = DateTimeEntry()
        entry.year = "1985"
        entry.month = "10"
        entry.day = "23"
        entry.hour = "5"
        entry.format = .pm

        entry.format = entry.format.next
        #expect(entry.format == .h24)
        #expect(entry.hour == "5")
        #expect(entry.edtfString == "1985-10-23T05:00:00")
        #expect(entry.format.next == .am)
        #expect(DateTimeEntry.TimeFormat.am.next == .pm)
    }

    @Test("The pill's labels")
    func formatLabels() {
        #expect(DateTimeEntry.TimeFormat.allCases.map(\.label) == ["AM", "PM", "24H"])
    }

    // MARK: - Preview

    @Test("The preview line reads as the Info row will", arguments: [
        ("1985-10-23T17:00:00+03:00", "October 23, 1985 • 5PM +03"),
        ("1985-10-23T16:16:00", "October 23, 1985 • 4:16 PM"),
        ("1985-10", "October 1985"),
        ("1985", "1985")
    ])
    func previewLine(displayTime: String, expected: String) {
        let entry = DateTimeEntry(displayTime: displayTime, legacy: nil, timeZone: plusThree)

        #expect(entry.preview == expected)
    }

    // MARK: - Zone

    @Test("With a time and a zone the string carries the zone's offset at that date; without a time, none")
    func zoneWritesTheOffset() {
        var entry = DateTimeEntry(displayTime: "1985-10-23T17:00:00", legacy: nil, timeZone: plusThree)
        entry.timeZoneIdentifier = "Europe/Paris"
        #expect(entry.edtfString == "1985-10-23T17:00:00+01:00")

        entry.month = "07"
        #expect(entry.edtfString == "1985-07-23T17:00:00+02:00")

        entry.set(hour: 0, minute: 0, second: 0)
        entry.hour = ""
        entry.minute = ""
        entry.second = ""
        #expect(entry.edtfString == "1985-07-23")
        #expect(entry.timeSuffix == nil)
    }

    @Test("The preview ends in the zone's short name: the offset for Paris, letters for New York, nothing without a zone")
    func previewEndsInTheZone() {
        var entry = DateTimeEntry(displayTime: "1985-10-23T17:00:00", legacy: nil, timeZone: plusThree)
        entry.timeZoneIdentifier = "Europe/Paris"
        #expect(entry.preview == "October 23, 1985 • 5PM +01")

        entry.timeZoneIdentifier = "America/New_York"
        entry.month = "07"
        #expect(entry.preview == "July 23, 1985 • 5PM EDT")

        entry.timeZoneIdentifier = nil
        #expect(entry.preview == "July 23, 1985 • 5PM")
    }

    @Test("A record string's offset is kept as the stored offset and shows after the time while no zone is chosen")
    func storedOffsetIsKept() {
        let entry = DateTimeEntry(displayTime: "1985-10-23T17:00:00+03:00", legacy: nil, timeZone: plusThree)

        #expect(entry.storedOffset == "+03:00")
        #expect(entry.timeZoneIdentifier == nil)
        #expect(entry.edtfString == "1985-10-23T17:00:00", "no zone, so no offset is written")
        #expect(entry.preview == "October 23, 1985 • 5PM +03")
        #expect(DateTimeEntry(displayTime: "1985-10-23T17:00:00Z", legacy: nil, timeZone: plusThree).storedOffset == nil)
        #expect(DateTimeEntry(displayTime: "1985-10-23", legacy: nil, timeZone: plusThree).storedOffset == nil)
    }

    @Test("A record's zone comes in with its string, and a repeated hour keeps the stored offset when it fits")
    func zoneFromRecord() {
        let paris = DateTimeEntry(displayTime: "1985-10-23T17:00:00+01:00", legacy: nil, timeZoneIdentifier: "Europe/Paris", timeZone: plusThree)
        let repeated = DateTimeEntry(displayTime: "1985-09-29T02:30:00+01:00", legacy: nil, timeZoneIdentifier: "Europe/Paris", timeZone: plusThree)
        let unknown = DateTimeEntry(displayTime: "1985-10-23T17:00:00+01:00", legacy: nil, timeZoneIdentifier: "Mars/Olympus", timeZone: plusThree)

        #expect(paris.zone?.identifier == "Europe/Paris")
        #expect(paris.edtfString == "1985-10-23T17:00:00+01:00")
        #expect(repeated.edtfString == "1985-09-29T02:30:00+01:00")
        #expect(unknown.zone == nil)
        #expect(unknown.edtfString == "1985-10-23T17:00:00")
    }

    // MARK: - Pickers

    @Test("The calendar writes the day and leaves the clock")
    func calendarWritesTheDay() throws {
        var entry = DateTimeEntry(displayTime: "1985-10-23T17:00:00", legacy: nil, timeZone: plusThree)
        let picked = try #require(moment("1985-10-24T00:00:00"))

        entry.set(date: picked, timeZone: plusThree)

        #expect(fields(of: entry) == ["1985", "10", "24", "05", "00", "00"])
        #expect(entry.format == .pm)
    }

    @Test("The wheels write two digits each")
    func wheelsWriteTwoDigits() {
        var entry = DateTimeEntry()
        entry.year = "1985"

        entry.set(hour: 4, minute: 16, second: 0)

        #expect(fields(of: entry) == ["1985", "", "", "04", "16", "00"])
    }

    @Test("The picker date is the fields as a moment, else now")
    func pickerDate() throws {
        let entry = DateTimeEntry(displayTime: "1985-10-23T17:00:00", legacy: nil, timeZone: plusThree)
        var yearOnly = DateTimeEntry()
        yearOnly.year = "1985"
        let now = Date(timeIntervalSince1970: 981_185_400)

        #expect(entry.pickerDate(timeZone: plusThree, now: now) == moment("1985-10-23T17:00:00"))
        #expect(yearOnly.pickerDate(timeZone: plusThree, now: now) == moment("1985-01-01T00:00:00"))
        #expect(DateTimeEntry().pickerDate(timeZone: plusThree, now: now) == now)
    }

    @Test("Clear empties every field, resets the pill and drops the zone")
    func clearEmpties() {
        var entry = DateTimeEntry(displayTime: "1985-10-23T17:00:00+01:00", legacy: nil, timeZoneIdentifier: "Europe/Paris", timeZone: plusThree)

        entry.clear()

        #expect(entry.isEmpty)
        #expect(entry.format == .am)
        #expect(entry.edtfString == nil)
        #expect(entry.timeZoneIdentifier == nil)
        #expect(entry.storedOffset == nil)
    }

    // MARK: - Bounds

    @Test("A field past its end reads its end and a zero its first value, padded to the width", arguments: [
        (DateTimeEntry.Field.month, "22", "12"),
        (.month, "0", "01"),
        (.day, "99", "31"),
        (.day, "00", "01"),
        (.minute, "60", "59"),
        (.second, "99", "59"),
        (.year, "0000", "0001"),
        (.year, "2555", "2026")
    ])
    func clampsToBounds(field: DateTimeEntry.Field, typed: String, expected: String) throws {
        var entry = DateTimeEntry()
        entry[field] = typed

        entry.clamp(field, now: try #require(moment("2026-10-29T12:00:00")))

        #expect(entry[field] == expected)
    }

    @Test("A field inside its bounds keeps its digits as typed, and an empty one stays empty")
    func keepsWhatFits() {
        var entry = DateTimeEntry()
        entry.year = "19"
        entry.month = "9"
        entry.day = "05"
        entry.hour = ""

        entry.clamp(.year)
        entry.clamp(.month)
        entry.clamp(.day)
        entry.clamp(.hour)

        #expect([entry.year, entry.month, entry.day, entry.hour] == ["19", "9", "05", ""])
    }

    @Test("The day's end follows the month and the year's leap day, and a year or month re-checks it")
    func dayFollowsMonthAndYear() {
        var entry = DateTimeEntry()
        entry.day = "31"
        entry.month = "04"
        entry.clamp(.month)
        #expect(entry.day == "30")

        entry.day = "29"
        entry.month = "02"
        entry.clamp(.day)
        #expect(entry.day == "29", "no year yet, so the leap day stays")

        entry.year = "2023"
        entry.clamp(.year)
        #expect(entry.day == "28")

        entry.year = "2024"
        entry.day = "29"
        entry.clamp(.day)
        #expect(entry.day == "29")
    }

    @Test("The hour's bounds follow the pill: 1 to 12 on AM and PM, 0 to 23 on 24H", arguments: [
        ("13", DateTimeEntry.TimeFormat.am, "12"),
        ("0", .pm, "01"),
        ("12", .pm, "12"),
        ("24", .h24, "23"),
        ("00", .h24, "00")
    ])
    func hourBoundsPerFormat(typed: String, format: DateTimeEntry.TimeFormat, expected: String) {
        var entry = DateTimeEntry()
        entry.format = format
        entry.hour = typed

        entry.clamp(.hour)

        #expect(entry.hour == expected)
    }

    @Test("The year runs from 1 to this year: 1850 and this year stay, a later year reads this year")
    func yearRunsToThisYear() throws {
        var entry = DateTimeEntry()
        let now = try #require(moment("2026-10-29T12:00:00"))

        #expect(entry.bounds(of: .year, now: now) == 1...2026)

        entry.year = "1850"
        entry.clamp(.year, now: now)
        #expect(entry.year == "1850")
        entry.year = "2026"
        entry.clamp(.year, now: now)
        #expect(entry.year == "2026")
        entry.year = "2027"
        entry.clamp(.year, now: now)
        #expect(entry.year == "2026")
    }

    // MARK: - Helpers

    private func fields(of entry: DateTimeEntry) -> [String] {
        [entry.year, entry.month, entry.day, entry.hour, entry.minute, entry.second]
    }

    /// A clock time three hours east of UTC as a moment.
    private func moment(_ text: String) -> Date? {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = plusThree
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        return formatter.date(from: text)
    }
}
