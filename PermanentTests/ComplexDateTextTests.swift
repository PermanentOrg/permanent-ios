//
//  ComplexDateTextTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 18.11.2026.
//

import Foundation
import Testing
@testable import Permanent

/// How each complex `displayTime` reads in the list line, the Info caption and the Info lines.
struct ComplexDateTextTests {
    private let utc = TimeZone(secondsFromGMT: 0) ?? .current
    private let bucharest = TimeZone(identifier: "Europe/Bucharest") ?? .current

    @Test("The list line reads as the design writes it", arguments: [
        ("1985~", "c. 1985"),
        ("1980-03?", "March 1980 ?"),
        ("1985%", "c. 1985 ?"),
        ("1980-09-30T00:56:00/..", "After Sept. 30, 1980  •  12:56 AM"),
        ("1980-09-30/", "After Sept. 30, 1980"),
        ("../2025-11-12", "Before Nov. 12, 2025"),
        ("/2025-11-12", "Before Nov. 12, 2025"),
        ("../..", "Unknown"),
        ("XXXX", "Unknown"),
        ("198X", "1980s"),
        ("19XX", "1900s"),
        ("1985-XX", "1985"),
        ("1985-XX-XX", "1985"),
        ("1985-06-XX", "June 1985"),
        ("1985/1990", "1985 — 1990"),
        ("1985-06/1990", "June 1985 — 1990"),
        ("2001-09-24/2015-07-21", "Sept. 24, 2001 — Jul. 21, 2015"),
        ("2001-09-24/2001-09-30", "Sept. 24 — 30, 2001"),
        ("2012-09-24/2012-11-15", "Sept. 24 — Nov. 15, 2012"),
        ("2001-09-24T09:45:00/2001-09-24T16:00:00", "Sept. 24, 2001  •  9:45 AM — 4:00 PM"),
        ("1985~/1990?", "c. 1985 — 1990 ?"),
        ("1990-05-01/1990-05-09", "May 1 — 9, 1990"),
        ("1990-04-28/1990-05-09", "Apr. 28 — May 9, 1990"),
        ("1990-05-01/..", "After May 1, 1990")
    ])
    func listLine(displayTime: String, expected: String) {
        #expect(ComplexDateText(displayTime, timeZone: utc).listText == expected)
    }

    @Test("A value that does not read shows Unknown, never a wrong date", arguments: [
        "1985-13", "1985-02-30", "85-10-23", "1985/1990/1995", "-1985", "1985-21", "1X8X", "1985-10-23T25:00:00/.."
    ])
    func unreadableIsUnknown(displayTime: String) {
        let text = ComplexDateText(displayTime, timeZone: utc)
        #expect(text.listText == "Unknown")
        #expect(text.infoLines == [.init(label: nil, text: "Unknown")])
    }

    @Test("The lighter words are muted, the date is not")
    func mutedSegments() {
        let after = ComplexDateText("1980-09-30T00:56:00/..", timeZone: utc).listSegments
        #expect(after.filter(\.isMuted).map(\.text) == ["After ", " AM"])
        #expect(after.filter { !$0.isMuted }.map(\.text) == ["Sept. 30, 1980", "  •  12:56"])

        let circa = ComplexDateText("1985%", timeZone: utc).listSegments
        #expect(circa.filter(\.isMuted).map(\.text) == ["c. ", " ?"])
        #expect(circa.filter { !$0.isMuted }.map(\.text) == ["1985"])
    }

    @Test("A Z time is shown on the phone's clock")
    func zuluTimeOnPhoneClock() {
        #expect(ComplexDateText("2001-09-24T23:30:00Z/..", timeZone: bucharest).listText == "After Sept. 25, 2001  •  2:30 AM")
    }

    @Test("Info gets the marks as a caption and a range as From and To lines")
    func infoLines() {
        let range = ComplexDateText("1985-10-23T16:16:00~/1985-11-23?", timeZone: utc, zoneSuffix: { _ in "CEST" })
        #expect(range.qualifiers == ["Approximate", "Uncertain"])
        #expect(range.infoLines == [
            .init(label: "From", text: "October 23, 1985  •  4:16 PM CEST"),
            .init(label: "To", text: "November 23, 1985")
        ])
        #expect(range.infoText == "From October 23, 1985  •  4:16 PM CEST, To November 23, 1985")

        let single = ComplexDateText("1980-03?", timeZone: utc)
        #expect(single.qualifiers == ["Uncertain"])
        #expect(single.infoLines == [.init(label: nil, text: "March 1980")])

        let openEnd = ComplexDateText("1980-09-30/..", timeZone: utc)
        #expect(openEnd.qualifiers.isEmpty)
        #expect(openEnd.infoLines == [.init(label: nil, text: "After September 30, 1980")])
        #expect(ComplexDateText("../2025-11-12", timeZone: utc).infoLines == [.init(label: nil, text: "Before November 12, 2025")])
    }

    @Test("An unknown month or day adds the Unspecified mark; an unknown year digit reads as its decade", arguments: [
        ("1985-XX", ["Unspecified"]),
        ("1985-XX-XX", ["Unspecified"]),
        ("1985-06-XX", ["Unspecified"]),
        ("1985-06-XX~", ["Approximate", "Unspecified"]),
        ("198X", [String]()),
        ("1985-06", [String]())
    ])
    func unspecifiedMark(displayTime: String, expected: [String]) {
        #expect(ComplexDateText(displayTime, timeZone: utc).qualifiers == expected)
    }

    @Test("Each end of a range gets its own zone label, asked with the end as written without its marks")
    func zoneLabelPerEnd() {
        var asked: [String] = []
        let range = ComplexDateText("1985-10-23T10:00:00Z~/1985-10-24T10:00:00+02:00", timeZone: utc) { end in
            asked.append(end)
            return end.hasSuffix("Z") ? "UTC" : "+02"
        }
        #expect(asked == ["1985-10-23T10:00:00Z", "1985-10-24T10:00:00+02:00"])
        #expect(range.infoLines.map(\.text) == ["October 23, 1985  •  10:00 AM UTC", "October 24, 1985  •  10:00 AM +02"])
    }

    @Test("VoiceOver hears the marks as words, never c. or ?", arguments: [
        ("1985%", "Approximate, Uncertain, 1985"),
        ("1980-03?", "Uncertain, March 1980"),
        ("1985~/1990", "Approximate, 1985 — 1990"),
        ("1980-09-30/..", "After Sept. 30, 1980"),
        ("1985-06-XX", "Unspecified, June 1985")
    ])
    func voiceOverText(displayTime: String, expected: String) {
        #expect(ComplexDateText(displayTime, timeZone: utc).voiceOverText == expected)
    }
}
