//
//  DateTimeRangeEntryTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The full sheet's entry: the bytes each toggle combination saves and that edtf.js accepts them, what Unknown
/// and a qualifier keep aside, each stored shape read back, and the line under the title.
struct DateTimeRangeEntryTests {
    /// What one side of the sheet can be, with the bytes it adds to the saved string.
    enum SideCase: CaseIterable {
        case plain, approximate, uncertain, both, unknown, empty

        var text: String {
            switch self {
            case .plain: return "1985-10-23"
            case .approximate: return "1985-10-23~"
            case .uncertain: return "1985-10-23?"
            case .both: return "1985-10-23%"
            case .unknown: return ""
            case .empty: return ".."
            }
        }

        var qualifiers: [DateQualifiers] {
            switch self {
            case .plain, .empty: return []
            case .approximate: return [.approximate]
            case .uncertain: return [.uncertain]
            case .both: return [.approximate, .uncertain]
            case .unknown: return [.unknown]
            }
        }
    }

    private let plusThree = TimeZone(secondsFromGMT: 3 * 3600) ?? .current
    private let edtf = JavaScriptCoreEDTF.shared

    // MARK: - Bytes

    @Test("One date writes its symbol after the date, and Unknown writes all X", arguments: [
        (SideCase.plain, "1985-10-23"),
        (.approximate, "1985-10-23~"),
        (.uncertain, "1985-10-23?"),
        (.both, "1985-10-23%"),
        (.unknown, "XXXX-XX-XX")
    ])
    func oneDatePerToggle(side: SideCase, expected: String) throws {
        var range = DateTimeRangeEntry()
        fill(&range, .start, as: side)

        #expect(range.edtfString == expected)
        #expect(try edtf.validated(try #require(range.gateString)) == expected)
    }

    @Test("A year or a month alone takes a symbol too", arguments: [("1985", "1985~"), ("1985-10", "1985-10~")])
    func coarseDateTakesASymbol(displayTime: String, expected: String) throws {
        var range = DateTimeRangeEntry(displayTime: displayTime, legacy: nil)
        range.set(.approximate, on: true)

        #expect(range.edtfString == expected)
        #expect(try edtf.validated(try #require(range.gateString)) == expected)
    }

    @Test("Every pair of sides writes web's bytes, and edtf.js accepts each", arguments: SideCase.allCases, SideCase.allCases)
    func rangePerTogglePair(start: SideCase, end: SideCase) throws {
        var range = DateTimeRangeEntry()
        range.setRange(on: true)
        fill(&range, .start, as: start)
        fill(&range, .end, as: end, day: "24")

        guard start != .empty || end != .empty else {
            #expect(range.edtfString == nil, "a range with nothing on either side is a clear")
            return
        }
        let expected = start.text + "/" + end.text.replacingOccurrences(of: "-23", with: "-24")
        #expect(range.edtfString == expected)
        #expect(try edtf.validated(try #require(range.gateString)) == expected)
    }

    @Test("'Sometime before 2000' is an empty start and a 2000 end")
    func emptyStartBeforeAYear() {
        var range = DateTimeRangeEntry()
        range.setRange(on: true)
        range.end?.year = "2000"

        #expect(range.edtfString == "../2000")
        #expect(range.preview == "— 2000")
    }

    // MARK: - Save gate

    @Test("A Stage 1 time with no zone saves as typed and still passes the gate")
    func zonelessTimePassesTheGate() throws {
        let range = DateTimeRangeEntry(displayTime: "1985-10-23T17:00:00", legacy: nil, timeZone: plusThree)

        #expect(range.edtfString == "1985-10-23T17:00:00")
        #expect(range.gateString == "1985-10-23T17:00:00Z")
        #expect(throws: Never.self) { try edtf.validated(try #require(range.gateString)) }
    }

    @Test("The gate reads a zone's offset as Z and the saved bytes keep the offset")
    func zonedTimeGatesAsZ() throws {
        let range = DateTimeRangeEntry(
            displayTime: "1985-10-23T17:00:00+01:00", legacy: nil, timeZoneIdentifier: "Europe/Paris", timeZone: plusThree
        )

        #expect(range.edtfString == "1985-10-23T17:00:00+01:00")
        #expect(range.gateString == "1985-10-23T17:00:00Z")
    }

