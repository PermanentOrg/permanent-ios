//
//  TimeZoneCatalogTests.swift
//  PermanentTests
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import Foundation
import Testing
@testable import Permanent

/// The zone catalog: the generated table resolves, the regions and their order at a date, the labels, the names
/// read from Foundation, the zones built on the spot, the search and the guess for an offset.
struct TimeZoneCatalogTests {
    private let october1985 = DateComponents(year: 1985, month: 10, day: 23, hour: 17)
    private let july1985 = DateComponents(year: 1985, month: 7, day: 23, hour: 17)
    private let january2026 = DateComponents(year: 2026, month: 1, day: 15, hour: 12)
    private let october2026 = DateComponents(year: 2026, month: 10, day: 29, hour: 12)

    // MARK: - The table and the regions

    @Test("Every zone of the generated table is one this iOS knows, and holds a two-letter code")
    func tableResolves() {
        let codes = TimeZoneCountryCodes.codes

        #expect(codes.count > 400)
        #expect(codes.keys.allSatisfy { TimeZone(identifier: $0) != nil })
        #expect(codes.values.allSatisfy { $0.count == 2 && $0 == $0.uppercased() })
        #expect(TimeZoneCatalog.listed.count == codes.count)
    }

    @Test("The regions are the ten continents in alphabetical order")
    func regions() {
        let names = TimeZoneCatalog.regions(at: october1985).map(\.name)

        #expect(names == ["Africa", "America", "Antarctica", "Arctic", "Asia", "Atlantic", "Australia", "Europe", "Indian", "Pacific"])
    }

    @Test("Inside a region the offsets at the entered date never go down, and cities with one offset are alphabetical")
    func regionOrder() throws {
        let europe = try #require(TimeZoneCatalog.regions(at: october1985).first { $0.name == "Europe" })
        let offsets = europe.options.map { $0.offsetMinutes(at: october1985) }
        let plusOne = europe.options.filter { $0.offsetMinutes(at: october1985) == 60 }.map(\.city)

        #expect(offsets == offsets.sorted())
        #expect(europe.options.filter { $0.offsetMinutes(at: october1985) == 0 }.map(\.identifier) == ["Europe/Lisbon"])
        #expect(plusOne.contains("Dublin") && plusOne.contains("London") && plusOne.contains("Paris"), "summer time ended on the 27th that year")
        #expect(plusOne == plusOne.sorted { $0.compare($1, options: .caseInsensitive) == .orderedAscending })
        #expect(Set(europe.options.map(\.identifier)).count == europe.options.count, "no duplicate rows")
    }

    // MARK: - One zone

    @Test("A zone's offset follows the entered date: Paris is +01:00 in October 1985 and +02:00 in July")
    func offsetAtDate() throws {
        let paris = try #require(TimeZoneCatalog.option(for: "Europe/Paris"))
        let london = try #require(TimeZoneCatalog.option(for: "Europe/London"))

        #expect(paris.offsetMinutes(at: october1985) == 60)
        #expect(paris.offsetMinutes(at: july1985) == 120)
        #expect(paris.offsetLabel(at: october1985) == "GMT+01:00")
        #expect(paris.offsetLabel(at: july1985) == "GMT+02:00")
        #expect(london.offsetMinutes(at: october1985) == 60)
        #expect(london.offsetMinutes(at: january2026) == 0)
    }

    @Test("A clock in a repeated hour keeps the stored offset when it fits, else the earlier occurrence; a skipped hour moves forward")
    func repeatedAndSkippedHours() throws {
        let paris = try #require(TimeZoneCatalog.option(for: "Europe/Paris"))
        let repeated = DateComponents(year: 1985, month: 9, day: 29, hour: 2, minute: 30)
        let skipped = DateComponents(year: 1985, month: 3, day: 31, hour: 2, minute: 30)

        #expect(paris.offsetMinutes(at: repeated) == 120)
        #expect(paris.offsetMinutes(at: repeated, storedOffset: "+01:00") == 60)
        #expect(paris.offsetMinutes(at: repeated, storedOffset: "+03:00") == 120)
        #expect(paris.offsetMinutes(at: october1985, storedOffset: "+02:00") == 60, "a stored offset that does not fit is ignored")
        #expect(paris.offsetMinutes(at: skipped) == 120)
    }

    @Test("The labels", arguments: [(0, "GMT+00:00"), (60, "GMT+01:00"), (330, "GMT+05:30"), (-210, "GMT-03:30"), (-600, "GMT-10:00")])
    func offsetLabels(minutes: Int, label: String) {
        #expect(TimeZoneOption.offsetLabel(minutes: minutes) == label)
    }

    @Test("An offset in a string reads as minutes, and anything else as nothing", arguments: [
        ("+01:00", 60), ("-03:30", -210), ("+00:00", 0), ("Z", nil), ("1:00", nil), ("+1:00", nil), ("+25:00", nil), ("", nil)
    ])
    func offsetMinutes(text: String, expected: Int?) {
        #expect(TimeZoneOption.minutes(inOffset: text) == expected)
    }

