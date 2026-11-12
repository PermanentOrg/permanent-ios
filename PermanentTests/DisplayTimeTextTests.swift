//
//  DisplayTimeTextTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import Foundation
import Testing
@testable import Permanent

/// What the screens show for each shape `displayTime` can hold: the Info row's label words and lines, and the
/// date under a file in a list.
struct DisplayTimeTextTests {
    private let utc = TimeZone(secondsFromGMT: 0) ?? .current

    // MARK: - Info row

    @Test("One date shows on one line, with its qualifier words after the label", arguments: [
        ("1985-10-23", nil, "October 23, 1985"),
        ("1985-10-23T16:16:00", nil, "October 23, 1985 • 4:16 PM"),
        ("1985-10-23~", "Approximate", "October 23, 1985"),
        ("1985?", "Uncertain", "1985"),
        ("1985-10%", "Approximate • Uncertain", "October 1985"),
        ("XXXX-XX-XX", nil, "Unknown date and time")
    ])
    func oneDate(displayTime: String, detail: String?, text: String) throws {
        let row = try #require(DisplayTimeText(displayTime: displayTime, legacy: "2023-08-15T00:00:00.000Z", timeZone: utc))

        #expect(row.labelDetail == detail)
        #expect(row.lines == [DisplayTimeText.Line(caption: nil, text: text)])
    }

    @Test("A range shows a From and a To line; the words go on the label only when both sides share them", arguments: [
        ("1985-10-23T16:16:00/1985-11-23", nil, "October 23, 1985 • 4:16 PM", "November 23, 1985"),
        ("1985-10-23~/1985-11-23", nil, "~ October 23, 1985", "November 23, 1985"),
        ("1985-10-23~/1985-11-23?", nil, "~ October 23, 1985", "? November 23, 1985"),
        ("1985-10-23~/1985-11-23~", "Approximate", "October 23, 1985", "November 23, 1985"),
        ("1985%/1990%", "Approximate • Uncertain", "1985", "1990"),
        ("1985-10-23/", nil, "October 23, 1985", "Unknown"),
        ("/1985-11-23?", "Uncertain", "Unknown", "November 23, 1985")
    ])
    func range(displayTime: String, detail: String?, from: String, to: String) throws {
        let row = try #require(DisplayTimeText(displayTime: displayTime, legacy: nil, timeZone: utc))

        #expect(row.labelDetail == detail)
        #expect(row.lines == [DisplayTimeText.Line(caption: "From", text: from), DisplayTimeText.Line(caption: "To", text: to)])
    }

    @Test("An empty start reads Before, an empty end After, on one line", arguments: [
        ("../1985-11-23", nil, "Before November 23, 1985"),
        ("1985-10-23/..", nil, "After October 23, 1985"),
        ("../1985~", "Approximate", "Before 1985"),
        ("1985-10-23T17:00:00/..", nil, "After October 23, 1985 • 5PM")
    ])
    func openEnd(displayTime: String, detail: String?, text: String) throws {
        let row = try #require(DisplayTimeText(displayTime: displayTime, legacy: nil, timeZone: utc))

        #expect(row.labelDetail == detail)
        #expect(row.lines == [DisplayTimeText.Line(caption: nil, text: text)])
    }

    @Test("A range with no date on either side reads as unknown", arguments: ["/", "../..", "/..", "../"])
    func noWrittenSide(displayTime: String) throws {
        let row = try #require(DisplayTimeText(displayTime: displayTime, legacy: "2023-08-15T00:00:00.000Z", timeZone: utc))

        #expect(row.labelDetail == nil)
        #expect(row.lines == [DisplayTimeText.Line(caption: nil, text: "Unknown date and time")])
    }

    @Test("Each side's clock ends in the record's zone")
    func zoneFollowsEachClock() throws {
        let row = try #require(DisplayTimeText(
            displayTime: "1985-07-23T17:00:00-04:00/1985-07-24", legacy: nil, timeZoneIdentifier: "America/New_York", timeZone: utc
        ))

        #expect(row.lines.map(\.text) == ["July 23, 1985 • 5PM EDT", "July 24, 1985"])
    }

    @Test("A string that does not read shows the old field; nothing readable gives no row")
    func oldField() throws {
        let legacy = try #require(DisplayTimeText(displayTime: nil, legacy: "2019-06-22T13:05:00.000Z", timeZone: utc, onlyEDTF: false))
        let unreadable = try #require(DisplayTimeText(displayTime: "198X", legacy: "2019-06-22T13:05:00.000Z", timeZone: utc, onlyEDTF: false))

        #expect(legacy.lines == [DisplayTimeText.Line(caption: nil, text: "June 22, 2019 • 1:05 PM")])
        #expect(unreadable == legacy)
        #expect(DisplayTimeText(displayTime: nil, legacy: nil) == nil)
        #expect(DisplayTimeText(displayTime: nil, legacy: "2019-06-22T13:05:00.000Z", onlyEDTF: true) == nil)
    }

    @Test("The row's one-string value is each line after its caption")
    func oneStringValue() throws {
        let range = try #require(DisplayTimeText(displayTime: "1985-10-23~/1985-11-23~", legacy: nil, timeZone: utc))
        let single = try #require(DisplayTimeText(displayTime: "1985-10-23", legacy: nil, timeZone: utc))

        #expect(range.text == "From October 23, 1985, To November 23, 1985")
        #expect(single.text == "October 23, 1985")
    }

    // MARK: - List date

    @Test("A list shows the first written side's date as written", arguments: [
        ("1985-10-23~", "1985-10-23"),
        ("1985?", "1985"),
        ("1985-10-23~/1985-11-23", "1985-10-23"),
        ("../1985-11", "1985-11"),
        ("/2000", "2000"),
        ("1985-10-23T17:00:00+01:00/1985-10-24", "1985-10-23")
    ])
    func listDate(displayTime: String, expected: String) {
        #expect(DateUtils.listDate(displayTime: displayTime, legacy: "2023-08-15T00:00:00.000Z") == expected)
    }

    @Test("A value with no written side shows no date, not the upload date", arguments: ["XXXX-XX-XX", "/", "../.."])
    func listDateWithoutAWrittenSide(displayTime: String) {
        #expect(DateUtils.listDate(displayTime: displayTime, legacy: "2023-08-15T00:00:00.000Z") == "-")
        #expect(DateUtils.date(fromDisplayTime: displayTime) == nil)
        #expect(!DateUtils.showsLegacyDate(displayTimes: [displayTime]))
    }

    // MARK: - Shape

    @Test("A symbol after a clock, a third side or a lone open end does not read", arguments: [
        "1985-10-23T17:00:00+01:00~", "1985/1990/1995", "..", "", "1985~~", "~", "XXXX-XX"
    ])
    func refusedShapes(displayTime: String) {
        #expect(DisplayTimeValue(displayTime) == nil)
    }
}
