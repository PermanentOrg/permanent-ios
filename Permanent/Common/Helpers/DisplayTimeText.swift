//
//  DisplayTimeText.swift
//  Permanent
//
//  Created by Lucian Cerbu on 11.11.2026.
//

import Foundation

/// What the Info tab's Date row shows for a record: the words after its label, and one line or a From and a To
/// line. Nil when neither `displayTime` nor the old field reads, so the row shows its placeholder.
struct DisplayTimeText: Equatable {
    struct Line: Equatable {
        /// "From" or "To" in a range; nil for a single line.
        let caption: String?
        let text: String
    }

    /// The qualifier words, when they hold for every written side.
    let labelDetail: String?
    let lines: [Line]

    /// The lines as one string, each after its caption: what the row holds as its value and VoiceOver reads.
    var text: String {
        lines.map { line in line.caption.map { "\($0) \(line.text)" } ?? line.text }.joined(separator: ", ")
    }

    init?(
        displayTime: String?, legacy: String?, timeZoneIdentifier: String? = nil, timeZone: TimeZone = .current,
        onlyEDTF: Bool = FeatureFlags.shared.showsOnlyEDTFDate
    ) {
        guard let value = DisplayTimeValue(displayTime) else {
            guard let text = DateUtils.infoRowDate(displayTime: nil, legacy: legacy, timeZone: timeZone, onlyEDTF: onlyEDTF) else { return nil }
            self.init(labelDetail: nil, lines: [Line(caption: nil, text: text)])
            return
        }
        let text = { (side: DisplayTimeValue.Side) in Self.text(of: side, timeZoneIdentifier: timeZoneIdentifier, timeZone: timeZone) }
        let written = [value.start, value.end].compactMap { $0.flatMap(Self.qualifiers(of:)) }
        // The words go on the label only when every written side carries the same ones.
        let shared = Set(written).count == 1 ? written.first : nil
        let symbol = { (side: DisplayTimeValue.Side) in shared == nil ? Self.qualifiers(of: side)?.symbol : nil }
        let line = { (caption: String?, side: DisplayTimeValue.Side) -> Line? in
            text(side).map { Line(caption: caption, text: [symbol(side), $0].compactMap { $0 }.joined(separator: " ")) }
        }

        let lines: [Line?]
        switch (value.start, value.end) {
        case (.written, nil):
            lines = [line(nil, value.start)]

        case (.empty, .written?):
            lines = [line(nil, value.end ?? .unknown).map { Line(caption: nil, text: String(format: "DateBeforeSide".localized(), $0.text)) }]

        case (.written, .empty?):
            lines = [line(nil, value.start).map { Line(caption: nil, text: String(format: "DateAfterSide".localized(), $0.text)) }]

        case (.written, .unknown?), (.unknown, .written?), (.written, .written?):
            lines = [line("RangeFrom".localized(), value.start), line("RangeTo".localized(), value.end ?? .unknown)]

        default:
            // No side holds a date: all-X alone, or a range of open and unknown ends.
            lines = [Line(caption: nil, text: "UnknownDateAndTime".localized())]
        }
        guard !lines.contains(nil) else { return nil }
        self.init(labelDetail: shared?.words, lines: lines.compactMap { $0 })
    }

    private init(labelDetail: String?, lines: [Line]) {
        self.labelDetail = labelDetail
        self.lines = lines
    }

    private static func qualifiers(of side: DisplayTimeValue.Side) -> DateQualifiers? {
        guard case .written(_, _, let qualifiers) = side else { return nil }
        return qualifiers
    }

    /// One side's words: the date, its clock and zone when written; "Unknown" in a range, the long form alone.
    private static func text(of side: DisplayTimeValue.Side, timeZoneIdentifier: String?, timeZone: TimeZone) -> String? {
        switch side {
        case .written(let text, _, _):
            let suffix = DateTimeEntry.timeSuffix(displayTime: text, timeZoneIdentifier: timeZoneIdentifier)
            return DateUtils.infoRowDate(displayTime: text, legacy: nil, zoneAbbreviation: suffix, timeZone: timeZone)

        case .unknown:
            return "DateUnknown".localized()

        case .empty:
            return nil
        }
    }
}
