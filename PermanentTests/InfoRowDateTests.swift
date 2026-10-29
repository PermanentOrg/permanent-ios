//
//  InfoRowDateTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The Info tab's Date row text: the written date, its clock when it has one, and the zone when the record carries one.
struct InfoRowDateTests {
    private let bucharest = TimeZone(identifier: "Europe/Bucharest") ?? .current
    private let utc = TimeZone(secondsFromGMT: 0) ?? .current

    @Test("A date with a clock on the hour reads as 'October 23, 1985 • 5PM'")
    func onTheHour() {
        #expect(DateUtils.infoRowDate(displayTime: "1985-10-23T17:00:00", legacy: nil, timeZone: bucharest) == "October 23, 1985 • 5PM")
    }

    @Test("A clock with minutes keeps them: '4:16 PM'")
    func withMinutes() {
        #expect(DateUtils.infoRowDate(displayTime: "1985-10-23T16:16:00", legacy: nil, timeZone: bucharest) == "October 23, 1985 • 4:16 PM")
    }

    @Test("A date, a month or a year alone shows only what is written")
    func withoutAClock() {
        #expect(DateUtils.infoRowDate(displayTime: "1985-10-23", legacy: nil, timeZone: bucharest) == "October 23, 1985")
        #expect(DateUtils.infoRowDate(displayTime: "1985-10", legacy: nil, timeZone: bucharest) == "October 1985")
        #expect(DateUtils.infoRowDate(displayTime: "1985", legacy: nil, timeZone: bucharest) == "1985")
    }

    @Test("The zone follows the clock only when the record carries one")
    func zone() {
        #expect(DateUtils.infoRowDate(displayTime: "1985-10-23T17:00:00", legacy: nil, zoneAbbreviation: "CES", timeZone: bucharest) == "October 23, 1985 • 5PM CES")
        #expect(DateUtils.infoRowDate(displayTime: "1985-10-23T17:00:00", legacy: nil, zoneAbbreviation: "", timeZone: bucharest) == "October 23, 1985 • 5PM")
    }

    @Test("A Z time is a moment in UTC, shown on the phone's clock")
    func zuluTime() {
        let twoAhead = TimeZone(secondsFromGMT: 7200) ?? .current
        #expect(DateUtils.infoRowDate(displayTime: "1985-10-23T17:00:00Z", legacy: nil, timeZone: twoAhead) == "October 23, 1985 • 7PM")
        #expect(DateUtils.infoRowDate(displayTime: "1985-10-23T17:00:00Z", legacy: nil, timeZone: utc) == "October 23, 1985 • 5PM")
    }

    @Test("An offset time shows the clock as written, in any zone")
    func offsetTime() {
        #expect(DateUtils.infoRowDate(displayTime: "2001-02-03T09:30:00+03:00", legacy: nil, timeZone: bucharest) == "February 3, 2001 • 9:30 AM")
        #expect(DateUtils.infoRowDate(displayTime: "2001-02-03T09:30:00+03:00", legacy: nil, timeZone: utc) == "February 3, 2001 • 9:30 AM")
    }

    @Test("The old field gets the same shape when displayTime is missing or does not read")
    func legacyField() {
        #expect(DateUtils.infoRowDate(displayTime: nil, legacy: "2019-06-22T13:05:00.000Z", timeZone: utc) == "June 22, 2019 • 1:05 PM")
        #expect(DateUtils.infoRowDate(displayTime: "1985~", legacy: "2019-06-22T13:00:00.000Z", timeZone: utc) == "June 22, 2019 • 1PM")
    }

    @Test("displayTime wins over the old field")
    func displayTimeFirst() {
        #expect(DateUtils.infoRowDate(displayTime: "1985-10", legacy: "2019-06-22T13:05:00.000Z", timeZone: utc) == "October 1985")
    }

    @Test("Nothing readable gives nil, so the row shows its placeholder")
    func nothingReadable() {
        #expect(DateUtils.infoRowDate(displayTime: nil, legacy: nil) == nil)
        #expect(DateUtils.infoRowDate(displayTime: "1985~", legacy: "-") == nil)
        #expect(DateUtils.infoRowDate(displayTime: "", legacy: "") == nil)
    }
}
