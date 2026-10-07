//
//  StickyHeaderReveal.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.09.2026.
//

import UIKit

/// Hides the pinned sort and Select row while the finger scrolls down a folder list and brings it back on the
/// way up. It acts only on a list laid out by `StickyHeaderFlowLayout` that has the row.
final class StickyHeaderReveal {
    private weak var list: UICollectionView?
    private let keepsShown: () -> Bool
    private let reducesMotion: () -> Bool
    private var rule = StickyHeaderRevealRule()
    private var observers: [NSObjectProtocol] = []

    private static let duration: TimeInterval = 0.25

    /// `keepsShown` is the screen's own reason to keep the row, such as select mode; VoiceOver and Switch Control
    /// always keep it.
    init(list: UICollectionView, keepsShown: @escaping () -> Bool, reducesMotion: @escaping () -> Bool = { UIAccessibility.isReduceMotionEnabled }) {
        self.list = list
        self.keepsShown = keepsShown
        self.reducesMotion = reducesMotion
        let center = NotificationCenter.default
        for name in [UIAccessibility.voiceOverStatusDidChangeNotification, UIAccessibility.switchControlStatusDidChangeNotification] {
            observers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                self?.show(animated: false)
            })
        }
    }

    deinit {
        observers.forEach { NotificationCenter.default.removeObserver($0) }
    }

    /// Feeds the list's new offset to the rule; only a finger's scroll can flip the row.
    func listDidScroll() {
        guard let list, let layout = list.collectionViewLayout as? StickyHeaderFlowLayout, let slot = layout.stickyHeaderSlot else { return }
        let hides = rule.step(
            top: list.contentOffset.y + list.contentInset.top,
            maxTop: list.contentSize.height + list.adjustedContentInset.bottom - list.bounds.height + list.contentInset.top,
            slotBottom: slot.maxY,
            byUser: list.isDragging || list.isDecelerating,
            keepsShown: keepsShown() || UIAccessibility.isVoiceOverRunning || UIAccessibility.isSwitchControlRunning,
            canHide: Self.rowsPassVisibleBottom(of: list, in: layout)
        )
        apply(hides: hides, to: layout, in: list, animated: true)
    }

    func show(animated: Bool) {
        rule.reset()
        guard let list, let layout = list.collectionViewLayout as? StickyHeaderFlowLayout else { return }
        apply(hides: false, to: layout, in: list, animated: animated)
    }

    private func apply(hides: Bool, to layout: StickyHeaderFlowLayout, in list: UICollectionView, animated: Bool) {
        guard layout.hidesStickyHeader != hides else { return }
        // Read at each change, so turning Reduce Motion on applies from the next one.
        let slides = !reducesMotion()
        let change = {
            layout.slidesStickyHeader = slides
            layout.hidesStickyHeader = hides
            list.layoutIfNeeded()
        }
        guard animated else {
            UIView.performWithoutAnimation(change)
            return
        }
        // The scroll's own move of the pinned row lands first, so only the fade and the slide animate.
        UIView.performWithoutAnimation { list.layoutIfNeeded() }
        UIView.animate(withDuration: Self.duration, delay: 0, options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction], animations: change)
    }

    /// Whether the last row ends below the visible bottom with the list at its top, so there is more to scroll to.
    private static func rowsPassVisibleBottom(of list: UICollectionView, in layout: UICollectionViewLayout) -> Bool {
        for section in stride(from: list.numberOfSections - 1, through: 0, by: -1) {
            let count = list.numberOfItems(inSection: section)
            guard count > 0 else { continue }
            let lastRow = layout.layoutAttributesForItem(at: IndexPath(item: count - 1, section: section))
            return (lastRow?.frame.maxY ?? 0) > list.bounds.height - list.contentInset.top
        }
        return false
    }
}
