//
//  DateTimeRangeEntry.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import Foundation

/// What the full date and time sheet holds: one date, or the two sides of a range, and what each side held
/// before a toggle greyed it. Both sides share one time zone.
struct DateTimeRangeEntry: Hashable {
    enum Side: Hashable, CaseIterable, Identifiable {
        case start, end

        var id: Self { self }
    }

    var start = DateTimeEntry() {
        didSet {
            let zone = start.timeZoneIdentifier
            guard zone != oldValue.timeZoneIdentifier else { return }
            end?.timeZoneIdentifier = zone
        }
    }

    /// The To side; nil while "Use a date range" is off.
    var end: DateTimeEntry? {
        didSet {
            guard let zone = end.map(\.timeZoneIdentifier), let oldValue, zone != oldValue.timeZoneIdentifier else { return }
            start.timeZoneIdentifier = zone
        }
    }

    /// Each side as it was before Unknown emptied it.
    private var keptSides: [Side: DateTimeEntry] = [:]
    /// Each side's clock as it was before Approximate or Uncertain greyed it.
    private var keptClocks: [Side: DateTimeEntry] = [:]
    /// The To side as it was before the range was switched off.
    private var keptEnd: DateTimeEntry?

    var isRange: Bool {
        end != nil
    }

    /// True when no side holds a date, a clock or Unknown: a save clears the record's date.
    var isEmpty: Bool {
        sides.allSatisfy { $0.isEmpty && !$0.qualifiers.contains(.unknown) }
    }

    /// True when no side has a field typed: a clear, or nothing but Unknown and empty sides.
    var holdsNoDate: Bool {
        sides.allSatisfy(\.isEmpty)
    }

    var hasTime: Bool {
        sides.contains(where: \.hasTime)
    }

    /// True when the sheet opens in its full view: the record already carries a qualifier or a second side.
    var opensFull: Bool {
        isRange || !start.qualifiers.isEmpty
    }

    /// The string Stela gets, in web's bytes: "XXXX-XX-XX" for one unknown date; in a range nothing for an
    /// unknown side and ".." for an empty one, around "/". Nil when there is nothing to save.
    var edtfString: String? {
        composed(\.sideString)
    }

    /// The string edtf.js checks before a save: `edtfString` with each clock's offset, or its absence, as `Z`.
    var gateString: String? {
        composed(\.gateSideString)
    }

    /// The line under the title: the symbol before the date, a full month for one date, "Oct." in a range. An
    /// empty side shows nothing beside the dash; nil until the fields make a date.
    var preview: String? {
        guard let end else { return preview(of: start, shortMonth: false) }
        guard !isEmpty else { return nil }
        let texts = [start, end].map { side in
            side.isEmpty && !side.qualifiers.contains(.unknown) ? "" : preview(of: side, shortMonth: true)
        }
        guard let first = texts[0], let second = texts[1] else { return nil }
        return "\(first) — \(second)".trimmingCharacters(in: .whitespaces)
    }

    private var sides: [DateTimeEntry] {
        [start, end].compactMap { $0 }
    }

    init() {}

    init(start: DateTimeEntry) {
        self.start = start
    }

    /// The sides from a record: every shape `displayTime` can hold, else the old field as one date while the
    /// screens still show it. The record's zone, when known, serves both sides.
    init(
        displayTime: String?, legacy: String?, timeZoneIdentifier: String? = nil, timeZone: TimeZone = .current,
        onlyEDTF: Bool = FeatureFlags.shared.showsOnlyEDTFDate
    ) {
        guard let value = DisplayTimeValue(displayTime) else {
            start = DateTimeEntry(
                displayTime: nil, legacy: legacy, timeZoneIdentifier: timeZoneIdentifier, timeZone: timeZone, onlyEDTF: onlyEDTF
            )
            return
        }
        start = DateTimeEntry(side: value.start, timeZoneIdentifier: timeZoneIdentifier, timeZone: timeZone)
        end = value.end.map { DateTimeEntry(side: $0, timeZoneIdentifier: timeZoneIdentifier, timeZone: timeZone) }
    }

    subscript(side: Side) -> DateTimeEntry? {
        side == .start ? start : end
    }

    /// Switches one toggle of a side. Unknown empties the side and keeps it aside; Approximate and Uncertain
    /// keep the side's clock aside, because EDTF cannot qualify a time. Each comes back when its toggle goes off.
    mutating func set(_ qualifier: DateQualifiers, on: Bool, side: Side = .start) {
        guard var entry = self[side] else { return }
        if qualifier == .unknown {
            guard entry.qualifiers.contains(.unknown) != on else { return }
            if on {
                keptSides[side] = entry
                entry = DateTimeEntry()
                entry.qualifiers = .unknown
            } else {
                entry = keptSides.removeValue(forKey: side) ?? DateTimeEntry()
                entry.qualifiers.remove(.unknown)
            }
            entry.timeZoneIdentifier = start.timeZoneIdentifier
        } else {
            guard !entry.qualifiers.contains(.unknown) else { return }
            if on {
                entry.qualifiers.insert(qualifier)
            } else {
                entry.qualifiers.remove(qualifier)
            }
            if entry.qualifiers.symbol != nil, entry.hasTime {
                keptClocks[side] = entry
                (entry.hour, entry.minute, entry.second) = ("", "", "")
            } else if entry.qualifiers.symbol == nil, let kept = keptClocks.removeValue(forKey: side) {
                (entry.hour, entry.minute, entry.second, entry.format) = (kept.hour, kept.minute, kept.second, kept.format)
            }
        }
        switch side {
        case .start: start = entry
        case .end: end = entry
        }
    }

    /// Adds or removes the To side. A side switched off waits aside and comes back with the next switch on.
    mutating func setRange(on: Bool) {
        guard on != isRange else { return }
        if on {
            var side = keptEnd ?? DateTimeEntry()
            side.timeZoneIdentifier = start.timeZoneIdentifier
            keptEnd = nil
            end = side
        } else {
            keptEnd = end
            end = nil
        }
    }

    /// Empties both sides, switches every toggle and the range off and drops the zone.
    mutating func clear() {
        self = Self()
    }

    /// Empties one side of a range and switches its toggles off; an empty side saves as open. The shared zone stays.
    mutating func clear(_ side: Side) {
        guard self[side] != nil else { return }
        var entry = DateTimeEntry()
        entry.timeZoneIdentifier = start.timeZoneIdentifier
        keptSides[side] = nil
        keptClocks[side] = nil
        switch side {
        case .start: start = entry
        case .end: end = entry
        }
    }

    private func composed(_ text: KeyPath<DateTimeEntry, String?>) -> String? {
        guard !isEmpty else { return nil }
        guard let end else {
            return start.qualifiers.contains(.unknown) ? DisplayTimeValue.unknownString : start[keyPath: text]
        }
        let parts = [start, end].map { side in
            side.qualifiers.contains(.unknown) ? "" : side[keyPath: text] ?? ".."
        }
        return parts.joined(separator: "/")
    }

    private func preview(of side: DateTimeEntry, shortMonth: Bool) -> String? {
        if side.qualifiers.contains(.unknown) { return "DateUnknown".localized() }
        guard let text = side.previewText(shortMonth: shortMonth) else { return nil }
        return side.qualifiers.symbol.map { "\($0) \(text)" } ?? text
    }
}
