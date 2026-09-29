//
//  SortMenu.swift
//  Permanent
//

import UIKit

/// The folder list's sort menu: a "Sort by" line naming the current sort, the three fields, then that field's two orders.
enum SortMenu {
    /// Arrows drawn down first, then up. SF Symbols has only the up-first glyph and a menu ignores a flipped
    /// orientation, so the glyph is mirrored in its pixels, at the current text size and weight.
    static var icon: UIImage? {
        let textSize = UITraitCollection(preferredContentSizeCategory: UIApplication.shared.preferredContentSizeCategory)
        let body = UIFont.preferredFont(forTextStyle: .body, compatibleWith: textSize)
        let weight: UIImage.SymbolWeight = UIAccessibility.isBoldTextEnabled ? .semibold : .regular
        return UIImage(systemName: "arrow.up.arrow.down", withConfiguration: UIImage.SymbolConfiguration(pointSize: body.pointSize, weight: weight)).map(mirrored)
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
        let summary = UIAction(
            title: .sortBy,
            subtitle: current.title,
            image: icon,
            attributes: .keepsMenuPresented
        ) { _ in }
        summary.accessibilityLabel = [String.sortBy, current.spokenTitle].joined(separator: ", ")
        let fields = SortOption.fieldDefaults.map { field in
            UIAction(title: field.fieldTitle, state: current.fieldOrders.contains(field) ? .on : .off) { _ in
                if let option = sort(pickingField: field, current: current) {
                    onSelect(option)
                }
            }
        }
        let orders = current.fieldOrders.map { order in
            UIAction(title: order.directionTitle, state: order == current ? .on : .off) { _ in
                if let option = sort(pickingOrder: order, current: current) {
                    onSelect(option)
                }
            }
        }
        return [
            UIMenu(options: .displayInline, children: [summary]),
            UIMenu(options: [.displayInline, .singleSelection], children: fields),
            UIMenu(options: [.displayInline, .singleSelection], children: orders)
        ]
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
