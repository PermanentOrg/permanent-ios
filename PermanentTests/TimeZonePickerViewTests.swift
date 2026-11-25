//
//  TimeZonePickerViewTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import Foundation
import SwiftUI
import Testing
import UIKit
@testable import Permanent

/// The Time zone screen and the zone row: they render, the list shows the regions with the chosen zone marked,
/// typing filters it, a row tap writes the zone and closes, and VoiceOver gets the strings the design names.
@MainActor
struct TimeZonePickerViewTests {
    private let tenRegions = ["Africa", "America", "Antarctica", "Arctic", "Asia", "Atlantic", "Australia", "Europe", "Indian", "Pacific"]

    // MARK: - Rendering

    @Test("The screen renders, and with an empty search lists the No time zone row and the ten regions")
    func rendersAllRegions() {
        let values = Values(entry: entry("1985-10-23T17:00:00", zone: nil))

        let host = render(TimeZonePickerSheet(entry: values.binding) {})
        let listing = TimeZonePickerSheet.listing(for: values.entry, search: "")

        #expect(host.view != nil)
        #expect(listing.showsNoZoneRow)
        #expect(listing.unlistedChosen == nil)
        #expect(listing.regions.map(\.name) == tenRegions)
        #expect(listing.regions.first?.options.first?.identifier == "Africa/Abidjan")
        #expect(!listing.isEmpty)
    }

    @Test("The zone row and the option rows render on their own, chosen or not")
    func rendersRows() throws {
        let paris = try #require(TimeZoneCatalog.option(for: "Europe/Paris"))
        let clock = DateComponents(year: 1985, month: 10, day: 23, hour: 17)

        let unset = render(TimeZoneRow(zone: nil, wallClock: clock) {})
        let set = render(TimeZoneRow(zone: paris, wallClock: clock) {})
        let waiting = render(TimeZoneRow(zone: paris, wallClock: clock, isEnabled: false) {})
        let chosen = render(TimeZoneOptionRow(option: paris, wallClock: clock, isChosen: true) {})
        let plain = render(TimeZoneOptionRow(option: paris, wallClock: clock, isChosen: false) {})
        let field = render(TimeZoneSearchField(text: .constant("paris")))

        #expect(unset.view != nil && set.view != nil && waiting.view != nil && chosen.view != nil && plain.view != nil && field.view != nil)
    }