    @Test("A timed start meets a dated, an open or an unknown end", arguments: [
        ("1985-10-23T17:00:00+01:00/1985-10-24", "1985-10-23T17:00:00Z/1985-10-24"),
        ("1985-10-23T17:00:00+01:00/..", "1985-10-23T17:00:00Z/.."),
        ("1985-10-23T17:00:00+01:00/", "1985-10-23T17:00:00Z/"),
        ("../1985-10-23T17:00:00+01:00", "../1985-10-23T17:00:00Z"),
        ("1985-10-23T17:00:00+01:00/1985-10-24T09:30:00+01:00", "1985-10-23T17:00:00Z/1985-10-24T09:30:00Z")
    ])
    func timedSidePassesTheGate(displayTime: String, gate: String) throws {
        let range = DateTimeRangeEntry(displayTime: displayTime, legacy: nil, timeZoneIdentifier: "Europe/Paris", timeZone: plusThree)

        #expect(range.edtfString == displayTime)
        #expect(range.gateString == gate)
        #expect(throws: Never.self) { try edtf.validated(gate) }
    }

    @Test("An end at or before the start is refused as an upper bound", arguments: ["1985-10-23/1985-10-23", "1985-10-23/1985-10-22", "2000/1985"])
    func endNotAfterStartIsRefused(displayTime: String) throws {
        let range = DateTimeRangeEntry(displayTime: displayTime, legacy: nil)
        let gate = try #require(range.gateString)

        let error = #expect(throws: EDTFError.self) { try edtf.validated(gate) }
        guard case .rejected(let reason)? = error else {
            Issue.record("expected a rejection, got \(String(describing: error))")
            return
        }
        #expect(reason.contains("upper bound"))
    }

    // MARK: - Unknown

    @Test("Unknown empties the side, keeps what it held and the zone, and gives it back when switched off")
    func unknownKeepsAndRestores() {
        var range = DateTimeRangeEntry(
            displayTime: "1985-10-23T17:00:00+01:00", legacy: nil, timeZoneIdentifier: "Europe/Paris", timeZone: plusThree
        )
        let typed = range.start

        range.set(.unknown, on: true)

        #expect(range.start.isEmpty)
        #expect(range.start.qualifiers == .unknown)
        #expect(range.start.timeZoneIdentifier == "Europe/Paris")
        #expect(range.edtfString == "XXXX-XX-XX")
        #expect(range.preview == "Unknown")
        #expect(!range.isEmpty, "an unknown date is a value, not a clear")

        range.set(.unknown, on: false)

        #expect(range.start == typed)
        #expect(range.edtfString == "1985-10-23T17:00:00+01:00")
    }

    @Test("Unknown puts Approximate and Uncertain out of reach and brings them back with the date")
    func unknownKeepsTheOtherToggles() {
        var range = DateTimeRangeEntry(displayTime: "1985-10-23~", legacy: nil)

        range.set(.unknown, on: true)
        range.set(.uncertain, on: true)

        #expect(range.start.qualifiers == .unknown)

        range.set(.unknown, on: false)

        #expect(range.start.qualifiers == .approximate)
        #expect(range.edtfString == "1985-10-23~")
    }

    @Test("A record saved as unknown opens with Unknown on and comes back empty")
    func unknownRecordOpensEmpty() {
        var range = DateTimeRangeEntry(displayTime: "XXXX-XX-XX", legacy: "2023-08-15T00:00:00.000Z")

        #expect(range.start.qualifiers == .unknown)
        #expect(range.start.isEmpty)
        #expect(range.opensFull)

        range.set(.unknown, on: false)

        #expect(range.isEmpty)
        #expect(range.edtfString == nil)
    }

    @Test("Each side of a range goes unknown on its own")
    func unknownPerSide() {
        var range = DateTimeRangeEntry(displayTime: "1985-10-23/1985-11-23", legacy: nil)

        range.set(.unknown, on: true, side: .end)
        #expect(range.edtfString == "1985-10-23/")
        #expect(range.preview == "Oct. 23, 1985 — Unknown")

        range.set(.unknown, on: false, side: .end)
        range.set(.unknown, on: true, side: .start)
        #expect(range.edtfString == "/1985-11-23")

        range.set(.unknown, on: false, side: .start)
        #expect(range.edtfString == "1985-10-23/1985-11-23")
    }

    // MARK: - A symbol and a clock

