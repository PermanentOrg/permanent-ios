//
//  DisplayTimeTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 16.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The `displayTime` helpers in `DateUtils`: which EDTF Level 0 values read, what the list and pickers
/// show for them, and the string a date save sends to Stela V2.
struct DisplayTimeTests {
    private let bucharest = TimeZone(identifier: "Europe/Bucharest") ?? .current

    // MARK: - Reading

    @Test(
        "A Level 0 value gives the list its date as written",
        arguments: [
            ("1985", "1985"),
            ("1985-10", "1985-10"),
            ("1985-10-23", "1985-10-23"),
            ("2026-07-15T12:45:00", "2026-07-15"),
            ("2026-07-15T12:45:00Z", "2026-07-15"),
            ("2026-07-15T23:45:00+03:00", "2026-07-15"),
            ("2026-07-15T01:15:00-05:30", "2026-07-15"),
            ("1985-10-23T23:30:00.000Z", "1985-10-23"),
            ("1990-10-05T16:15:38.000Z", "1990-10-05"),
            ("2026-07-15T12:45:00.5+03:00", "2026-07-15"),
            ("2026-07-15T12:45:00.123", "2026-07-15"),
            ("1964/2008", "1964"),
            ("2004-02-01/2005-02-08", "2004-02-01")
        ]
    )
    func level0ValueReads(displayTime: String, listDate: String) {
        #expect(DateUtils.listDate(displayTime: displayTime, legacy: "1999-01-01T00:00:00.000Z") == listDate)
        #expect(!DateUtils.showsLegacyDate(displayTimes: [displayTime]))
    }

    @Test(
        "A value above Level 0, or a broken one, falls back to the old field",
        arguments: [
            "", "1985~", "1985?", "198X", "1985-13", "1985-02-30", "85-10-23", "1985-10-23T25:00:00",
            "1985-10-23T12:45", "1985-10-23T12:45:00+3", "1985-10T12:45:00",
            "1985-10-23T12:45:00.", "1985-10-23T12:45:00.5.5", "1985-10-23T12:45:00.x", "1985-10-23T12:45.5",
            "../1985", "1985/..", "1985/1990/1995", "2004-02-01T10:00:00/2005", "-1985"
        ]
    )
    func otherValueFallsBack(displayTime: String) {
        #expect(DateUtils.listDate(displayTime: displayTime, legacy: "2023-08-15T00:00:00.000Z") == "2023-08-15")
        #expect(DateUtils.date(fromDisplayTime: displayTime) == nil)
        #expect(DateUtils.showsLegacyDate(displayTimes: [displayTime]))
    }

    @Test("With no displayTime the list keeps today's old-field text")
    func noDisplayTimeKeepsOldText() {
        #expect(DateUtils.listDate(displayTime: nil, legacy: "2023-08-15 12:34:56+00") == "2023-08-15")
        #expect(DateUtils.listDate(displayTime: nil, legacy: nil) == "-")
    }

    // MARK: - Pickers

    @Test(
        "A picker date keeps the clock time as written, with or without an offset",
        arguments: [
            "2026-07-15T12:45:00", "2026-07-15T12:45:00+05:00", "2026-07-15T12:45:00-08:00",
            "2026-07-15T12:45:00.250", "2026-07-15T12:45:00.000+05:00"
        ]
    )
    func pickerKeepsWrittenClock(displayTime: String) throws {
        let date = try #require(DateUtils.date(fromDisplayTime: displayTime, timeZone: bucharest))
        #expect(clock(of: date) == [2026, 7, 15, 12, 45, 0])
    }

    @Test(
        "A Z time is the UTC moment the old web editor wrote, read like the old field",
        arguments: ["1985-10-23T23:30:00.000Z", "1985-10-23T23:30:00Z"]
    )
    func zuluTimeIsUTCMoment(displayTime: String) throws {
        let date = try #require(DateUtils.date(fromDisplayTime: displayTime, timeZone: bucharest))
        #expect(date == DateUtils.date(fromISO: "1985-10-23T23:30:00.000Z"))
        let centralStandard = try #require(TimeZone(secondsFromGMT: -6 * 3600))
        #expect(clock(of: date, in: centralStandard) == [1985, 10, 23, 17, 30, 0])
    }

