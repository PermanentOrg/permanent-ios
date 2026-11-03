//
//  TimeZoneCatalog.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.10.2026.
//

import Foundation

/// The zones the picker lists: every zone of the country table that this iOS knows, grouped by region. The order
/// inside a region follows the offset at the entered date, so the groups are built per clock time.
enum TimeZoneCatalog {
    struct Region: Identifiable, Equatable {
        let name: String
        let options: [TimeZoneOption]

        var id: String { name }
    }

    /// Every listed zone in id order: the country table's keys that resolve on this iOS.
    static let listed: [TimeZoneOption] = TimeZoneCountryCodes.codes.keys.sorted().compactMap(TimeZoneOption.init(identifier:))

    /// Regions alphabetical, each sorted by the offset at the clock time, then by city.
    static func regions(at wallClock: DateComponents) -> [Region] {
        regions(of: listed, at: wallClock)
    }

    /// Any zone this iOS knows, listed or not: an old alias or "UTC" that a record may carry.
    static func option(for identifier: String) -> TimeZoneOption? {
        listed.first { $0.identifier == identifier } ?? TimeZoneOption(identifier: identifier)
    }

    static func isListed(_ identifier: String) -> Bool {
        listed.contains { $0.identifier == identifier }
    }

    /// The regions whose zones carry the text in their search text, case and accents aside; empty regions are dropped.
    static func search(_ text: String, at wallClock: DateComponents) -> [Region] {
        let needle = text.trimmingCharacters(in: .whitespaces)
        guard !needle.isEmpty else { return regions(at: wallClock) }
        return regions(of: listed.filter { $0.matches(needle, at: wallClock) }, at: wallClock)
    }

    /// The guess for a record with an offset and no zone, as web makes it: the first listed zone, regions then
    /// ids alphabetical, whose offset at the clock time matches.
    static func firstIdentifier(matchingOffset minutes: Int, at wallClock: DateComponents) -> String? {
        listed.first { $0.offsetMinutes(at: wallClock) == minutes }?.identifier
    }

    private static func regions(of options: [TimeZoneOption], at wallClock: DateComponents) -> [Region] {
        let byRegion = Dictionary(grouping: options, by: \.region)
        return byRegion.keys.sorted().map { name in
            let withOffsets = byRegion[name, default: []].map { (option: $0, offset: $0.offsetMinutes(at: wallClock)) }
            let sorted = withOffsets.sorted { left, right in
                guard left.offset == right.offset else { return left.offset < right.offset }
                return left.option.city.compare(right.option.city, options: .caseInsensitive) == .orderedAscending
            }
            return Region(name: name, options: sorted.map(\.option))
        }
    }
}