    @Test("Approximate or Uncertain keeps the clock aside and gives it back when both are off")
    func symbolKeepsTheClockAside() {
        var range = DateTimeRangeEntry(
            displayTime: "1985-10-23T17:00:00+01:00", legacy: nil, timeZoneIdentifier: "Europe/Paris", timeZone: plusThree
        )

        range.set(.approximate, on: true)
        #expect(!range.start.hasTime)
        #expect(range.edtfString == "1985-10-23~")
        #expect(range.preview == "~ October 23, 1985")

        range.set(.uncertain, on: true)
        #expect(range.edtfString == "1985-10-23%")
        #expect(range.preview == "% October 23, 1985")

        range.set(.approximate, on: false)
        #expect(!range.start.hasTime, "Uncertain still holds the clock aside")
        #expect(range.edtfString == "1985-10-23?")

        range.set(.uncertain, on: false)
        #expect(range.start.format == .pm)
        #expect(range.edtfString == "1985-10-23T17:00:00+01:00")
    }

    @Test("A symbol on one side leaves the other side's clock alone")
    func symbolPerSide() {
        var range = DateTimeRangeEntry(
            displayTime: "1985-10-23T17:00:00+01:00/1985-10-24T09:30:00+01:00", legacy: nil,
            timeZoneIdentifier: "Europe/Paris", timeZone: plusThree
        )

        range.set(.approximate, on: true, side: .start)

        #expect(range.edtfString == "1985-10-23~/1985-10-24T09:30:00+01:00")
        #expect(range.end?.qualifiers.isEmpty == true)
    }

    // MARK: - Range switch, zone, clear

    @Test("The range switch adds an empty To side with the start's zone, and a side switched off comes back")
    func rangeSwitch() {
        var range = DateTimeRangeEntry(
            displayTime: "1985-10-23T17:00:00+01:00", legacy: nil, timeZoneIdentifier: "Europe/Paris", timeZone: plusThree
        )
        #expect(!range.isRange)

        range.setRange(on: true)
        #expect(range.end?.isEmpty == true)
        #expect(range.end?.timeZoneIdentifier == "Europe/Paris")
        #expect(range.edtfString == "1985-10-23T17:00:00+01:00/..")

        range.end?.year = "1990"
        range.setRange(on: false)
        #expect(range.edtfString == "1985-10-23T17:00:00+01:00")

        range.setRange(on: true)
        #expect(range.end?.year == "1990")
    }

    @Test("Both sides share one zone, set from either")
    func oneZoneForBothSides() {
        var range = DateTimeRangeEntry(displayTime: "1985-10-23T17:00:00/1985-10-24T09:30:00", legacy: nil, timeZone: plusThree)

        range.start.timeZoneIdentifier = "Europe/Paris"
        #expect(range.end?.timeZoneIdentifier == "Europe/Paris")
        #expect(range.edtfString == "1985-10-23T17:00:00+01:00/1985-10-24T09:30:00+01:00")

        range.end?.timeZoneIdentifier = "America/New_York"
        #expect(range.start.timeZoneIdentifier == "America/New_York")

        range.end?.timeZoneIdentifier = nil
        #expect(range.start.timeZoneIdentifier == nil)
        #expect(range.edtfString == "1985-10-23T17:00:00/1985-10-24T09:30:00")
    }

    @Test("Clear empties both sides, switches every toggle and the range off and drops the zone")
    func clearEmptiesEverything() {
        var range = DateTimeRangeEntry(
            displayTime: "1985-10-23~/1985-10-24T09:30:00+01:00", legacy: nil, timeZoneIdentifier: "Europe/Paris", timeZone: plusThree
        )

        range.clear()

        #expect(range == DateTimeRangeEntry())
        #expect(range.isEmpty && !range.isRange && !range.opensFull)
        #expect(range.edtfString == nil && range.gateString == nil && range.preview == nil)
        #expect(range.start.timeZoneIdentifier == nil)
    }

    // MARK: - Reading back

    @Test("Every stored shape reads into the sides and writes the same bytes again", arguments: [
        "1985", "1985-10", "1985-10-23", "1985-10-23T17:00:00",
        "1985~", "1985-10?", "1985-10-23%", "XXXX-XX-XX",
        "1985-10-23/1985-11-23", "1985-10-23~/1985-11-23", "1985~/2000?", "1985-10-23%/1985-11-23%",
        "../1985-11-23", "1985-10-23/..", "1985-10-23/", "/2000", "/", "/..", "../",
        "1985-10-23T17:00:00/1985-10-24"
    ])
    func shapeReadsBack(displayTime: String) {
        let range = DateTimeRangeEntry(displayTime: displayTime, legacy: "2023-08-15T00:00:00.000Z", timeZone: plusThree)

        #expect(range.edtfString == displayTime)
        #expect(range.isRange == displayTime.contains("/"))
    }

