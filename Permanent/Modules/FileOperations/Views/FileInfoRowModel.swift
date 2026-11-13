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
    /// The words after the label, such as "Approximate • Uncertain". Only a date row has them.
    var labelDetail: String?
    /// A date range's From and To lines; empty for a row with one value.
    var lines: [DisplayTimeText.Line] = []

    // MARK: - Look

    static let labelFont = SwiftUI.Font.custom("Usual-Medium", size: 12, relativeTo: .caption)
    static let valueFont = SwiftUI.Font.custom("Usual-Regular", size: 14, relativeTo: .subheadline)
    static let labelLineHeight: CGFloat = 16
    static let valueLineHeight: CGFloat = 24
    static let labelGap: CGFloat = 8
    static let labelDetailGap: CGFloat = 12
    static let lineGap: CGFloat = 8
    static let captionFont = SwiftUI.Font.custom("Usual-Regular", size: 10, relativeTo: .caption2)
    static let captionWidth: CGFloat = 36
    static let captionGap: CGFloat = 10
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

    /// The row's height at the given text size: label, gap and each value line, plus the box around a boxed value.
    static func height(for style: Style, lines: Int = 1, compatibleWith traits: UITraitCollection) -> CGFloat {
        let label = UIFontMetrics(forTextStyle: .caption1).scaledValue(for: labelLineHeight, compatibleWith: traits)
        let value = UIFontMetrics(forTextStyle: .subheadline).scaledValue(for: valueLineHeight, compatibleWith: traits)
        let count = CGFloat(max(lines, 1))
        let box = style == .boxed ? 2 * boxPadding : 0
        return (label + labelGap + value * count + lineGap * (count - 1) + box).rounded(.up)
    }

    // MARK: - Content

    /// The lines the value takes on screen: two for a date range, else one.
    var lineCount: Int {
        max(lines.count, 1)
    }

    var isSet: Bool {
        !(value ?? "").isEmpty
    }

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

    /// The symbol at the box's trailing edge: a pencil over a set value, a plus over an empty one. A plain row has none.
    var iconName: String? {
        guard style == .boxed else { return nil }
        return isSet ? "square.and.pencil" : "plus"
    }

    /// True when VoiceOver reads the row as a button: only a boxed row does something on a tap.
    var isButton: Bool {
        style == .boxed
    }

    var accessibilityLabel: String {
        [title, labelDetail, text].compactMap { $0 }.joined(separator: ", ")
    }

    var accessibilityHint: String? {
        isButton ? "InfoEditHint".localized() : nil
    }
}

extension FileInfoRowModel {
    /// The Date row: one line, or a range's From and To lines, with the qualifier words after the label.
    init(date: DisplayTimeText?, style: Style) {
        self.init(
            kind: .date, value: date?.text, style: style, labelDetail: date?.labelDetail,
            lines: (date?.lines.count ?? 0) > 1 ? date?.lines ?? [] : []
        )
    }
}