    @Test("A year or a month alone starts the picker on its first day")
    func reducedPrecisionStartsOnFirstDay() throws {
        let year = try #require(DateUtils.date(fromDisplayTime: "1985", timeZone: bucharest))
        let month = try #require(DateUtils.date(fromDisplayTime: "1985-10", timeZone: bucharest))
        #expect(clock(of: year) == [1985, 1, 1, 0, 0, 0])
        #expect(clock(of: month) == [1985, 10, 1, 0, 0, 0])
    }

    // MARK: - Writing

    @Test("A save writes the picked clock time with the phone's offset today, as web does")
    func writeUsesTodaysOffset() throws {
        let picked = try date(DateComponents(year: 2001, month: 2, day: 3, hour: 9, minute: 30), in: bucharest)
        let octoberToday = try date(DateComponents(year: 2026, month: 10, day: 16, hour: 12), in: bucharest)
        #expect(DateUtils.displayTime(from: picked, timeZone: bucharest, now: octoberToday) == "2001-02-03T09:30:00+03:00")
    }

    @Test(
        "The offset is signed and keeps its minutes",
        arguments: [("UTC", "+00:00"), ("America/New_York", "-04:00"), ("Asia/Kolkata", "+05:30"), ("America/St_Johns", "-02:30")]
    )
    func offsetFormat(zoneIdentifier: String, offset: String) throws {
        let zone = try #require(TimeZone(identifier: zoneIdentifier))
        let picked = try date(DateComponents(year: 1999, month: 1, day: 1, hour: 8), in: zone)
        let octoberToday = try date(DateComponents(year: 2026, month: 10, day: 16, hour: 12), in: zone)
        #expect(DateUtils.displayTime(from: picked, timeZone: zone, now: octoberToday) == "1999-01-01T08:00:00" + offset)
    }

    @Test("What a save writes reads back as the same clock time")
    func writeThenReadKeepsClock() throws {
        let picked = try date(DateComponents(year: 2001, month: 2, day: 3, hour: 9, minute: 30), in: bucharest)
        let written = DateUtils.displayTime(from: picked, timeZone: bucharest)
        #expect(DateUtils.date(fromDisplayTime: written, timeZone: bucharest) == picked)
        #expect(DateUtils.listDate(displayTime: written, legacy: nil) == "2001-02-03")
    }

    @Test("The PATCH fields carry displayTime only")
    func patchFieldsCarryDisplayTimeOnly() throws {
        let fields = DateUtils.displayTimeFields(for: Date())
        #expect(Array(fields.keys) == ["displayTime"])
        let value = try #require(fields["displayTime"] as? String)
        #expect(DateUtils.date(fromDisplayTime: value) != nil)
    }

    // MARK: - Failsafe check

    @Test("The old field is shown only when no record being saved has a displayTime that reads")
    func legacyShownOnlyWithoutReadableDisplayTime() {
        #expect(DateUtils.showsLegacyDate(displayTimes: [nil, nil]))
        #expect(DateUtils.showsLegacyDate(displayTimes: [nil, "1985~"]))
        #expect(!DateUtils.showsLegacyDate(displayTimes: [nil, "1985"]))
    }

    // MARK: - File information text

    @Test(
        "File information shows only the parts a date has",
        arguments: [("1985", "1985"), ("1985-10", "Oct. 1985"), ("1985-10-23", "Oct. 23, 1985")]
    )
    func fileInformationText(listDate: String, text: String) {
        #expect(DateUtils.displayDate(from: listDate) == text)
    }

    // MARK: - Helpers

    private func clock(of date: Date, in zone: TimeZone? = nil) -> [Int?] {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone ?? bucharest
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        return [parts.year, parts.month, parts.day, parts.hour, parts.minute, parts.second]
    }

    private func date(_ parts: DateComponents, in zone: TimeZone) throws -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = zone
        return try #require(calendar.date(from: parts))
    }
}