    @Test("The date sheet opens with the record's zone on its row and in its preview line")
    func sheetShowsTheZone() throws {
        let file = try child(#""recordId": "301", "archiveId": "5", "displayTime": "1985-10-23T17:00:00+01:00""#)
        let viewModel = EditDateAndTimeViewModel(selectedFiles: [file], hasUpdates: .constant(false), recordZone: .known("Europe/Paris"))
        viewModel.sessionArchiveId = { 5 }

        let host = render(EditDateAndTimeView(viewModel: viewModel))

        #expect(host.view != nil)
        #expect(viewModel.entry.zone?.placeName == "France, Paris")
        #expect(viewModel.entry.zone?.offsetLabel(at: viewModel.entry.offsetClock()) == "GMT+01:00")
        #expect(viewModel.entry.preview == "October 23, 1985 • 5PM +01")
    }

    // MARK: - The listing

    @Test("A chosen zone the list does not carry gets its own row above the regions, and goes when the search misses it")
    func unlistedChosenZone() {
        let utc = entry("1985-10-23T17:00:00", zone: "UTC")
        let kiev = entry("1985-10-23T17:00:00", zone: "Europe/Kiev")

        #expect(TimeZonePickerSheet.listing(for: utc, search: "").unlistedChosen?.identifier == "UTC")
        #expect(TimeZonePickerSheet.listing(for: utc, search: "utc").unlistedChosen?.identifier == "UTC")
        #expect(TimeZonePickerSheet.listing(for: utc, search: "paris").unlistedChosen == nil)
        #expect(TimeZonePickerSheet.listing(for: kiev, search: "kiev").unlistedChosen?.identifier == "Europe/Kiev")
        #expect(TimeZonePickerSheet.listing(for: entry("1985-10-23T17:00:00", zone: "Europe/Paris"), search: "").unlistedChosen == nil)
    }

    @Test("Typing filters the regions: paris leaves one row, +05:30 leaves Kolkata and Colombo, xyz leaves nothing")
    func typingFilters() {
        let today = entry(nil, zone: nil)

        let paris = TimeZonePickerSheet.listing(for: today, search: "paris")
        let halfHour = TimeZonePickerSheet.listing(for: today, search: "+05:30")
        let nothing = TimeZonePickerSheet.listing(for: today, search: "xyz")

        #expect(!paris.showsNoZoneRow, "the No time zone row goes while typing")
        #expect(paris.regions.map(\.name) == ["Europe"])
        #expect(paris.regions.first?.options.map(\.identifier) == ["Europe/Paris"])
        #expect(halfHour.regions.flatMap(\.options).map(\.identifier) == ["Asia/Colombo", "Asia/Kolkata"])
        #expect(nothing.isEmpty)
    }

    @Test("With no date typed the offsets are today's, so an empty sheet still lists every zone")
    func emptyEntryUsesToday() throws {
        let january = try #require(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 1, day: 15, hour: 12)))
        let july = try #require(Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: 7, day: 15, hour: 12)))
        let paris = try #require(TimeZoneCatalog.option(for: "Europe/Paris"))

        #expect(paris.offsetLabel(at: DateTimeEntry().offsetClock(now: january)) == "GMT+01:00")
        #expect(paris.offsetLabel(at: DateTimeEntry().offsetClock(now: july)) == "GMT+02:00")
        #expect(TimeZonePickerSheet.listing(for: DateTimeEntry(), search: "", now: july).regions.map(\.name) == tenRegions)
    }

    // MARK: - Choosing

    @Test("A row tap writes the zone and closes; the No time zone row unsets it and closes")
    func rowTapChoosesAndCloses() {
        let values = Values(entry: entry("1985-10-23T17:00:00", zone: nil))
        let closes = Counter()
        let picker = TimeZonePickerSheet(entry: values.binding) { closes.count += 1 }

        picker.choose("Europe/Paris")
        #expect(values.entry.timeZoneIdentifier == "Europe/Paris")
        #expect(values.entry.edtfString == "1985-10-23T17:00:00+01:00")
        #expect(closes.count == 1)

        picker.choose(nil)
        #expect(values.entry.timeZoneIdentifier == nil)
        #expect(values.entry.edtfString == "1985-10-23T17:00:00")
        #expect(closes.count == 2)
    }

    // MARK: - VoiceOver

    @Test("The row and header strings read as the design names them")
    func accessibilityStrings() throws {
        let october = DateComponents(year: 1985, month: 10, day: 23, hour: 17)
        let january = DateComponents(year: 2026, month: 1, day: 15, hour: 12)

        #expect(try #require(TimeZoneCatalog.option(for: "Africa/Abidjan")).spokenName(at: october) == "GMT plus 0, C\u{F4}te d\u{2019}Ivoire, Abidjan")
        #expect(try #require(TimeZoneCatalog.option(for: "Europe/Bucharest")).spokenName(at: october) == "GMT plus 2, Romania, Bucharest")
        #expect(try #require(TimeZoneCatalog.option(for: "Asia/Kolkata")).spokenName(at: october) == "GMT plus 5:30, India, Kolkata")
        #expect(try #require(TimeZoneCatalog.option(for: "America/St_Johns")).spokenName(at: january) == "GMT minus 3:30, Canada, St Johns")
        #expect(try #require(TimeZoneCatalog.option(for: "UTC")).spokenName(at: october) == "GMT plus 0, UTC")
        #expect("TimeZone".localized() == "Time zone")
        #expect("SelectTimeZone".localized() == "Select time zone")
        #expect("TimeZoneNotSet".localized() == "Not set")
        #expect("TimeZoneHint".localized() == "Double tap to choose")
        #expect("TimeZoneNeedsTime".localized() == "Add a time to choose a zone")
        #expect("SearchTimeZones".localized() == "Search city, country or offset")
        #expect("ClearSearch".localized() == "Clear search")
        #expect("NoTimeZone".localized() == "No time zone")
        #expect("NoMatchingTimeZones".localized() == "No matching time zones")
        #expect("Back".localized() == "Back")
    }

    // MARK: - Helpers

    private func entry(_ displayTime: String?, zone: String?) -> DateTimeEntry {
        DateTimeEntry(displayTime: displayTime, legacy: nil, timeZoneIdentifier: zone)
    }

    private func child(_ fields: String) throws -> FileModel {
        let json = #"{ "items": [ { "type": "type.record.image", "folderLinkId": "900", \#(fields) } ] }"#
        let response = try FolderChildrenV2Response.decoder.decode(FolderChildrenV2Response.self, from: Data(json.utf8))
        let item = try #require(response.items?.first)
        return FileModel(model: item, permissions: [.read, .edit], accessRole: .editor)
    }

    /// Puts the view in a window the size of a phone and lays it out once.
    private func render<Content: View>(_ view: Content) -> UIHostingController<Content> {
        let host = UIHostingController(rootView: view)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host
        window.makeKeyAndVisible()
        host.view.layoutIfNeeded()
        return host
    }

    /// The entry the picker writes, held where a test can read it back; a binding's closures must be Sendable.
    private final class Values: @unchecked Sendable {
        var entry: DateTimeEntry

        init(entry: DateTimeEntry) {
            self.entry = entry
        }

        var binding: Binding<DateTimeEntry> {
            Binding(get: { self.entry }, set: { self.entry = $0 })
        }
    }

    private final class Counter {
        var count = 0
    }
}
