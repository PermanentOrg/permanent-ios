//
//  StickyHeaderRevealRule.swift
//  Permanent
//
//  Created by Lucian Cerbu on 29.09.2026.
//

import CoreGraphics

/// When the pinned sort and Select row hides: after 24pt of finger scrolling down past its slot, and back after
/// 12pt up. Offsets are the list's top edge in content coordinates.
struct StickyHeaderRevealRule {
    static let hideAfter: CGFloat = 24
    static let showAfter: CGFloat = 12

    private(set) var isHidden = false
    private var lastTop: CGFloat?
    /// Signed distance scrolled in the current direction; down is positive.
    private var travel: CGFloat = 0

    /// Returns whether the row is hidden after this offset.
    /// - Parameters:
    ///   - top: The list's top edge, clamped to `0...maxTop` so the rubber band at either end adds no travel.
    ///   - maxTop: The furthest the top edge reaches, at the end of the list.
    ///   - slotBottom: Where the row's own slot ends; while the slot shows, so does the row.
    ///   - byUser: Whether a finger moved the list, dragging or decelerating. Other steps only record the offset.
    ///   - keepsShown: Select mode or an assistive technology, which always show the row.
    ///   - canHide: Whether rows run past the visible bottom, so a folder that fits on screen never hides the row.
    mutating func step(top: CGFloat, maxTop: CGFloat, slotBottom: CGFloat, byUser: Bool, keepsShown: Bool, canHide: Bool) -> Bool {
        let top = min(max(top, 0), max(0, maxTop))
        let previous = lastTop ?? top
        lastTop = top
        if keepsShown {
            reveal()
            return isHidden
        }
        guard byUser else { return isHidden }
        guard top >= slotBottom, canHide else {
            reveal()
            return isHidden
        }
        // Only the part past the slot counts, so a jump out of the slot measures from its bottom.
        let delta = top - max(previous, slotBottom)
        guard delta != 0 else { return isHidden }
        if travel != 0, (delta > 0) != (travel > 0) {
            travel = 0
        }
        travel += delta
        if travel >= Self.hideAfter {
            isHidden = true
        } else if travel <= -Self.showAfter {
            isHidden = false
        }
        return isHidden
    }

    /// Shows the row and forgets the offset, so the next step measures afresh.
    mutating func reset() {
        reveal()
        lastTop = nil
    }

    private mutating func reveal() {
        isHidden = false
        travel = 0
    }
}