    @Test("The short name after the time is letters when Foundation has them, else the offset as the tz database writes it")
    func shortNames() throws {
        #expect(try #require(TimeZoneCatalog.option(for: "America/New_York")).shortName(at: july1985) == "EDT")
        #expect(try #require(TimeZoneCatalog.option(for: "America/New_York")).shortName(at: january2026) == "EST")
        #expect(try #require(TimeZoneCatalog.option(for: "Pacific/Honolulu")).shortName(at: july1985) == "HST")
        #expect(try #require(TimeZoneCatalog.option(for: "Europe/London")).shortName(at: january2026) == "GMT")
        #expect(try #require(TimeZoneCatalog.option(for: "Europe/London")).shortName(at: october1985) == "+01")
        #expect(try #require(TimeZoneCatalog.option(for: "Europe/Paris")).shortName(at: october1985) == "+01")
        #expect(try #require(TimeZoneCatalog.option(for: "Asia/Kolkata")).shortName(at: october1985) == "+0530")
        #expect(TimeZoneOption.tzdataOffset(minutes: -210) == "-0330")
        #expect(TimeZoneOption.tzdataOffset(minutes: 0) == "+00")
        #expect(TimeZoneOption.offsetSuffix(minutes: -210) == "-03:30")
    }

    @Test("Country and generic names come from Foundation in English; the city is the id's last part with spaces")
    func names() throws {
        let bucharest = try #require(TimeZoneCatalog.option(for: "Europe/Bucharest"))
        let abidjan = try #require(TimeZoneCatalog.option(for: "Africa/Abidjan"))
        let newYork = try #require(TimeZoneCatalog.option(for: "America/New_York"))

        #expect(bucharest.region == "Europe")
        #expect(bucharest.city == "Bucharest")
        #expect(bucharest.countryName == "Romania")
        #expect(bucharest.genericName == "Eastern European Time")
        #expect(abidjan.countryName == "C\u{F4}te d\u{2019}Ivoire")
        #expect(newYork.city == "New York")
        #expect(newYork.countryName == "United States")
        #expect(newYork.searchText(at: july1985) == "America New York Eastern Time United States GMT-04:00")
    }

    @Test("An old alias and UTC build on the spot with no country, and neither is listed")
    func unlisted() throws {
        let kiev = try #require(TimeZoneCatalog.option(for: "Europe/Kiev"))
        let utc = try #require(TimeZoneCatalog.option(for: "UTC"))

        #expect(kiev.city == "Kiev")
        #expect(kiev.countryName == nil)
        #expect(utc.identifier == "UTC")
        #expect(utc.region == "UTC")
        #expect(utc.city == "UTC")
        #expect(utc.countryName == nil)
        #expect(utc.offsetLabel(at: october1985) == "GMT+00:00")
        #expect(!TimeZoneCatalog.listed.contains { $0.identifier == "Europe/Kiev" || $0.identifier == "UTC" })
        #expect(TimeZoneCatalog.option(for: "Mars/Olympus") == nil)
    }

    // MARK: - Search and guess

    @Test("The search matches a city, a country, a zone name or an offset, case and accents aside, and drops empty regions")
    func search() {
        let paris = TimeZoneCatalog.search("paris", at: october1985)
        let romania = TimeZoneCatalog.search("Romania", at: october1985)
        let central = TimeZoneCatalog.search("central", at: october1985).flatMap(\.options).map(\.identifier)
        let halfHour = TimeZoneCatalog.search("+05:30", at: october2026)
        let accent = TimeZoneCatalog.search("cote d", at: october1985).flatMap(\.options).map(\.identifier)

        #expect(paris.map(\.name) == ["Europe"])
        #expect(paris.first?.options.map(\.identifier) == ["Europe/Paris"])
        #expect(romania.flatMap(\.options).map(\.identifier) == ["Europe/Bucharest"])
        #expect(central.contains("Europe/Paris") && central.contains("America/Chicago"))
        #expect(halfHour.map(\.name) == ["Asia"])
        #expect(halfHour.first?.options.map(\.identifier) == ["Asia/Colombo", "Asia/Kolkata"])
        #expect(accent == ["Africa/Abidjan"])
        #expect(TimeZoneCatalog.search("xyz", at: october1985).isEmpty)
        #expect(TimeZoneCatalog.search("  ", at: october1985).count == 10, "blank text is no filter")
    }

    @Test("An offset typed short finds what the padded label finds", arguments: [("+5", "+05"), ("GMT-3", "-03"), ("+5:30", "+05:30"), ("utc+0530", "+05:30")])
    func shortOffsetSearch(short: String, padded: String) {
        let found = TimeZoneCatalog.search(short, at: october2026).flatMap(\.options).map(\.identifier)

        #expect(!found.isEmpty)
        #expect(found == TimeZoneCatalog.search(padded, at: october2026).flatMap(\.options).map(\.identifier))
    }

    @Test("The offset read out of typed text", arguments: [
        ("+5", "+05"), ("-3", "-03"), ("GMT-3", "-03"), ("gmt +5", "+05"), ("utc+5:30", "+05:30"), ("+0530", "+05:30"), ("-330", "-03:30"), ("+05:00", "+05:00"),
        ("paris", nil), ("+", nil), ("gmt", nil), ("+25", nil), ("5", nil), ("+5:3", nil)
    ])
    func offsetNeedle(text: String, needle: String?) {
        #expect(TimeZoneOption.offsetNeedle(in: text) == needle)
    }

    @Test("The guess for an offset walks regions then ids alphabetically, as web does")
    func guess() {
        #expect(TimeZoneCatalog.firstIdentifier(matchingOffset: 60, at: october1985) == "Africa/Algiers")
        #expect(TimeZoneCatalog.firstIdentifier(matchingOffset: 0, at: october1985) == "Africa/Abidjan")
        #expect(TimeZoneCatalog.firstIdentifier(matchingOffset: 17 * 60, at: october1985) == nil)
    }
}
