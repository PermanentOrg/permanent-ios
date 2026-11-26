//
//  FileInfoRowModel.swift
//  Permanent
//
//  Created by Lucian Cerbu on 28.10.2026.
//

import SwiftUI
import UIKit

/// One row of the Info tab: a label over a value. Boxed with an icon for a member who can edit, plain text for the others.
struct FileInfoRowModel: Equatable {
    enum Kind: CaseIterable {
        case name, description, date, location
    }

    /// Boxed for a member with the edit right, plain for the others.
    enum Style: CaseIterable {
        case boxed, plain
    }

    let kind: Kind
    let value: String?
    let style: Style
    /// A Date row for a complex date: its marks beside the label, its From and To lines in the value.
    var complexDate: ComplexDateText?

    // MARK: - Look

    static let labelFont = SwiftUI.Font.custom("Usual-Medium", size: 12, relativeTo: .caption)
    static let valueFont = SwiftUI.Font.custom("Usual-Regular", size: 14, relativeTo: .subheadline)
    static let labelLineHeight: CGFloat = 16
    static let valueLineHeight: CGFloat = 24
    static let labelGap: CGFloat = 8
    static let lineGap: CGFloat = 8
    static let lineLabelWidth: CGFloat = 36
    static let lineLabelFont = SwiftUI.Font.custom("Usual-Regular", size: 10, relativeTo: .caption2)
    static let lineLabelTracking: CGFloat = 1.6
    static let boxPadding: CGFloat = 12
    static let boxCornerRadius: CGFloat = 12
    static let iconSize: CGFloat = 24
    static let sideInset: CGFloat = 24
    static let placeholderOpacity = 0.64
    static let borderOpacity = 0.32

    /// The label font for a UIKit row that sits among these, such as the tags row.
    static var labelUIFont: UIFont {
        let base = UIFont(name: "Usual-Medium", size: 12) ?? .systemFont(ofSize: 12, weight: .medium)
        return UIFontMetrics(forTextStyle: .caption1).scaledFont(for: base)
    }

    /// The space between two rows of this style.
    static func rowSpacing(for style: Style) -> CGFloat {
        style == .boxed ? 16 : 24
    }

    /// The row's height at the given text size: label, gap and value lines, plus the box around a boxed value.
    static func height(for style: Style, lines: Int = 1, compatibleWith traits: UITraitCollection) -> CGFloat {
        let label = UIFontMetrics(forTextStyle: .caption1).scaledValue(for: labelLineHeight, compatibleWith: traits)
        let value = UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: valueLineHeight, compatibleWith: traits)
        let box = style == .boxed ? 2 * boxPadding : 0
        let extraLines = CGFloat(max(lines, 1) - 1) * (value + lineGap)
        return (label + labelGap + value + extraLines + box).rounded(.up)
    }

    // MARK: - Content

    var isSet: Bool {
        !(value ?? "").isEmpty
    }

    var isWebOnly: Bool { complexDate != nil }

    /// The value lines: a range's From and To, else the value alone.
    var valueLineCount: Int { complexDate?.infoLines.count ?? 1 }

    var title: String {
        switch kind {
        case .name: return "Name".localized()
        case .description: return "Description".localized()
        case .date: return "Date".localized()
        case .location: return "Location".localized()
        }
    }

    /// What an empty boxed row says. A name is never empty, so it has none.
    var placeholder: String {
        switch kind {
        case .name: return ""
        case .description: return "InfoAddDescription".localized()
        case .date: return "InfoAddDateAndTime".localized()
        case .location: return "InfoAddLocation".localized()
        }
    }

    /// The value when set, else the placeholder.
    var text: String {
        isSet ? (value ?? "") : placeholder
    }

    /// True for name and description, typed in place. A date or location opens its own screen.
    var isTyped: Bool {
        kind == .name || kind == .description
    }

    /// The symbol at the trailing edge: on a box a pencil over a set value, a plus over an empty one, as the design
    /// shows for a web-only date too. A plain web-only date, which cannot be edited, gets (i); other plain rows none.
    var iconName: String? {
        guard style == .boxed else { return isWebOnly ? "info.circle" : nil }
        return isSet ? "square.and.pencil" : "plus"
    }

    /// True when VoiceOver reads the row as a button: a boxed row or a complex date does something on a tap.
    var isButton: Bool {
        style == .boxed || isWebOnly
    }

    var accessibilityLabel: String {
        guard let complexDate else { return "\(title), \(text)" }
        return "\(title), \(complexDate.infoText)"
    }

    var accessibilityHint: String? {
        if isWebOnly { return "WebOnlyDateHint".localized() }
        return isButton ? "InfoEditHint".localized() : nil
    }
}