    @Test("A range reads each side's fields and qualifiers")
    func rangeReadsBothSides() {
        let range = DateTimeRangeEntry(displayTime: "1985-10-23~/1990-05?", legacy: nil, timeZone: plusThree)

        #expect([range.start.year, range.start.month, range.start.day] == ["1985", "10", "23"])
        #expect(range.start.qualifiers == .approximate)
        #expect([range.end?.year, range.end?.month, range.end?.day] == ["1990", "05", ""])
        #expect(range.end?.qualifiers == .uncertain)
    }

    @Test("The sheet opens full for a qualifier or a second side, simple otherwise", arguments: [
        ("1985-10-23~", true), ("XXXX-XX-XX", true), ("1985/1990", true), ("../1990", true),
        ("1985-10-23", false), ("1985-10-23T17:00:00+01:00", false)
    ])
    func opensFull(displayTime: String, expected: Bool) {
        #expect(DateTimeRangeEntry(displayTime: displayTime, legacy: nil).opensFull == expected)
    }

    @Test("A string that does not read falls back to the old field as one date, and no date gives an empty entry")
    func unreadableFallsBack() {
        let unreadable = DateTimeRangeEntry(displayTime: "198X", legacy: "2023-08-15T09:30:00.000Z", timeZone: plusThree)
        let none = DateTimeRangeEntry(displayTime: nil, legacy: nil)

        #expect([unreadable.start.year, unreadable.start.month, unreadable.start.day] == ["2023", "08", "15"])
        #expect(!unreadable.isRange && !unreadable.opensFull)
        #expect(none == DateTimeRangeEntry())
        #expect(none.isEmpty)
    }

    @Test("A range open on both ends holds nothing, so a save clears it")
    func openOnBothEndsIsEmpty() {
        let range = DateTimeRangeEntry(displayTime: "../..", legacy: nil)

        #expect(range.isRange)
        #expect(range.isEmpty)
        #expect(range.edtfString == nil)
    }

    // MARK: - Preview

    @Test("The line under the title puts the symbol first, a full month alone and a short one in a range", arguments: [
        ("1985-10-23", "October 23, 1985"),
        ("1985-10-23~", "~ October 23, 1985"),
        ("1985-10?", "? October 1985"),
        ("1985-10-23%", "% October 23, 1985"),
        ("XXXX-XX-XX", "Unknown"),
        ("1985-10-23/1985-11-23", "Oct. 23, 1985 — Nov. 23, 1985"),
        ("1985-10-23~/1985-11-23", "~ Oct. 23, 1985 — Nov. 23, 1985"),
        ("1985/1990?", "1985 — ? 1990"),
        ("1985-10/1990-11", "Oct. 1985 — Nov. 1990"),
        ("../1985-11-23", "— Nov. 23, 1985"),
        ("1985-10-23~/..", "~ Oct. 23, 1985 —"),
        ("1985-10-23/", "Oct. 23, 1985 — Unknown"),
        ("/", "Unknown — Unknown"),
        ("1985-10-23T17:00:00/1985-10-24", "Oct. 23, 1985 • 5PM — Oct. 24, 1985")
    ])
    func previewLine(displayTime: String, expected: String) {
        #expect(DateTimeRangeEntry(displayTime: displayTime, legacy: nil, timeZone: plusThree).preview == expected)
    }

    @Test("A range's clock ends in the zone's short name")
    func previewEndsInTheZone() {
        let range = DateTimeRangeEntry(
            displayTime: "1985-07-23T17:00:00-04:00/1985-07-24", legacy: nil, timeZoneIdentifier: "America/New_York", timeZone: plusThree
        )

        #expect(range.preview == "Jul. 23, 1985 • 5PM EDT — Jul. 24, 1985")
    }

    // MARK: - Helpers

    /// Types 1985-10 and the day into a side, then switches its toggles on.
    private func fill(_ range: inout DateTimeRangeEntry, _ side: DateTimeRangeEntry.Side, as sideCase: SideCase, day: String = "23") {
        var entry = DateTimeEntry()
        if sideCase != .empty {
            entry.year = "1985"
            entry.month = "10"
            entry.day = day
        }
        switch side {
        case .start: range.start = entry
        case .end: range.end = entry
        }
        for qualifier in sideCase.qualifiers {
            range.set(qualifier, on: true, side: side)
        }
    }
}
