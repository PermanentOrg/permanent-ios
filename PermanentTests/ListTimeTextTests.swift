//
//  ListTimeTextTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 20.11.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The list's date text: fixed English month names, and the clock with the zone for a date that has one, as in
/// the design and on Android.
struct ListTimeTextTests {
    private let chicago = TimeZone(identifier: "America/Chicago") ?? .current

    private func child(_ fields: String) throws -> FileModel {
        let json = "{ \"items\": [ { \(fields) } ] }"
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        let item = try #require(response.items?.first)
        return FileModel(model: item, permissions: [.read], accessRole: .viewer)
    }

    @Test("Each month has its fixed short name", arguments: [
        (1, "Jan."), (3, "Mar."), (5, "May"), (6, "Jun."), (7, "Jul."), (9, "Sept."), (12, "Dec.")
    ])
    func shortMonthNames(month: Int, name: String) {
        #expect(DateUtils.shortMonthName(month) == name)
    }

    @Test("A day, a month alone and a year alone", arguments: [
        ("2023-09-16", "Sept. 16, 2023"), ("2020-05-03", "May 3, 2020"), ("1985-10", "October 1985"), ("1985", "1985")
    ])
    func dateText(raw: String, expected: String) {
        #expect(DateUtils.displayDate(from: raw) == expected)
    }

    @Test("A complex date writes the same short names")
    func complexDateUsesTheSameNames() {
        #expect(ComplexDateText("2020-05-03/2021-09-16").listText == "May 3, 2020 — Sept. 16, 2021")
    }

    @Test("A date with a clock shows the time with minutes, then the zone label")
    func clockAndZone() {
        let text = DateUtils.listDateText(displayTime: "2026-06-24T00:56:00-05:00", listDate: "2026-06-24", timeZone: chicago) { _ in "CT" }
        #expect(text == "Jun. 24, 2026 • 12:56 AM CT")
        let onTheHour = DateUtils.listDateText(displayTime: "2026-06-24T16:00:00", listDate: "2026-06-24", timeZone: chicago)
        #expect(onTheHour == "Jun. 24, 2026 • 4:00 PM")
    }

    @Test("A Z time shows on the phone's clock")
    func utcOnThePhoneClock() {
        let text = DateUtils.listDateText(displayTime: "2026-06-24T03:30:00Z", listDate: "2026-06-23", timeZone: chicago)
        #expect(text == "Jun. 23, 2026 • 10:30 PM")
    }

    @Test("A date with no clock, and the old field, show only the day", arguments: [true, false])
    func noClockShowsTheDay(onlyEDTF: Bool) {
        #expect(DateUtils.listDateText(displayTime: "2023-09-16", listDate: "2023-09-16") { _ in "CT" } == "Sept. 16, 2023")
        let legacyDay = DateUtils.listDate(displayTime: nil, legacy: "2023-09-16T10:30:00", onlyEDTF: onlyEDTF)
        #expect(DateUtils.listDateText(displayTime: nil, listDate: legacyDay) == (onlyEDTF ? "" : "Sept. 16, 2023"))
    }

    @Test("A folder row names the record's zone")
    func rowNamesTheZone() throws {
        let file = try child(#""recordId": "8", "type": "type.record.image", "displayTime": "2026-06-24T00:56:00-05:00", "location": { "timezone": "America/Chicago" }"#)
        #expect(file.timeZoneIdentifier == "America/Chicago")
        #expect(file.displayDateText == "Jun. 24, 2026 • 12:56 AM CDT")
        #expect(file.sizeAndDateForVoiceOver == "Jun. 24, 2026, 12:56 AM CDT")
    }

    @Test("A row with no zone shows the string's offset, and a Z time no label")
    func rowWithoutZone() throws {
        let offset = try child(#""recordId": "8", "type": "type.record.image", "displayTime": "2026-06-24T00:56:00-04:00""#)
        #expect(offset.displayDateText == "Jun. 24, 2026 • 12:56 AM -04")
        let utc = try child(#""recordId": "8", "type": "type.record.image", "displayTime": "2026-06-24T12:00:00Z""#)
        #expect(!utc.displayDateText.contains("Z"))
        #expect(utc.displayDateText.hasSuffix("M"))
    }

    @Test("The item menu header shows the row's text")
    @MainActor
    func menuHeaderMatchesTheRow() throws {
        let file = try child(#""recordId": "8", "type": "type.record.image", "displayTime": "2026-06-24T00:56:00-04:00""#)
        let menu = FileMenuViewModel(fileViewModel: file, menuItems: [], onDismiss: {})
        #expect(menu.cachedFormattedDate == file.displayDateText)
    }
}
