//
//  SortMenu.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.09.2026.
//

import UIKit

/// The folder list's sort menu: a "Sort by" line naming the current sort, the three fields, then that field's two orders.
enum SortMenu {
    /// Arrows drawn down first, then up. SF Symbols has only the up-first glyph and a menu ignores a flipped
    /// orientation, so the glyph is mirrored in its pixels, at the current text size and weight.
    static var icon: UIImage? {
        UIImage(systemName: "arrow.up.arrow.down", withConfiguration: symbolConfiguration).map(mirrored)
    }

    /// The mark on the field and order in force. iOS keeps a checkmark column before every row's image, so the
    /// marks are drawn as images, and the "Sort by" icon shares their column as the design shows.
    static var checkmark: UIImage? {
        UIImage(systemName: "checkmark", withConfiguration: symbolConfiguration)?.withRenderingMode(.alwaysTemplate)
    }

    /// The current text size and weight, so both icons follow Dynamic Type and Bold Text.
    private static var symbolConfiguration: UIImage.SymbolConfiguration {
        let textSize = UITraitCollection(preferredContentSizeCategory: UIApplication.shared.preferredContentSizeCategory)
        let body = UIFont.preferredFont(forTextStyle: .body, compatibleWith: textSize)
        let weight: UIImage.SymbolWeight = UIAccessibility.isBoldTextEnabled ? .semibold : .regular
        return UIImage.SymbolConfiguration(pointSize: body.pointSize, weight: weight)
    }

    /// `image` turned left to right in its pixels, at its own size, as a template.
    static func mirrored(_ image: UIImage) -> UIImage {
        UIGraphicsImageRenderer(size: image.size).image { context in
            context.cgContext.translateBy(x: image.size.width, y: 0)
            context.cgContext.scaleBy(x: -1, y: 1)
            image.draw(in: CGRect(origin: .zero, size: image.size))
        }.withRenderingMode(.alwaysTemplate)
    }

    /// The items are built each time the menu opens, so one menu can serve every reload of the list.
    static func make(current: @escaping () -> SortOption, onSelect: @escaping (SortOption) -> Void) -> UIMenu {
        let opening = itemsOnOpening(current: current, onSelect: onSelect)
        let items = UIDeferredMenuElement.uncached { completion in
            completion(opening())
        }
        return UIMenu(children: [items])
    }

    /// Builds the items from the sort in force at each call; the menu makes one call per opening.
    static func itemsOnOpening(current: @escaping () -> SortOption, onSelect: @escaping (SortOption) -> Void) -> () -> [UIMenuElement] {
        { elements(for: current(), onSelect: onSelect) }
    }

    static func elements(for current: SortOption, onSelect: @escaping (SortOption) -> Void) -> [UIMenuElement] {
        let summary = UIAction(title: .sortBy, subtitle: current.title, image: icon, attributes: .keepsMenuPresented) { _ in }
        summary.accessibilityLabel = [String.sortBy, current.spokenTitle].joined(separator: ", ")
        let mark = checkmark
        let fields = SortOption.fieldDefaults.map { field in
            row(field.fieldTitle, checked: current.fieldOrders.contains(field), mark: mark) {
                if let option = sort(pickingField: field, current: current) {
                    onSelect(option)
                }
            }
        }
        let orders = current.fieldOrders.map { order in
            let action = row(order.directionTitle, checked: order == current, mark: mark) {
                if let option = sort(pickingOrder: order, current: current) {
                    onSelect(option)
                }
            }
            action.accessibilityLabel = order.spokenDirectionTitle
            return action
        }
        return [
            UIMenu(options: .displayInline, children: [summary]),
            UIMenu(options: .displayInline, children: fields),
            UIMenu(options: .displayInline, children: orders)
        ]
    }

    /// An unchecked row gets a clear mark of the same size, so every title starts at the same place.
    private static func row(_ title: String, checked: Bool, mark: UIImage?, picked: @escaping () -> Void) -> UIAction {
        let clear = mark.map { UIGraphicsImageRenderer(size: $0.size).image { _ in }.withRenderingMode(.alwaysTemplate) }
        let action = UIAction(title: title, image: checked ? mark : clear) { _ in picked() }
        // VoiceOver hears "selected" on the checked row, as on a menu row that iOS checks itself.
        if checked { action.accessibilityTraits = .selected }
        return action
    }

    /// Nil when `field` is the field already in use; otherwise that field's first order.
    static func sort(pickingField field: SortOption, current: SortOption) -> SortOption? {
        guard !current.fieldOrders.contains(field) else { return nil }
        return field.fieldOrders.first
    }

    /// Nil when `order` is the sort already in force; otherwise that order.
    static func sort(pickingOrder order: SortOption, current: SortOption) -> SortOption? {
        order == current ? nil : order
    }
}
